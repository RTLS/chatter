defmodule Chat.Users.User do
  @enforce_keys [:id, :avatar, :color]
  defstruct [:id, :avatar, :color]

  alias __MODULE__
  alias Chat.Constants

  @type id :: binary
  @type avatar :: binary
  @type color :: Constants.color()
  @type t :: %User{id: id(), avatar: avatar(), color: color()}

  @spec create :: User.t()
  @spec create(map) :: User.t()
  def create(params \\ %{}) when is_map(params) do
    params
    |> Map.put_new(:id, UUID.uuid1())
    |> Map.put_new(:avatar, random_avatar())
    |> then(&struct(User, &1))
  end

  defp random_avatar do
    for _ <- 1..2, into: "", do: <<Enum.random('abcdef')>>
  end
end
