defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view

  alias Chat.Users.User
  alias Chat.Chats.Chat

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:user, User.create())
      |> assign(:chats, [Chat.create(%{name: "test chat"})])

    {:ok, socket}
  end
end
