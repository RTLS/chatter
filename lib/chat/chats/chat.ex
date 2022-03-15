defmodule Chat.Chats.Chat do
  @enforce_keys [:id, :name]
  defstruct [:id, :name, :users_online, messages: []]

  alias __MODULE__

  @type id :: binary
  @type name :: binary
  @type t :: %Chat{id: id(), name: name()}

  @spec create(map) :: Chat.t()
  def create(params) when is_map(params) do
    params
    |> Map.put_new(:id, UUID.uuid1())
    |> then(&struct(Chat, &1))
  end
end
