defmodule ChartsEx.MultiChart do
  @moduledoc """
  Combines multiple charts into a single SVG.

  ## Example

      bar = BarChart.new() |> BarChart.title("Sales") |> ...
      line = LineChart.new() |> LineChart.title("Trend") |> ...

      MultiChart.new()
      |> MultiChart.add_chart(bar)
      |> MultiChart.add_chart(line)
      |> MultiChart.gap(20.0)
      |> ChartsEx.render()
  """

  @behaviour ChartsEx.Chart

  defstruct [
    :gap,
    :margin,
    :background_color,
    child_charts: []
  ]

  @chart_type_map %{
    ChartsEx.BarChart => "bar",
    ChartsEx.HorizontalBarChart => "horizontal_bar",
    ChartsEx.LineChart => "line",
    ChartsEx.PieChart => "pie",
    ChartsEx.RadarChart => "radar",
    ChartsEx.ScatterChart => "scatter",
    ChartsEx.CandlestickChart => "candlestick",
    ChartsEx.TableChart => "table",
    ChartsEx.HeatmapChart => "heatmap"
  }

  @doc "Creates a new empty multi-chart container."
  def new, do: %__MODULE__{}

  @doc """
  Adds a child chart. Optionally pass `x:` and `y:` for positioning.

      MultiChart.add_chart(multi, bar_chart, x: 0.0, y: 0.0)
  """
  def add_chart(multi, %mod{} = chart, opts \\ []) do
    type = Map.fetch!(@chart_type_map, mod)
    child = %{chart: chart, type: type, x: opts[:x], y: opts[:y]}
    %{multi | child_charts: multi.child_charts ++ [child]}
  end

  @doc "Sets the gap between charts in pixels."
  def gap(multi, g), do: %{multi | gap: g}

  @doc "Sets the outer margin."
  def margin(multi, m), do: %{multi | margin: m}

  @doc "Sets the background color."
  def background_color(multi, c), do: %{multi | background_color: c}

  @impl ChartsEx.Chart
  def to_json(multi) do
    child_charts =
      Enum.map(multi.child_charts, fn %{chart: chart, type: type, x: x, y: y} ->
        chart_json = chart |> chart.__struct__.to_json() |> Jason.decode!()
        chart_json = Map.put(chart_json, "type", type)
        chart_json = Map.put_new(chart_json, "theme", "")
        chart_json = if x, do: Map.put(chart_json, "x", x), else: chart_json
        chart_json = if y, do: Map.put(chart_json, "y", y), else: chart_json
        chart_json
      end)

    base =
      %{type: "multi_chart", child_charts: child_charts}
      |> then(fn m -> if multi.gap, do: Map.put(m, :gap, multi.gap), else: m end)
      |> then(fn m -> if multi.margin, do: Map.put(m, :margin, multi.margin), else: m end)
      |> then(fn m ->
        if multi.background_color,
          do: Map.put(m, :background_color, multi.background_color),
          else: m
      end)

    Jason.encode!(base)
  end
end
