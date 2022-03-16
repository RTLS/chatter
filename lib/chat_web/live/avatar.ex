defmodule ChatWeb.Avatar do
  @moduledoc "functional component for displaying avatars"

  use Phoenix.Component

  def large(assigns) do
    ~H"""
    <div class="relative inline-block">
      <span class={"flex inline-block align-middle w-12 h-12 rounded-full bg-#{@user.color}-600 text-xl text-center"}>
        <div class="m-auto uppercase">
          <p><%= @user.avatar %></p>
        </div>
      </span>
      <%= if @online do %>
        <span class="absolute bottom-0 right-0 inline-block w-3 h-3 bg-green-500 border border-white rounded-full"></span>
      <% end %>
    </div>
    """
  end

  def medium(assigns) do
    ~H"""
    <div class="relative inline-block">
      <span class={"flex inline-block align-middle w-8 h-8 rounded-full bg-#{@user.color}-600 text-sm text-center"}>
        <div class="m-auto uppercase">
          <p><%= @user.avatar %></p>
        </div>
      </span>
      <%= if @online do %>
        <span class="absolute bottom-0 right-0 inline-block w-2 h-2 bg-green-500 border border-white rounded-full"></span>
      <% end %>
    </div>
    """
  end

  def small(assigns) do
    ~H"""
    <div class="relative inline-block">
      <span class={"flex inline-block align-middle w-6 h-6 rounded-full bg-#{@user.color}-600 text-xs text-center"}>
        <div class="m-auto uppercase">
          <p><%= @user.avatar %></p>
        </div>
      </span>
      <%= if @online do %>
        <span class="absolute bottom-0 right-0 inline-block w-2 h-2 bg-green-500 border border-white rounded-full"></span>
      <% end %>
    </div>
    """
  end
end
