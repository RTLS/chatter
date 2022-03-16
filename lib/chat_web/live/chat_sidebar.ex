defmodule ChatWeb.ChatSidebar do
  @moduledoc "LiveView LiveComponent for chat in the sidebar."
  use Phoenix.Component

  alias ChatWeb.Avatar

  @max_avatars 8

  def render(assigns) do
    assigns = assign(assigns, :users_online, Enum.take(assigns.chat.users_online, @max_avatars))
    assigns = assign(assigns, :overflow_users, max(length(assigns.chat.users_online) - @max_avatars, 0))

    ~H"""
    <div phx-click="click-chat" phx-value-chat-id={@chat.id} class={"pl-4 py-3 m-2 rounded h-20 #{if @selected, do: "bg-zinc-800"}"}>
      <div><%= @chat.name %></div>
      <%= if message = List.first(@chat.messages) do %>
        <div class="flex justify-between pr-4 text-zinc-500 text-sm">
          <div class="w-3/4 h-5 overflow-hidden"><%= message.text %></div>
          <div class="w-1/4 h-5 text-right"><%= Chat.Utils.format_datetime(message.sent_at) %></div>
        </div>
      <% end %>
      <div class="py-1 -space-x-2 w-full">
        <%= for user <- @users_online do %>
          <Avatar.small user={user} online={false} />
        <% end %>
        <span class="px-3 text-sm text-zinc-400"><%= overflow_text(@overflow_users) %></span>
      </div>
    </div>
    """
  end

  defp overflow_text(0), do: ""
  defp overflow_text(num), do: "+#{num}"
end
