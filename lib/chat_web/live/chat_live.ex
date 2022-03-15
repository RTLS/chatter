defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view

  alias Chat.Utils
  alias Chat.Users.User
  alias Chat.Chats.{Chat, Message}
  alias ChatWeb.Avatar

  @user User.create(%{avatar: "up", color: :violet})
  @other_users Enum.map(1..30, fn _ -> User.create() end)

  def mount(_params, _session, socket) do
    chats = [
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
          Message.create(%{user: List.first(@other_users), text: "and of course it depnds on a number of things such as:"})
        ]
      }),
      Chat.create(%{
        name: "send it",
        messages: [
          Message.create(%{user: Enum.random(@other_users), text: "yeah sorry I'm not in town this weekend unfortunately"}),
          Message.create(%{user: Enum.random(@other_users), text: "what about you renee?"}),
          Message.create(%{user: Enum.random(@other_users), text: "that does work for me!"}),
          Message.create(%{user: Enum.random(@other_users), text: "bingo bongo :D"}),
          Message.create(%{user: Enum.random(@other_users), text: "how about saturday?? let's def try to get a session in soon"})
        ]
      })
    ]

    socket =
      socket
      |> assign(:user, @user)
      |> assign(:chat_id, chats |> List.last() |> Map.get(:id))
      |> assign(:chats, chats)
      |> assign(:chat, List.last(chats))

    {:ok, socket}
  end

  def handle_event("click-chat", %{"chat-id" => chat_id}, socket) do
    chat = Enum.find(socket.assigns.chats, &(&1.id === chat_id))
    {:noreply, assign(socket, %{chat_id: chat_id, chat: chat})}
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
      <div class="px-4 py-4 text-xl font-semibold">
        Chats
      </div>
      <%= for chat <- @chats do %>
        <div class={"pl-4 py-3 m-2 rounded h-20 #{if chat.id === @chat_id, do: "bg-zinc-800"}"} phx-click="click-chat" phx-value-chat-id={chat.id}>
          <div class="">
            <%= chat.name %>
          </div>
          <%= if message = List.first(chat.messages) do %>
            <div class="flex justify-between text-zinc-500 text-sm">
              <div class="w-3/4 h-5 overflow-hidden text-ellipsis"><%= message.text %></div>
              <div class="w-1/6"><%= Utils.format_datetime(message.sent_at) %></div>
            </div>
          <% end %>
        </div>
      <% end %>
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
          <input type="text" name="message" class="w-full rounded-2xl bg-zinc-800 target:outline-black" placeholder="Type a message..."/>
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
end
