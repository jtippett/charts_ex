defmodule ChartsEx.HorizontalBarChart do
  @moduledoc """
  Horizontal bar chart.

  ## Example

      HorizontalBarChart.new()
      |> HorizontalBarChart.title("Language Popularity")
      |> HorizontalBarChart.x_axis(["Go", "Rust", "Elixir"])
      |> HorizontalBarChart.add_series("Stars", [5000.0, 8000.0, 3000.0])
      |> ChartsEx.render()
  """

  @behaviour ChartsEx.Chart

  defstruct [
    :title_text, :title_font_size, :title_font_color, :title_font_weight,
    :title_margin, :title_align, :title_height,
    :sub_title_text, :sub_title_font_size, :sub_title_font_color,
    :sub_title_font_weight, :sub_title_margin, :sub_title_align, :sub_title_height,
    :width, :height, :margin, :font_family, :background_color, :theme,
    :legend_font_size, :legend_font_color, :legend_font_weight,
    :legend_align, :legend_margin, :legend_category, :legend_show,
    :x_axis_data, :x_axis_height, :x_axis_stroke_color,
    :x_axis_font_size, :x_axis_font_color, :x_axis_font_weight,
    :x_axis_name_gap, :x_axis_name_rotate, :x_axis_margin, :x_boundary_gap,
    :y_axis_configs,
    :grid_stroke_color, :grid_stroke_width,
    :series_list, :series_stroke_width, :series_label_font_color,
    :series_label_font_size, :series_label_font_weight, :series_label_formatter,
    :series_colors, :series_symbol, :series_smooth, :series_fill,
    # HorizontalBar-specific
    :series_label_position
  ]

  @doc "Creates a new empty horizontal bar chart."
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

  @doc """
  Adds a data series to the chart.

  ## Options

    * `:label_show` - whether to show value labels (boolean)
    * `:y_axis_index` - which y-axis to use (0 or 1)
    * `:mark_lines` - list of mark lines, e.g. `[%{category: "average"}]`
    * `:mark_points` - list of mark points, e.g. `[%{category: "max"}]`
    * `:colors` - per-bar colors as list of hex strings

  """
  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  @doc "Sets the chart margin as `%{left: _, top: _, right: _, bottom: _}`."
  def margin(chart, m), do: %{chart | margin: m}

  @doc "Sets y-axis configurations. Pass a list of config maps for dual y-axis."
  def y_axis_configs(chart, configs), do: %{chart | y_axis_configs: configs}

  @doc "Sets series colors as a list of hex strings."
  def series_colors(chart, colors), do: %{chart | series_colors: colors}

  @doc "Sets the background color as a hex string."
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets the legend alignment. One of `:left`, `:center`, `:right`."
  def legend_align(chart, align), do: %{chart | legend_align: align}

  @doc "Sets label position. One of `:inside`, `:top`, `:right`, `:bottom`, `:left`."
  def label_position(chart, pos), do: %{chart | series_label_position: pos}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "horizontal_bar")
end
