defmodule ChartsEx.Theme do
  @moduledoc """
  Built-in chart themes from charts-rs.

  Available themes: `:light`, `:dark`, `:grafana`, `:ant`, `:vintage`,
  `:walden`, `:westeros`, `:chalk`, `:shine`.
  """

  @themes ~w(light dark grafana ant vintage walden westeros chalk shine)a

  @doc "Returns the list of available theme atoms."
  @spec list() :: [atom()]
  def list, do: @themes

  @doc """
  Validates a theme name and returns its string representation.

  Raises `ArgumentError` if the theme is not recognized.
  """
  @spec validate!(atom()) :: String.t()
  def validate!(name) when name in @themes, do: Atom.to_string(name)

  def validate!(name) do
    raise ArgumentError,
          "unknown theme #{inspect(name)}, expected one of: #{inspect(@themes)}"
  end
end
