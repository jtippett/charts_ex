defmodule ChartsEx.HeatmapChart do
  @moduledoc """
  Heatmap chart with color gradient.

  ## Example

      HeatmapChart.new()
      |> HeatmapChart.title("Activity")
      |> HeatmapChart.x_axis(["Mon", "Tue", "Wed"])
      |> HeatmapChart.y_axis(["Morning", "Afternoon"])
      |> HeatmapChart.series(%{
        data: [[0, 0, 5], [1, 0, 10]],
        min: 0, max: 30,
        min_color: "#C6E48B", max_color: "#196127"
      })
      |> ChartsEx.render()
  """

  @behaviour ChartsEx.Chart

  defstruct [
    :title_text,
    :title_font_size,
    :title_font_color,
    :title_font_weight,
    :title_margin,
    :title_align,
    :title_height,
    :sub_title_text,
    :sub_title_font_size,
    :sub_title_font_color,
    :sub_title_font_weight,
    :sub_title_margin,
    :sub_title_align,
    :sub_title_height,
    :width,
    :height,
    :margin,
    :font_family,
    :background_color,
    :theme,
    :legend_font_size,
    :legend_font_color,
    :legend_font_weight,
    :legend_align,
    :legend_margin,
    :legend_category,
    :legend_show,
    :x_axis_data,
    :x_axis_height,
    :x_axis_stroke_color,
    :x_axis_font_size,
    :x_axis_font_color,
    :x_axis_font_weight,
    :x_axis_name_gap,
    :x_axis_name_rotate,
    :x_axis_margin,
    :x_axis_hidden,
    :series_list,
    :series_label_font_color,
    :series_label_font_size,
    :series_label_font_weight,
    :series_label_formatter,
    :series_colors,
    # Heatmap-specific
    :series,
    :y_axis_data
  ]

  @doc "Creates a new empty heatmap chart."
  def new, do: %__MODULE__{}

  @doc "Sets the chart title."
  def title(chart, text), do: %{chart | title_text: text}

  @doc "Sets the chart subtitle."
  def sub_title(chart, text), do: %{chart | sub_title_text: text}

  @doc "Sets the theme. See `ChartsEx.Theme.list/0` for options."
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}

  @doc "Sets the chart width in pixels."
  def width(chart, w), do: %{chart | width: w}

  @doc "Sets the chart height in pixels."
  def height(chart, h), do: %{chart | height: h}

  @doc "Sets the x-axis category labels."
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}

  @doc "Sets the chart margin as `%{left: _, top: _, right: _, bottom: _}`."
  def margin(chart, m) when is_map(m), do: %{chart | margin: m}

  @doc "Sets the background color as a hex string."
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets the y-axis row labels."
  def y_axis(chart, labels) when is_list(labels), do: %{chart | y_axis_data: labels}

  @doc """
  Sets the heatmap data series.

  Expects a map with:
    * `:data` - list of `[x_index, y_index, value]` triples
    * `:min` / `:max` - value range
    * `:min_color` / `:max_color` - hex color strings for gradient endpoints
  """
  def series(chart, series) when is_map(series), do: %{chart | series: series}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "heatmap")
end
