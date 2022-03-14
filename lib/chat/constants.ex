defmodule Chat.Constants do
  @type color :: atom

  @colors [
    :red,
    :orange,
    :amber,
    :yellow,
    :lime,
    :green,
    :emerald,
    :teal,
    :cyan,
    :sky,
    :blue,
    :indigo,
    :violet,
    :purple,
    :fuchsia,
    :pink,
    :rose
  ]

  def colors, do: @colors
end
