defmodule ChatWeb.ChatLive do
  @moduledoc "LiveView for primary chat page."
  use ChatWeb, :live_view

  alias Chat.{Chats, Users, Store}
  alias ChatWeb.{Avatar, ChatSidebar, Presence}

  def mount(_params, _session, socket) do
    case connected?(socket) do
      true -> connected_mount(socket)
      false -> {:ok, assign(socket, :status, :connecting)}
    end
  end

  def connected_mount(socket) do
    {:ok, user} = Store.create_user()

    # Subscribe to new chats being started
    subscribe_to_new_chats()

    # Get chats with online user count
    chats =
      Enum.map(Store.all_chats(), fn chat ->
        # Subscribe to updates on all chats
        subscribe_to_chat_presence(chat)

        # Get current online count for all chats
        set_users_online(chat)
      end)

    # If we have a selected chat:
    # * add ourselves to presence as in the chat
    # * subscribe to new messages in this chat
    selected_chat_id =
      case chats do
        [] ->
          nil

        chats ->
          chat_id = List.first(chats).id
          track_presence(chat_id, user.id)
          subscribe_to_messages(chat_id)
          chat_id
      end

    socket =
      socket
      |> assign(:chats, chats)
      |> assign(:status, :connected)
      |> assign(:selected_chat_id, selected_chat_id)
      |> assign(:user, user)
      |> assign(:messages, Store.all_messages(%{chat_id: selected_chat_id}))
      |> assign(:clear_message, "")

    {:ok, socket}
  end

  def handle_event("new-chat", %{"chat-name" => chat_name}, socket) do
    case String.trim(chat_name) do
      "" ->
        {:noreply, socket}

      chat_name ->
        # Create a chat with 1 user online
        {:ok, chat} = Store.create_chat(%{name: chat_name, users_online: [socket.assigns.user]})

        # Begin tracking ourselves as in the chat
        track_presence(chat, socket.assigns.user)

        # Subscribe to messages
        subscribe_to_messages(chat.id)

        # Broadcast new chat
        broadcast_new_chat(chat)

        {:noreply, assign(socket, %{selected_chat_id: chat.id, chats: [chat | socket.assigns.chats], messages: []})}
    end
  end

  def handle_event("new-chat", _params, %{assigns: %{selected_chat_id: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("new-chat", _params, socket) do
    untrack_presence(socket.assigns.selected_chat_id, socket.assigns.user)
    unsubscribe_from_messages(socket.assigns.selected_chat_id)

    {:noreply, assign(socket, %{selected_chat_id: nil})}
  end

  def handle_event("click-chat", %{"chat-id" => chat_id}, %{assigns: %{selected_chat_id: chat_id}} = socket) do
    {:noreply, socket}
  end

  def handle_event("click-chat", %{"chat-id" => chat_id}, socket) do
    untrack_presence(socket.assigns.selected_chat_id, socket.assigns.user)
    track_presence(chat_id, socket.assigns.user)

    unsubscribe_from_messages(socket.assigns.selected_chat_id)
    subscribe_to_messages(chat_id)

    {:noreply,
     assign(socket, %{selected_chat_id: chat_id, clear_message: "", messages: Store.all_messages(%{chat_id: chat_id})})}
  end

  def handle_event("send-message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send-message", %{"message" => message}, socket) do
    user = socket.assigns.user

    {:ok, new_message} =
      Store.create_message(%{
        chat_id: socket.assigns.selected_chat_id,
        user_id: user.id,
        user: user,
        text: message
      })

    broadcast_message(new_message)

    # Super hacky but we need to 'update' the message send box in order to
    # trigger a client side hook to clear the text input after send while focused
    # https://github.com/phoenixframework/phoenix_live_view/issues/624
    {:noreply, assign(socket, :clear_message, UUID.uuid1())}
  end

  def handle_info(%{event: "presence_diff", topic: topic, payload: %{joins: joins, leaves: leaves}}, socket) do
    case topic_to_id(topic) do
      {:chat, chat_id} ->
        joins_users = joins |> Map.values() |> Enum.map(& &1.user)
        leaves_ids = leaves |> Map.values() |> Enum.map(& &1.user.id)

        {:noreply,
         update_chat(socket, chat_id, fn chat ->
            users_online =
              chat.users_online
              |> Kernel.++(joins_users)
              |> Stream.reject(& &1.id in leaves_ids)
              |> Enum.uniq()

           %{chat | users_online: users_online}
         end)}
    end
  end

  def handle_info(
        {:new_message, %Chats.Message{chat_id: chat_id} = message},
        %{assigns: %{selected_chat_id: chat_id}} = socket
      ) do
    {:noreply, update(socket, :messages, &[message | &1])}
  end

  def handle_info({:new_chat, %Chats.Chat{} = chat}, socket) do
    subscribe_to_chat_presence(chat)
    {:noreply, update(socket, :chats, &Enum.uniq([chat | &1]))}
  end

  def profile(assigns) do
    ~H"""
    <div class="flex justify-between py-3 h-20 border-b border-zinc-700">
      <div class="px-4 text-xl font-semibold">
        Profile
      </div>
      <div class="px-4">
        <Avatar.large user={@user} online={true} />
      </div>
    </div>
    """
  end

  def chats(assigns) do
    ~H"""
    <div class="pt-3">
      <div class="flex justify-between">
        <div class="px-4 py-4 text-xl font-semibold">
          Chats
        </div>
        <div phx-click="new-chat" class="py-4 px-4">
          <span class="material-icons">add_circle</span>
        </div>
      </div>
      <%= for chat <- @chats do %>
        <ChatSidebar.render chat={chat} selected={chat.id === @selected_chat_id} } />
      <% end %>
    </div>
    """
  end

  def chat(%{chat: nil} = assigns) do
    ~H"""
    <div class="flex flex-col max-h-screen h-full">
      <div class="flex-none py-3 px-4 h-20 w-full text-xl font-semibold border-b border-zinc-800">
        <form phx-submit="new-chat" autocomplete="off">
          <input type="text" name="chat-name" class="w-full bg-transparent border-none" placeholder="Type a name for this chat..." autofocus="true" />
        </form>
      </div>
      <div class="grow w-full"></div>
    </div>
    """
  end

  def chat(assigns) do
    ~H"""
    <div class="flex flex-col max-h-screen h-full">
      <div class="flex-none py-3 px-4 h-20 w-full text-xl font-semibold border-b border-zinc-800"><%= @chat.name %></div>
      <div class="grow w-full overflow-auto">
        <div class="py-4 flex flex-col-reverse h-full overflow-auto">
          <%= for message <- @messages do %>
            <.message message={message} user={@user} />
          <% end %>
        </div>
      </div>
      <div class="flex-none p-2 h-14 w-full">
        <form phx-submit="send-message" autocomplete="off">
          <input
            id="message"
            type="text"
            name="message"
            value={@clear_message}
            phx-hook="ClearMessageSend"
            class="w-full rounded-2xl bg-zinc-800 target:outline-black"
            placeholder="Type a message..."
          />
        </form>
      </div>
    </div>
    """
  end

  def message(assigns) do
    ~H"""
    <div class={"flex py-3 px-4 #{if did_user_send_message?(@user, @message), do: "place-self-end", else: "place-self-start"}"}>
      <div class={"#{if did_user_send_message?(@user, @message), do: "order-last", else: "order-first"}"}>
        <Avatar.medium user={@message.user} online={false} />
      </div>
      <div class="max-w-prose px-4">
        <div class={"py-1 px-2 rounded-2xl #{if did_user_send_message?(@user, @message), do: "bg-blue-800 rounded-tr", else: "bg-zinc-800 rounded-tl"}"}>
          <%= @message.text %>
        </div>
      </div>
    </div>
    """
  end

  defp did_user_send_message?(%Users.User{id: id}, %Chats.Message{user_id: id}), do: true
  defp did_user_send_message?(%Users.User{id: _}, %Chats.Message{user_id: _}), do: false

  defp topic_to_id("chat:" <> id), do: {:chat, id}

  defp update_chat(socket, chat_id, chat_update_fn) do
    chat =
      socket.assigns.chats
      |> Enum.find(&(&1.id === chat_id))
      |> chat_update_fn.()

    chat_idx = Enum.find_index(socket.assigns.chats, &(&1.id === chat_id))
    assign(socket, :chats, List.replace_at(socket.assigns.chats, chat_idx, chat))
  end

  defp set_users_online(%Chats.Chat{} = chat) do
    %{chat | users_online: chat |> chat_topic() |> Presence.list() |> Map.values() |> Enum.map(& &1.user)}
  end

  defp subscribe_to_chat_presence(chat), do: ChatWeb.Endpoint.subscribe(chat_topic(chat))

  defp track_presence(chat, user) when is_nil(chat) or is_nil(user), do: :ok
  defp track_presence(%Chats.Chat{id: chat_id}, user_or_id), do: track_presence(chat_id, user_or_id)
  defp track_presence(chat_or_id, %Users.User{id: user_id}), do: track_presence(chat_or_id, user_id)

  defp track_presence(chat_id, user_id) when is_binary(chat_id) and is_binary(user_id) do
    Presence.track(self(), chat_topic(chat_id), user_id, %{})
  end

  defp untrack_presence(chat, user) when is_nil(chat) or is_nil(user), do: :ok
  defp untrack_presence(%Chats.Chat{id: chat_id}, user_or_id), do: untrack_presence(chat_id, user_or_id)
  defp untrack_presence(chat_or_id, %Users.User{id: user_id}), do: untrack_presence(chat_or_id, user_id)

  defp untrack_presence(chat_id, user_id) when is_binary(chat_id) and is_binary(user_id) do
    Presence.untrack(self(), chat_topic(chat_id), user_id)
  end

  def chat_topic(%Chats.Chat{id: id}), do: "chat:#{id}"
  def chat_topic(id) when is_binary(id), do: "chat:#{id}"

  defp subscribe_to_messages(%Chats.Chat{id: id}), do: subscribe_to_messages(id)

  defp subscribe_to_messages(chat_id) when is_binary(chat_id) do
    Phoenix.PubSub.subscribe(Chat.PubSub, message_topic(chat_id))
  end

  defp unsubscribe_from_messages(nil), do: :ok
  defp unsubscribe_from_messages(%Chats.Chat{id: id}), do: unsubscribe_from_messages(id)

  defp unsubscribe_from_messages(chat_id) when is_binary(chat_id) do
    Phoenix.PubSub.unsubscribe(Chat.PubSub, message_topic(chat_id))
  end

  defp broadcast_message(%Chats.Message{chat_id: chat_id} = message) do
    Phoenix.PubSub.broadcast(Chat.PubSub, message_topic(chat_id), {:new_message, message})
  end

  defp subscribe_to_new_chats, do: Phoenix.PubSub.subscribe(Chat.PubSub, "new_chats")

  defp broadcast_new_chat(%Chats.Chat{} = chat) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "new_chats", {:new_chat, chat})
  end

  defp message_topic(chat_id), do: "messages:#{chat_id}"
end
