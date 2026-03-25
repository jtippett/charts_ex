defmodule ChartsEx.LineChart do
  @moduledoc """
  Line chart with smooth curves, area fill, and mark lines/points.

  ## Example

      LineChart.new()
      |> LineChart.title("Temperature")
      |> LineChart.x_axis(["Mon", "Tue", "Wed"])
      |> LineChart.add_series("City A", [22.0, 25.0, 28.0])
      |> LineChart.smooth(true)
      |> ChartsEx.render()
  """

  @behaviour ChartsEx.Chart

  defstruct [
    # Title
    :title_text,
    :title_font_size,
    :title_font_color,
    :title_font_weight,
    :title_margin,
    :title_align,
    :title_height,
    # Subtitle
    :sub_title_text,
    :sub_title_font_size,
    :sub_title_font_color,
    :sub_title_font_weight,
    :sub_title_margin,
    :sub_title_align,
    :sub_title_height,
    # Layout
    :width,
    :height,
    :margin,
    :font_family,
    :background_color,
    :theme,
    # Legend
    :legend_font_size,
    :legend_font_color,
    :legend_font_weight,
    :legend_align,
    :legend_margin,
    :legend_category,
    :legend_show,
    # X Axis
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
    :x_boundary_gap,
    # Y Axis
    :y_axis_configs,
    :y_axis_hidden,
    # Grid
    :grid_stroke_color,
    :grid_stroke_width,
    # Series styling
    :series_list,
    :series_stroke_width,
    :series_label_font_color,
    :series_label_font_size,
    :series_label_font_weight,
    :series_label_formatter,
    :series_colors,
    :series_symbol,
    :series_smooth,
    :series_fill
  ]

  @doc "Creates a new empty line chart."
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
  def x_axis(chart, labels) when is_list(labels), do: %{chart | x_axis_data: labels}

  @doc """
  Adds a data series to the chart.

  ## Options

    * `:label_show` - whether to show value labels (boolean)
    * `:y_axis_index` - which y-axis to use (0 or 1)
    * `:mark_lines` - list of mark lines, e.g. `[%{category: "average"}]`
    * `:mark_points` - list of mark points, e.g. `[%{category: "max"}]`
    * `:stroke_dash_array` - dash pattern, e.g. `"4,2"`

  """
  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  @doc "Sets the chart margin as `%{left: _, top: _, right: _, bottom: _}`."
  def margin(chart, m) when is_map(m), do: %{chart | margin: m}

  @doc "Sets y-axis configurations. Pass a list of config maps for dual y-axis."
  def y_axis_configs(chart, configs) when is_list(configs), do: %{chart | y_axis_configs: configs}

  @doc "Sets series colors as a list of hex strings."
  def series_colors(chart, colors) when is_list(colors), do: %{chart | series_colors: colors}

  @doc "Sets the background color as a hex string."
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets the legend alignment. One of `:left`, `:center`, `:right`."
  def legend_align(chart, align) when align in [:left, :center, :right],
    do: %{chart | legend_align: align}

  @doc "Sets the legend margin."
  def legend_margin(chart, m) when is_map(m), do: %{chart | legend_margin: m}

  @doc "Enables smooth curve interpolation."
  def smooth(chart, val \\ true), do: %{chart | series_smooth: val}

  @doc "Enables area fill below the line."
  def fill(chart, val \\ true), do: %{chart | series_fill: val}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "line")
end
