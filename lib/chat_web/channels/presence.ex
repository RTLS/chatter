defmodule ChatWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :chat,
    pubsub_server: Chat.PubSub

  alias Chat.{Store, Users}

  def fetch(_topic, presences) do
    users =
      presences
      |> Map.keys()
      |> then(&%{id: &1})
      |> Store.all_users()
      |> Enum.into(%{}, fn %Users.User{id: user_id} = user ->
        {user_id, user}
      end)

    for {user_id, %{metas: metas}} <- presences, into: %{} do
      {user_id, %{metas: metas, user: users[user_id]}}
    end
  end
end
