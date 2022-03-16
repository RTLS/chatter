defmodule Chat.Chats.Message do
  @enforce_keys [:id, :chat_id, :user_id, :text, :sent_at]
  defstruct [:id, :chat_id, :user_id, :user, :text, :sent_at]

  alias __MODULE__

  @type id :: binary
  @type text :: binary
  @type t :: %Message{id: id(), text: text(), user_id: id(), sent_at: DateTime.t()}

  @spec create(map) :: Message.t()
  def create(params) when is_map(params) do
    params
    |> Map.put_new(:id, UUID.uuid1())
    |> Map.put_new(:sent_at, DateTime.utc_now())
    |> then(&struct(Message, &1))
  end
end
