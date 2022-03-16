defmodule Chat.Store do
  use Agent

  alias Chat.Users.User
  alias Chat.Chats.{Chat, Message}

  @name {:global, __MODULE__}
  @entry_modules [User, Chat, Message]
  @initial_state Enum.into(@entry_modules, %{}, &{&1, []})

  def start_link(_opts) do
    case Agent.start_link(fn -> @initial_state end, name: @name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  def find_user(params \\ %{}) do
    Agent.get(@name, &find(User, params, &1))
  end

  def all_users(params \\ %{}) do
    Agent.get(@name, &all(User, params, &1))
  end

  def create_user(params \\ %{}) do
    Agent.get_and_update(@name, &create(User, params, &1))
  end

  def find_or_create_user(find_params, create_params) do
    case find_user(find_params) do
      {:ok, user} ->
        {:ok, user}

      {:error, :not_found} ->
        find_params
        |> Map.merge(create_params)
        |> create_user()
    end
  end

  def find_chat(params \\ %{}) do
    Agent.get(@name, &find(Chat, params, &1))
  end

  def all_chats(params \\ %{}) do
    Agent.get(@name, &all(Chat, params, &1))
  end

  def create_chat(params \\ %{}) do
    Agent.get_and_update(@name, &create(Chat, params, &1))
  end

  def find_message(params \\ %{}) do
    Agent.get(@name, &find(Message, params, &1))
  end

  def all_messages(params \\ %{}) do
    Agent.get(@name, &all(Message, params, &1))
  end

  def create_message(params \\ %{}) do
    Agent.get_and_update(@name, &create(Message, params, &1))
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

      cond do
        is_list(param_value) -> entry_value in param_value
        true -> entry_value === param_value
      end
    end)
  end
end
