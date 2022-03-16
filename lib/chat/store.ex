defmodule Chat.Store do
  use Agent

  alias Chat.Users.User
  alias Chat.Chats.{Chat, Message}

  @entry_modules [User, Chat, Message]
  @initial_state Enum.into(@entry_modules, %{}, &{&1, []})

  def start_link(_opts) do
    Agent.start_link(fn -> @initial_state end, name: __MODULE__)
  end

  def find_user(params \\ %{}) do
    Agent.get(__MODULE__, &find(User, params, &1))
  end

  def all_users(params \\ %{}) do
    Agent.get(__MODULE__, &all(User, params, &1))
  end

  def create_user(params \\ %{}) do
    Agent.get_and_update(__MODULE__, &create(User, params, &1))
  end

  def find_chat(params \\ %{}) do
    Agent.get(__MODULE__, &find(Chat, params, &1))
  end

  def all_chats(params \\ %{}) do
    Agent.get(__MODULE__, &all(Chat, params, &1))
  end

  def create_chat(params \\ %{}) do
    Agent.get_and_update(__MODULE__, &create(Chat, params, &1))
  end

  def find_message(params \\ %{}) do
    Agent.get(__MODULE__, &find(Message, params, &1))
  end

  def all_messages(params \\ %{}) do
    Agent.get(__MODULE__, &all(Message, params, &1))
  end

  def create_message(params \\ %{}) do
    Agent.get_and_update(__MODULE__, &create(Message, params, &1))
  end

  defp find(module, params, state) do
    case all(module, params, state) do
      [entry] -> {:ok, entry}
      [] -> {:error, :not_found}
    end
  end

  defp all(module, params, state) do
    %{^module => entries} = state

    Enum.filter(entries, &entry_matches_params?(&1, params))
  end

  defp create(module, params, state) do
    %{^module => entries} = state

    new_entry = module.create(params)
    {{:ok, new_entry}, %{state | module => [new_entry | entries]}}
  end

  defp entry_matches_params?(entry, params) do
    Enum.all?(params, fn {field, param_value} ->
      %{^field => entry_value} = entry
      entry_value === param_value
    end)
  end
end
