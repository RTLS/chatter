defmodule ChatWeb.ChatLive do
  @moduledoc "LiveView for primary chat page."
  use ChatWeb, :live_view

  alias Chat.Store
  alias Chat.Users.User
  alias Chat.Chats
  alias ChatWeb.{Avatar, ChatSidebar, Presence}

  def mount(_params, _session, socket) do
    case connected?(socket) do
      true -> connected_mount(socket)
      false -> {:ok, assign(socket, :status, :connecting)}
    end
  end

  def connected_mount(socket) do
    {:ok, user} = Store.create_user()

    chats =
      Enum.map(Store.all_chats(), fn chat ->
        # Subscribe to updates on all chats
        ChatWeb.Endpoint.subscribe(chat_topic(chat))

        # Get current online count for all chats
        %{chat | users_online: chat |> chat_topic() |> Presence.list() |> map_size()}
      end)

    selected_chat_id =
      case chats do
        [] ->
          nil

        chats ->
          chat_id = List.first(chats).id
          Presence.track(self(), chat_topic(chat_id), user.id, %{})
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

    {:ok, socket}
  end

  def handle_event("new-chat", %{"chat-name" => chat_name}, socket) do
    case String.trim(chat_name) do
      "" ->
        {:noreply, socket}

      chat_name ->
        # Create a chat with 1 user online
        {:ok, chat} = Store.create_chat(%{name: chat_name, users_online: 1})

        # Begin tracking ourselves as in the chat and subscribe to future joins/leaves
        Presence.track(self(), chat_topic(chat), socket.assigns.user.id, %{})
        ChatWeb.Endpoint.subscribe(chat_topic(chat))

        # Subscribe to messages
        subscribe_to_messages(chat.id)

        {:noreply, assign(socket, %{selected_chat_id: chat.id, chats: [chat | socket.assigns.chats], messages: []})}
    end
  end

  def handle_event("new-chat", _params, %{assigns: %{selected_chat_id: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("new-chat", _params, socket) do
    Presence.untrack(self(), chat_topic(socket.assigns.selected_chat_id), socket.assigns.user.id)
    unsubscribe_from_messages(socket.assigns.selected_chat_id)

    {:noreply, assign(socket, %{selected_chat_id: nil})}
  end

  def handle_event("click-chat", %{"chat-id" => chat_id}, %{assigns: %{selected_chat_id: chat_id}} = socket) do
    {:noreply, socket}
  end

  def handle_event("click-chat", %{"chat-id" => chat_id}, socket) do
    Presence.untrack(self(), chat_topic(socket.assigns.selected_chat_id), socket.assigns.user.id)
    Presence.track(self(), chat_topic(chat_id), socket.assigns.user.id, %{})

    unsubscribe_from_messages(socket.assigns.selected_chat_id)
    subscribe_to_messages(chat_id)

    {:noreply, assign(socket, %{selected_chat_id: chat_id, messages: Store.all_messages(%{chat_id: chat_id})})}
  end

  def handle_event("send-message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send-message", %{"message" => message}, socket) do
    user = socket.assigns.user

    {:ok, new_message} =
      Store.create_message(%{chat_id: socket.assigns.selected_chat_id, user_id: user.id, user: user, text: message})

    broadcast_message(new_message)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", topic: topic, payload: payload}, socket) do
    case topic_to_id(topic) do
      {:chat, chat_id} ->
        {:noreply,
         update_chat(socket, chat_id, fn chat ->
           %{chat | users_online: chat.users_online + map_size(payload.joins) - map_size(payload.leaves)}
         end)}
    end
  end

  def handle_info({:new_message, %Chats.Message{chat_id: chat_id} = message}, %{assigns: %{selected_chat_id: chat_id}} = socket) do
    {:noreply, update(socket, :messages, &[message | &1])}
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
          <input type="text" name="message" class="w-full rounded-2xl bg-zinc-800 target:outline-black" placeholder="Type a message..." />
        </form>
      </div>
    </div>
    """
  end

  def message(assigns) do
    ~H"""
    <div class={"flex py-3 px-4 #{if did_user_send_message?(@user, @message), do: "place-self-end", else: "place-self-start"}"}>
      <div class={"#{if did_user_send_message?(@user, @message), do: "order-last", else: "order-first"}"}>
        <Avatar.medium user={@message.user} online={Enum.random(0..1) === 0} />
      </div>
      <div class="max-w-prose px-4">
        <div class={"py-1 px-2 rounded-2xl #{if did_user_send_message?(@user, @message), do: "bg-blue-800 rounded-tr", else: "bg-zinc-800 rounded-tl"}"}>
          <%= @message.text %>
        </div>
      </div>
    </div>
    """
  end

  defp did_user_send_message?(%User{id: id}, %Chats.Message{user_id: id}), do: true
  defp did_user_send_message?(%User{id: _}, %Chats.Message{user_id: _}), do: false

  def chat_topic(%Chats.Chat{id: id}), do: "chat:#{id}"
  def chat_topic(id) when is_binary(id), do: "chat:#{id}"

  defp topic_to_id("chat:" <> id), do: {:chat, id}

  defp update_chat(socket, chat_id, chat_update_fn) do
    chat =
      socket.assigns.chats
      |> Enum.find(&(&1.id === chat_id))
      |> chat_update_fn.()

    chat_idx = Enum.find_index(socket.assigns.chats, &(&1.id === chat_id))
    assign(socket, :chats, List.replace_at(socket.assigns.chats, chat_idx, chat))
  end

  def subscribe_to_messages(%Chats.Chat{id: id}), do: subscribe_to_messages(id)
  def subscribe_to_messages(chat_id) when is_binary(chat_id), do: Phoenix.PubSub.subscribe(Chat.PubSub, message_topic(chat_id))

  def unsubscribe_from_messages(%Chats.Chat{id: id}), do: unsubscribe_from_messages(id)
  def unsubscribe_from_messages(chat_id) when is_binary(chat_id), do: Phoenix.PubSub.unsubscribe(Chat.PubSub, message_topic(chat_id))

  def broadcast_message(%Chats.Message{chat_id: chat_id} = message) do
    Phoenix.PubSub.broadcast(Chat.PubSub, message_topic(chat_id), {:new_message, message})
  end

  defp message_topic(chat_id), do: "messages:#{chat_id}"
end
