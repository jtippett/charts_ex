# ChartsEx

SVG chart rendering for Elixir powered by [charts-rs](https://github.com/niclas-niclas/charts-rs).

10 chart types, 9 built-in themes, idiomatic builder API, and a Phoenix component for LiveView.

## Installation

Add `charts_ex` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:charts_ex, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
alias ChartsEx.BarChart

{:ok, svg} =
  BarChart.new()
  |> BarChart.title("Weekly Downloads")
  |> BarChart.theme(:grafana)
  |> BarChart.width(630)
  |> BarChart.height(410)
  |> BarChart.x_axis(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
  |> BarChart.add_series("Hex", [120.0, 200.0, 150.0, 80.0, 70.0, 110.0, 130.0])
  |> BarChart.add_series("npm", [60.0, 140.0, 190.0, 100.0, 50.0, 80.0, 120.0])
  |> ChartsEx.render()
```

## Chart Types

| Module | Description |
|--------|-------------|
| `ChartsEx.BarChart` | Vertical bar chart with optional line overlay |
| `ChartsEx.HorizontalBarChart` | Horizontal bar chart |
| `ChartsEx.LineChart` | Line chart with smooth curves and area fill |
| `ChartsEx.PieChart` | Pie and donut charts |
| `ChartsEx.RadarChart` | Radar/spider chart |
| `ChartsEx.ScatterChart` | Scatter plot |
| `ChartsEx.CandlestickChart` | Financial OHLC chart |
| `ChartsEx.HeatmapChart` | Color-coded grid |
| `ChartsEx.TableChart` | Data table rendered as SVG |
| `ChartsEx.MultiChart` | Combine multiple charts |

## Themes

Nine built-in themes: `:light` (default), `:dark`, `:grafana`, `:ant`, `:vintage`, `:walden`, `:westeros`, `:chalk`, `:shine`.

```elixir
BarChart.new() |> BarChart.theme(:dark)
```

List available themes with `ChartsEx.Theme.list/0`.

## Three Input Modes

### Builder structs (recommended)

```elixir
LineChart.new()
|> LineChart.title("Temperature")
|> LineChart.x_axis(["Mon", "Tue", "Wed"])
|> LineChart.add_series("City A", [22.0, 25.0, 28.0])
|> LineChart.smooth(true)
|> ChartsEx.render()
```

### Atom-key maps

```elixir
ChartsEx.render(%{
  type: :bar,
  title_text: "Downloads",
  series_list: [%{name: "Hex", data: [120.0, 200.0]}],
  x_axis_data: ["Mon", "Tue"]
})
```

### Raw JSON

```elixir
ChartsEx.render(~s({"type": "bar", "series_list": [...], "x_axis_data": [...]}))
```

## Phoenix / LiveView

Use the built-in component to render charts in HEEx templates:

```heex
<ChartsEx.Component.chart config={@chart} class="mx-auto max-w-2xl" id="sales" />
```

Or render manually:

```heex
{raw(ChartsEx.render!(@chart))}
```

## Raster Output (PNG, JPEG, etc.)

ChartsEx outputs SVG. For raster formats, use [Vix](https://hex.pm/packages/vix):

```elixir
{:ok, svg} = ChartsEx.render(chart)
{:ok, {image, _}} = Vix.Vips.Operation.svgload_buffer(svg)
Vix.Vips.Image.write_to_file(image, "chart.png")
```

## Building from Source

By default, ChartsEx uses precompiled binaries. To compile the Rust NIF locally:

```bash
export CHARTS_EX_BUILD=true
mix deps.compile charts_ex --force
```

Requires Rust 1.70+.

## License

MIT
