defmodule ChatWeb.ChatSidebar do
  @moduledoc "LiveView LiveComponent for chat in the sidebar."
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div phx-click="click-chat" phx-value-chat-id={@chat.id} class={"pl-4 py-3 m-2 rounded h-20 #{if @selected, do: "bg-zinc-800"}"}>
      <div><%= @chat.name %></div>
      <%= if message = List.first(@chat.messages) do %>
        <div class="flex justify-between pr-4 text-zinc-500 text-sm">
          <div class="w-3/4 h-5 overflow-hidden"><%= message.text %></div>
          <div class="w-1/4 h-5 text-right"><%= Chat.Utils.format_datetime(message.sent_at) %></div>
        </div>
      <% end %>
      <div class="text-right pr-4 text-sm"><%= users_online_text(@chat.users_online) %></div>
    </div>
    """
  end

  defp users_online_text(1), do: "1 user here"
  defp users_online_text(num), do: "#{num} users here"
end
