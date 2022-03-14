defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view

  alias Chat.Utils
  alias Chat.Users.User
  alias Chat.Chats.{Chat, Message}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:user, User.create())
      |> assign(:chats, [
        Chat.create(%{name: "Radiohead", messages: [Message.create(%{text: "prescient"})]}),
        Chat.create(%{
          name: "ACM at UCLA",
          messages: [
            Message.create(%{
              text:
                "and of course it depnds on a number of things such as:\n1) when can I see a move?\n2) what movie might that be???"
            })
          ]
        }),
        Chat.create(%{
          name: "send it",
          messages: [
            Message.create(%{text: "yeah sorry I'm not in town this weekend unfortunately"})
          ]
        })
      ])

    {:ok, socket}
  end

  def profile(assigns) do
    ~H"""
    <div class="flex justify-between py-3 border-b border-zinc-700">
      <div class="px-4 text-xl bold font-semibold">
        Profile
      </div>
      <div class="px-4">
        <.avatar text={@user.avatar}, color={@user.color} />
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
      <span class="absolute bottom-0 right-0 inline-block w-3 h-3 bg-green-600 border border-white rounded-full">
      </span>
    </div>
    """
  end

  def chats(assigns) do
    ~H"""
    <div class="pt-3">
      <div class="px-4 py-4 text-xl bold font-semibold">
        Chats
      </div>
      <%= for chat <- @chats do %>
        <div class="pl-4 w-full h-20 py-3 hover:bg-zinc-600">
          <div class="">
            <%= chat.name %>
          </div>
          <%= if message = List.first(chat.messages) do %>
            <div class="flex justify-between text-zinc-500 text-sm">
              <div class="w-3/4 h-5 overflow-hidden text-ellipsis"> <%= message.text %> </div>
              <div class="w-1/6"> <%= Utils.format_datetime(message.sent_at) %> </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
