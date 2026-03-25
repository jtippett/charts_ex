defmodule ChartsEx do
  @moduledoc """
  SVG chart rendering for Elixir powered by charts-rs.

  ## Usage

  Three input modes are supported:

  ### Builder structs (recommended)

      alias ChartsEx.BarChart

      BarChart.new()
      |> BarChart.title("Downloads")
      |> BarChart.x_axis(["Mon", "Tue", "Wed"])
      |> BarChart.add_series("Hex", [120.0, 200.0, 150.0])
      |> ChartsEx.render()

  ### Atom-key maps

      ChartsEx.render(%{
        type: :bar,
        title_text: "Downloads",
        series_list: [%{name: "Hex", data: [120.0, 200.0]}],
        x_axis_data: ["Mon", "Tue"]
      })

  ### Raw JSON

      ChartsEx.render(~s({"type": "bar", ...}))

  """

  @type_map %{
    bar: "bar",
    horizontal_bar: "horizontal_bar",
    line: "line",
    pie: "pie",
    radar: "radar",
    scatter: "scatter",
    candlestick: "candlestick",
    heatmap: "heatmap",
    table: "table",
    multi_chart: "multi_chart"
  }

  @doc """
  Renders a chart to SVG.

  Accepts a chart struct, atom-key map with `:type`, or raw JSON string.

  Returns `{:ok, svg_string}` or `{:error, message}`.
  """
  @spec render(struct() | map() | String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def render(%mod{} = chart) do
    chart |> mod.to_json() |> ChartsEx.Native.render()
  end

  def render(map) when is_map(map) do
    map
    |> stringify_map()
    |> Jason.encode!()
    |> ChartsEx.Native.render()
  end

  def render(json) when is_binary(json) do
    ChartsEx.Native.render(json)
  end

  @doc """
  Like `render/1` but raises on error.
  """
  @spec render!(struct() | map() | String.t()) :: String.t()
  def render!(input) do
    case render(input) do
      {:ok, svg} -> svg
      {:error, msg} -> raise RuntimeError, "ChartsEx render error: #{msg}"
    end
  end

  defp stringify_map(map) when is_map(map) do
    Map.new(map, fn
      {:type, v} when is_atom(v) -> {"type", Map.get(@type_map, v, Atom.to_string(v))}
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_value(v)}
      {k, v} -> {k, stringify_value(v)}
    end)
  end

  defp stringify_value(v) when is_map(v), do: stringify_map(v)
  defp stringify_value(v) when is_list(v), do: Enum.map(v, &stringify_value/1)

  defp stringify_value(v) when is_atom(v) and not is_nil(v) and not is_boolean(v),
    do: Atom.to_string(v)

  defp stringify_value(v), do: v
end
