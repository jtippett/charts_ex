# charts_ex Design

Elixir NIF wrapper for the charts-rs Rust library. Provides an idiomatic, typed Elixir API for generating SVG charts, with optional Phoenix LiveView integration.

## Goals

- Release-quality community package on Hex
- Idiomatic Elixir API with builder pattern and typed structs
- All 10 charts-rs chart types from v0.1.0
- Phoenix function component for LiveView integration (no hard Phoenix dependency)
- Precompiled binaries via rustler_precompiled
- SVG-only output; document Vix for raster conversion

## API Design

### Three Input Modes

**1. Builder structs (primary):**

```elixir
alias ChartsEx.BarChart

BarChart.new()
|> BarChart.title("Weekly Downloads")
|> BarChart.theme(:grafana)
|> BarChart.width(630)
|> BarChart.height(410)
|> BarChart.x_axis(["Mon", "Tue", "Wed", "Thu", "Fri"])
|> BarChart.add_series("Hex", [120.0, 200.0, 150.0, 80.0, 70.0])
|> BarChart.add_series("npm", [60.0, 140.0, 190.0, 100.0, 50.0], label_show: true)
|> ChartsEx.render()
# => {:ok, "<svg ...>"}
```

**2. Atom-key maps (dynamic/programmatic):**

```elixir
ChartsEx.render(%{
  type: :bar,
  title_text: "Downloads",
  series_list: [%{name: "Hex", data: [120.0, 200.0]}],
  x_axis_data: ["Mon", "Tue"]
})
```

**3. Raw JSON (escape hatch):**

```elixir
ChartsEx.render(~s({"type": "bar", ...}))
```

All converge on the same NIF call. `render!/1` raises on error.

### Chart Module Pattern

Each chart type gets its own module with a struct and builder functions. Top-level structs only — nested config (series, y-axis, margins) uses keyword lists or plain maps.

```elixir
defmodule ChartsEx.BarChart do
  @behaviour ChartsEx.Chart

  defstruct [
    :title_text, :sub_title_text, :theme, :width, :height,
    :margin, :legend_align, :legend_margin, :legend_category,
    :title_font_size, :title_font_color, :title_font_weight,
    :sub_title_font_size, :sub_title_font_color,
    :y_axis_configs, :x_axis_font_size, :x_axis_data,
    :series_list, :background_color, :font_family
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  @impl true
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "bar")
end
```

- `nil` fields omitted from JSON — charts-rs applies its own defaults
- `add_series/4` takes keyword opts for `label_show`, `mark_lines`, `colors`, etc.
- Chart-specific functions (e.g., `PieChart.inner_radius/2`) live only on the relevant module

### Chart Types (all 10)

| Module | Type String | Notes |
|--------|-------------|-------|
| `ChartsEx.BarChart` | `"bar"` | Dual y-axis, line overlay via series category |
| `ChartsEx.HorizontalBarChart` | `"horizontal_bar"` | |
| `ChartsEx.LineChart` | `"line"` | Smooth curves, area fill, mark lines/points |
| `ChartsEx.PieChart` | `"pie"` | Inner radius (donut), rose type |
| `ChartsEx.RadarChart` | `"radar"` | Multi-dimensional with indicators |
| `ChartsEx.ScatterChart` | `"scatter"` | X/Y coordinate plots |
| `ChartsEx.CandlestickChart` | `"candlestick"` | Financial OHLC data |
| `ChartsEx.HeatmapChart` | `"heatmap"` | Color gradients with min/max |
| `ChartsEx.TableChart` | `"table"` | Cell styling, column spanning |
| `ChartsEx.MultiChart` | `"multi_chart"` | Combines multiple charts |

## Architecture

### Render Pipeline

```
Elixir struct/map/JSON
        |
        v
  ChartsEx.render/1 — dispatches by input type
        |
        v
  JSON string (via ChartsEx.Serializer or Jason or pass-through)
        |
        v
  ChartsEx.Native.render/1 — Rustler NIF (DirtyCpu)
        |
        v
  Rust: parse JSON → dispatch on "type" → charts-rs from_json() → svg()
        |
        v
  {:ok, "<svg ...>"} | {:error, "message"}
```

### Rust NIF

Single function, thin dispatch layer:

```rust
#[rustler::nif(schedule = "DirtyCpu")]
fn render(json: &str) -> Result<String, String> {
    let value: serde_json::Value = serde_json::from_str(json)
        .map_err(|e| format!("invalid JSON: {e}"))?;

    let chart_type = value.get("type")
        .and_then(|v| v.as_str())
        .ok_or("missing \"type\" field")?;

    match chart_type {
        "bar" => BarChart::from_json(json).and_then(|c| c.svg()),
        "line" => LineChart::from_json(json).and_then(|c| c.svg()),
        // ... all 10 types
        _ => Err(format!("unknown chart type: {chart_type}").into())
    }
    .map_err(|e| e.to_string())
}
```

`DirtyCpu` scheduling prevents chart rendering from blocking the BEAM scheduler.

### Elixir Dispatch

```elixir
def render(%mod{} = chart) do
  chart |> mod.to_json() |> ChartsEx.Native.render()
end

def render(map) when is_map(map) do
  map |> stringify_keys() |> Jason.encode!() |> ChartsEx.Native.render()
end

def render(json) when is_binary(json) do
  ChartsEx.Native.render(json)
end
```

### Serialization

`ChartsEx.Serializer` — shared module that all chart types delegate to:
- Converts struct to map
- Drops nil values
- Injects `"type"` key
- Converts atom values to strings where needed (theme, legend_align, etc.)
- Encodes to JSON via Jason

## Phoenix Component

Optional — guarded behind `Code.ensure_loaded?(Phoenix.Component)`.

```elixir
defmodule ChartsEx.Component do
  if Code.ensure_loaded?(Phoenix.Component) do
    use Phoenix.Component

    attr :config, :any, required: true
    attr :class, :string, default: nil
    attr :id, :string, default: nil

    def chart(assigns) do
      svg = ChartsEx.render!(assigns.config)
      assigns = assign(assigns, :svg, svg)

      ~H"""
      <div id={@id} class={@class}>{raw(@svg)}</div>
      """
    end
  end
end
```

Usage:

```heex
<ChartsEx.Component.chart config={@chart} class="mx-auto" id="revenue" />
```

## Themes

9 built-in themes via atom validation:

```elixir
defmodule ChartsEx.Theme do
  @themes ~w(light dark grafana ant vintage walden westeros chalk shine)a

  def list, do: @themes
  def validate!(name) when name in @themes, do: Atom.to_string(name)
  def validate!(name), do: raise ArgumentError, "unknown theme ..."
end
```

## Raster Output

SVG-only from the NIF. For raster conversion, document using Vix:

```elixir
{:ok, svg} = ChartsEx.render(chart)
{:ok, {image, _}} = Vix.Vips.Operation.svgload_buffer(svg)
Vix.Vips.Image.write_to_file(image, "chart.png")
```

## Precompiled Binaries

Via `rustler_precompiled`. Targets:
- aarch64-apple-darwin
- x86_64-apple-darwin
- aarch64-unknown-linux-gnu
- x86_64-unknown-linux-gnu
- x86_64-unknown-linux-musl

Fallback to local Rust compilation with `CHARTS_EX_BUILD=true mix compile`.

## Project Structure

```
charts_ex/
├── lib/
│   ├── charts_ex.ex
│   └── charts_ex/
│       ├── native.ex
│       ├── chart.ex              # Behaviour
│       ├── serializer.ex         # Shared JSON serialization
│       ├── theme.ex
│       ├── component.ex          # Phoenix function component
│       ├── bar_chart.ex
│       ├── horizontal_bar_chart.ex
│       ├── line_chart.ex
│       ├── pie_chart.ex
│       ├── radar_chart.ex
│       ├── scatter_chart.ex
│       ├── candlestick_chart.ex
│       ├── heatmap_chart.ex
│       ├── table_chart.ex
│       └── multi_chart.ex
├── native/charts_ex/
│   ├── src/lib.rs
│   └── Cargo.toml
├── test/
│   ├── charts_ex_test.exs
│   ├── bar_chart_test.exs
│   ├── line_chart_test.exs
│   └── ...
├── mix.exs
└── README.md
```
