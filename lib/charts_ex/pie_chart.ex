defmodule ChartsEx.PieChart do
  @moduledoc """
  Pie chart with donut and rose variants.

  ## Example

      PieChart.new()
      |> PieChart.title("Market Share")
      |> PieChart.inner_radius(60.0)
      |> PieChart.add_series("Chrome", [60.0])
      |> PieChart.add_series("Firefox", [25.0])
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
    :x_axis_data,
    :series_list, :series_label_font_color, :series_label_font_size,
    :series_label_font_weight, :series_label_formatter, :series_label_position,
    :series_colors,
    # Pie-specific
    :radius, :inner_radius, :rose_type, :border_radius, :start_angle
  ]

  @doc "Creates a new empty pie chart."
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

  @doc """
  Adds a data series to the chart.

  ## Options

    * `:label_show` - whether to show value labels (boolean)
    * `:colors` - per-segment colors as list of hex strings

  """
  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  @doc "Sets the chart margin as `%{left: _, top: _, right: _, bottom: _}`."
  def margin(chart, m) when is_map(m), do: %{chart | margin: m}

  @doc "Sets series colors as a list of hex strings."
  def series_colors(chart, colors), do: %{chart | series_colors: colors}

  @doc "Sets the background color as a hex string."
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets the legend alignment. One of `:left`, `:center`, `:right`."
  def legend_align(chart, align) when align in [:left, :center, :right],
    do: %{chart | legend_align: align}

  @doc "Sets the legend margin."
  def legend_margin(chart, m), do: %{chart | legend_margin: m}

  @doc "Sets the outer radius of the pie."
  def radius(chart, r), do: %{chart | radius: r}

  @doc "Sets the inner radius to create a donut chart. Use 0.0 for solid pie."
  def inner_radius(chart, r), do: %{chart | inner_radius: r}

  @doc "Enables rose/nightingale chart mode."
  def rose_type(chart, val), do: %{chart | rose_type: val}

  @doc "Sets the border radius for pie segments."
  def border_radius(chart, r), do: %{chart | border_radius: r}

  @doc "Sets the starting angle in degrees."
  def start_angle(chart, angle), do: %{chart | start_angle: angle}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "pie")
end
