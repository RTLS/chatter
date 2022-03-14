defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view

  alias Chat.Utils
  alias Chat.Users.User
  alias Chat.Chats.{Chat, Message}

  def mount(_params, _session, socket) do
    chats = [
      Chat.create(%{name: "Radiohead", messages: [Message.create(%{text: "prescient"})]}),
      Chat.create(%{
        name: "ACM at UCLA",
        messages: [
          Message.create(%{text: "and is it batman"}),
          Message.create(%{text: "what movie are we seeing?"}),
          Message.create(%{text: "and of course it depnds on a number of things such as:"})
        ]
      }),
      Chat.create(%{
        name: "send it",
        messages: [
          Message.create(%{text: "yeah sorry I'm not in town this weekend unfortunately"}),
          Message.create(%{text: "what about you renee?"}),
          Message.create(%{text: "that does work for me!"}),
          Message.create(%{text: "bingo bongo :D"}),
          Message.create(%{text: "how about saturday?? let's def try to get a session in soon"})
        ]
      })
    ]

    socket =
      socket
      |> assign(:user, User.create())
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
      | messages: [Message.create(%{user_id: user.id, text: message}) | chat.messages]
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
        <.avatar text={@user.avatar} , color={@user.color} />
      </div>
    </div>
    """
  end

  def avatar(assigns) do
    ~H"""
    <div class="relative inline-block">
      <span class="flex inline-block align-middle w-12 h-12 rounded-full bg-teal-600 text-xl text-center">
        <div class="m-auto uppercase">
          <p><%= @text %></p>
        </div>
      </span>
      <span class="absolute bottom-0 right-0 inline-block w-3 h-3 bg-green-600 border border-white rounded-full"></span>
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
        <div class={"pl-4 py-3 m-2 rounded h-20 #{if chat.id === @chat_id, do: "bg-zinc-700"}"} phx-click="click-chat" phx-value-chat-id={chat.id}>
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
      <div class="flex-none py-3 px-4 h-20 w-full text-xl font-semibold border-b border-zinc-700"><%= @chat.name %></div>
      <div class="grow w-full overflow-auto">
        <div class="py-4 flex flex-col-reverse h-full overflow-auto">
          <%= for message <- @chat.messages do %>
            <.message message={message} user={@user} />
          <% end %>
        </div>
      </div>
      <div class="flex-none p-2 h-14 w-full">
        <form phx-submit="send-message">
          <input type="text" name="message" class="w-full rounded-2xl bg-zinc-700" placeholder="Type a message..." />
        </form>
      </div>
    </div>
    """
  end

  def message(assigns) do
    ~H"""
    <div class={"max-w-prose py-3 px-2 #{if did_user_send_message?(@user, @message), do: "place-self-end", else: "place-self-start"}"}>
      <div class={"py-1 px-2 rounded-2xl #{if did_user_send_message?(@user, @message), do: "bg-blue-700 rounded-tr-none", else: "bg-zinc-700 rounded-tl-none"}"}>
        <%= @message.text %>
      </div>
    </div>
    """
  end

  defp did_user_send_message?(%User{id: id}, %Message{user_id: id}), do: true
  defp did_user_send_message?(%User{id: _}, %Message{user_id: _}), do: false
end
