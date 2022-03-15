defmodule ChatWeb.ChatLive do
  @moduledoc "LiveView for primary chat page."
  use ChatWeb, :live_view

  alias Chat.Users.User
  alias Chat.Chats.{Chat, Message}
  alias ChatWeb.{Avatar, ChatSidebar, Presence}

  @user User.create(%{avatar: "up", color: :violet})
  @other_users Enum.map(1..30, fn _ -> User.create() end)
  @chats [
    Chat.create(%{
      name: "Radiohead",
      messages: [
        Message.create(%{user: Enum.random(@other_users), text: "prescient"})
      ]
    }),
    Chat.create(%{
      name: "ACM at UCLA",
      messages: [
        Message.create(%{user: List.first(@other_users), text: "and is it batman"}),
        Message.create(%{user: List.first(@other_users), text: "what movie are we seeing?"}),
        Message.create(%{
          user: List.first(@other_users),
          text: "and of course it depnds on a number of things such as:"
        })
      ]
    }),
    Chat.create(%{
      name: "send it",
      messages: [
        Message.create(%{
          user: Enum.random(@other_users),
          text: "yeah sorry I'm not in town this weekend unfortunately"
        }),
        Message.create(%{user: Enum.random(@other_users), text: "what about you renee?"}),
        Message.create(%{user: Enum.random(@other_users), text: "that does work for me!"}),
        Message.create(%{user: Enum.random(@other_users), text: "bingo bongo :D"}),
        Message.create(%{
          user: Enum.random(@other_users),
          text: "how about saturday?? let's def try to get a session in soon"
        })
      ]
    })
  ]

  def mount(_params, _session, socket) do
    case connected?(socket) do
      true -> connected_mount(socket)
      false -> {:ok, assign(socket, :status, :connecting)}
    end
  end

  def connected_mount(socket) do
    selected_chat = List.last(@chats)

    socket =
      socket
      |> assign(:user, @user)
      |> assign(:chats, @chats)
      |> assign(:selected_chat_id, selected_chat.id)
      |> assign(:status, :connected)

    {:ok, socket}
  end

  def handle_event("new-chat", %{"chat-name" => chat_name}, socket) do
    case String.trim(chat_name) do
      "" ->
        {:noreply, socket}

      chat_name ->
        chat = Chat.create(%{name: chat_name})
        {:noreply, assign(socket, %{selected_chat_id: chat.id, chats: [chat | socket.assigns.chats]})}
    end
  end

  def handle_event("new-chat", _params, socket) do
    {:noreply, assign(socket, %{selected_chat_id: nil})}
  end

  def handle_event("click-chat", %{"chat-id" => chat_id}, socket) do
    {:noreply, assign(socket, %{selected_chat_id: chat_id})}
  end

  def handle_event("send-message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send-message", %{"message" => message}, socket) do
    user = socket.assigns.user
    chat = socket.assigns.chat

    chat = %{
      chat
      | messages: [Message.create(%{user_id: user.id, user: user, text: message}) | chat.messages]
    }

    {:noreply, assign(socket, %{chat: chat})}
  end

  def handle_info(%{event: "presence_diff", topic: topic, payload: payload}, socket) do
    case topic_to_id(topic) do
      {:chat, id} ->
        send_update(ChatSidebarComponent, id: id, payload: payload)
    end

    {:noreply, socket}
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
        <ChatSidebar.render chat={chat} selected={chat.id === @selected_chat_id}} />
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
          <%= for message <- @chat.messages do %>
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

  defp did_user_send_message?(%User{id: id}, %Message{user_id: id}), do: true
  defp did_user_send_message?(%User{id: _}, %Message{user_id: _}), do: false

  def chat_topic(%Chat{id: id}), do: "chat:#{id}"

  defp topic_to_id("chat:" <> id), do: {:chat, id}
end
