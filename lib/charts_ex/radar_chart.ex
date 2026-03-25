defmodule ChartsEx.RadarChart do
  @moduledoc """
  Radar (spider) chart for multi-dimensional data.

  ## Example

      RadarChart.new()
      |> RadarChart.title("Skill Assessment")
      |> RadarChart.indicators([
        %{name: "Frontend", max: 100.0},
        %{name: "Backend", max: 100.0},
        %{name: "DevOps", max: 100.0}
      ])
      |> RadarChart.add_series("Alice", [80.0, 90.0, 70.0])
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
    :x_axis_font_size,
    :x_axis_font_color,
    :y_axis_configs,
    :grid_stroke_color,
    :grid_stroke_width,
    :series_list,
    :series_stroke_width,
    :series_label_font_color,
    :series_label_font_size,
    :series_label_font_weight,
    :series_label_formatter,
    :series_colors,
    :series_symbol,
    :series_smooth,
    :series_fill,
    # Radar-specific
    :indicators
  ]

  @doc "Creates a new empty radar chart."
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

  Data is a list of numeric values, one per indicator.

  ## Options

    * `:label_show` - whether to show value labels (boolean)

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

  @doc "Sets radar indicators. Each is `%{name: \"Label\", max: 100.0}`."
  def indicators(chart, indicators) when is_list(indicators),
    do: %{chart | indicators: indicators}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "radar")
end
