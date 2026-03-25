defmodule ChartsEx.TableChart do
  @moduledoc """
  Table chart rendered as SVG.

  ## Example

      TableChart.new()
      |> TableChart.title("Results")
      |> TableChart.data([
        ["Name", "Score"],
        ["Alice", "95"],
        ["Bob", "87"]
      ])
      |> ChartsEx.render()
  """

  @behaviour ChartsEx.Chart

  defstruct [
    :title_text, :title_font_size, :title_font_color, :title_font_weight,
    :title_margin, :title_align, :title_height,
    :sub_title_text, :sub_title_font_size, :sub_title_font_color,
    :sub_title_font_weight, :sub_title_margin, :sub_title_align, :sub_title_height,
    :width, :height, :font_family, :background_color, :theme,
    # Table-specific
    :data, :spans, :text_aligns, :border_color, :outlined,
    :header_row_padding, :header_row_height, :header_font_size,
    :header_font_weight, :header_font_color, :header_background_color,
    :body_row_padding, :body_row_height, :body_font_size,
    :body_font_color, :body_background_colors,
    :cell_styles
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets table data as a 2D list. First row is the header."
  def data(chart, rows) when is_list(rows), do: %{chart | data: rows}

  @doc "Sets column width proportions as a list of floats."
  def spans(chart, spans) when is_list(spans), do: %{chart | spans: spans}

  @doc "Sets per-column text alignment. List of `:left`, `:center`, `:right`."
  def text_aligns(chart, aligns) when is_list(aligns), do: %{chart | text_aligns: aligns}

  @doc "Sets the border color."
  def border_color(chart, color), do: %{chart | border_color: color}

  @doc "Sets the header background color."
  def header_background_color(chart, color), do: %{chart | header_background_color: color}

  @doc "Sets the header font color."
  def header_font_color(chart, color), do: %{chart | header_font_color: color}

  @doc "Sets alternating body row background colors."
  def body_background_colors(chart, colors), do: %{chart | body_background_colors: colors}

  @doc "Sets cell-level styling. List of `%{indexes: [i], font_color: \"#000\", ...}`."
  def cell_styles(chart, styles) when is_list(styles), do: %{chart | cell_styles: styles}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "table")
end
