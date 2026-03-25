# ChartsEx

<!-- Badges: uncomment and update URLs when published -->
<!-- [![Hex.pm](https://img.shields.io/hexpm/v/charts_ex.svg)](https://hex.pm/packages/charts_ex) -->
<!-- [![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/charts_ex) -->
<!-- [![CI](https://github.com/jtippett/charts_ex/actions/workflows/ci.yml/badge.svg)](https://github.com/jtippett/charts_ex/actions) -->

SVG chart rendering for Elixir powered by [charts-rs](https://github.com/niclas-niclas/charts-rs) -- 10 chart types, 9 built-in themes, an idiomatic builder API, and a Phoenix component for LiveView.

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
  |> BarChart.title("Monthly Revenue")
  |> BarChart.theme(:grafana)
  |> BarChart.width(600)
  |> BarChart.height(400)
  |> BarChart.x_axis(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> BarChart.add_series("Revenue ($k)", [48.2, 53.1, 61.7, 59.3, 72.0, 84.5])
  |> ChartsEx.render()

# svg is a self-contained SVG string -- write it to a file, embed it in HTML, etc.
File.write!("revenue.svg", svg)
```

## Examples

### Bar Chart

Basic vertical bar chart with two series and a theme:

```elixir
alias ChartsEx.BarChart

{:ok, svg} =
  BarChart.new()
  |> BarChart.title("Quarterly Sales by Region")
  |> BarChart.sub_title("FY 2025 — All figures in $k")
  |> BarChart.theme(:ant)
  |> BarChart.width(700)
  |> BarChart.height(420)
  |> BarChart.x_axis(["Q1", "Q2", "Q3", "Q4"])
  |> BarChart.add_series("North America", [312.0, 348.0, 295.0, 410.0])
  |> BarChart.add_series("Europe", [228.0, 265.0, 241.0, 302.0])
  |> BarChart.series_colors(["#5470C6", "#91CC75"])
  |> BarChart.legend_align(:right)
  |> BarChart.radius(4.0)
  |> ChartsEx.render()
```

Bar chart with a line overlay (dual series types) and mark lines:

```elixir
alias ChartsEx.BarChart

{:ok, svg} =
  BarChart.new()
  |> BarChart.title("Website Traffic vs. Conversion Rate")
  |> BarChart.theme(:walden)
  |> BarChart.width(720)
  |> BarChart.height(400)
  |> BarChart.x_axis(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> BarChart.y_axis_configs([
    %{axis_font_size: 12},
    %{axis_font_size: 12}
  ])
  |> BarChart.add_series("Visitors", [14200.0, 16800.0, 15400.0, 18900.0, 21300.0, 24100.0],
    mark_lines: [%{category: "average"}]
  )
  |> BarChart.add_series("Conversion %", [2.1, 2.4, 1.9, 3.0, 3.5, 3.8],
    category: "line",
    y_axis_index: 1,
    stroke_dash_array: "4,2"
  )
  |> ChartsEx.render()
```

### Line Chart

Smooth curves with area fill:

```elixir
alias ChartsEx.LineChart

{:ok, svg} =
  LineChart.new()
  |> LineChart.title("Server Response Times")
  |> LineChart.sub_title("p50 and p99 latency in ms")
  |> LineChart.theme(:grafana)
  |> LineChart.width(700)
  |> LineChart.height(400)
  |> LineChart.smooth(true)
  |> LineChart.fill(true)
  |> LineChart.x_axis(["00:00", "04:00", "08:00", "12:00", "16:00", "20:00", "23:59"])
  |> LineChart.add_series("p50", [12.0, 8.0, 35.0, 62.0, 48.0, 24.0, 14.0])
  |> LineChart.add_series("p99", [45.0, 28.0, 120.0, 210.0, 165.0, 78.0, 52.0],
    mark_lines: [%{category: "average"}],
    mark_points: [%{category: "max"}]
  )
  |> LineChart.series_colors(["#73C0DE", "#EE6666"])
  |> ChartsEx.render()
```

### Pie Chart

Donut chart with inner radius:

```elixir
alias ChartsEx.PieChart

{:ok, svg} =
  PieChart.new()
  |> PieChart.title("Browser Market Share")
  |> PieChart.sub_title("Global — March 2025")
  |> PieChart.theme(:westeros)
  |> PieChart.width(500)
  |> PieChart.height(400)
  |> PieChart.inner_radius(80.0)
  |> PieChart.radius(150.0)
  |> PieChart.border_radius(4.0)
  |> PieChart.add_series("Chrome", [64.7])
  |> PieChart.add_series("Safari", [18.6])
  |> PieChart.add_series("Firefox", [3.2])
  |> PieChart.add_series("Edge", [5.3])
  |> PieChart.add_series("Other", [8.2])
  |> PieChart.series_colors(["#5470C6", "#91CC75", "#FAC858", "#EE6666", "#73C0DE"])
  |> ChartsEx.render()
```

### Horizontal Bar Chart

```elixir
alias ChartsEx.HorizontalBarChart

{:ok, svg} =
  HorizontalBarChart.new()
  |> HorizontalBarChart.title("Top Programming Languages by Job Postings")
  |> HorizontalBarChart.theme(:ant)
  |> HorizontalBarChart.width(650)
  |> HorizontalBarChart.height(400)
  |> HorizontalBarChart.x_axis([
    "Elixir", "Go", "Rust", "TypeScript", "Python", "Java"
  ])
  |> HorizontalBarChart.add_series("Job Postings (thousands)", [
    8.4, 22.1, 12.7, 58.3, 92.5, 74.0
  ], label_show: true)
  |> HorizontalBarChart.series_colors(["#5470C6"])
  |> ChartsEx.render()
```

### Radar Chart

Multi-dimensional comparison with indicators:

```elixir
alias ChartsEx.RadarChart

{:ok, svg} =
  RadarChart.new()
  |> RadarChart.title("Framework Comparison")
  |> RadarChart.sub_title("Phoenix vs. Rails vs. Next.js")
  |> RadarChart.theme(:vintage)
  |> RadarChart.width(560)
  |> RadarChart.height(460)
  |> RadarChart.indicators([
    %{name: "Performance", max: 100.0},
    %{name: "Scalability", max: 100.0},
    %{name: "Ecosystem", max: 100.0},
    %{name: "Learning Curve", max: 100.0},
    %{name: "Realtime", max: 100.0},
    %{name: "Deployment", max: 100.0}
  ])
  |> RadarChart.add_series("Phoenix", [92.0, 95.0, 58.0, 55.0, 98.0, 72.0])
  |> RadarChart.add_series("Rails", [65.0, 70.0, 90.0, 75.0, 50.0, 80.0])
  |> RadarChart.add_series("Next.js", [78.0, 72.0, 95.0, 68.0, 65.0, 88.0])
  |> RadarChart.series_colors(["#6C5CE7", "#E17055", "#00B894"])
  |> ChartsEx.render()
```

### Scatter Chart

```elixir
alias ChartsEx.ScatterChart

{:ok, svg} =
  ScatterChart.new()
  |> ScatterChart.title("House Price vs. Square Footage")
  |> ScatterChart.sub_title("Austin, TX — 2025 listings")
  |> ScatterChart.theme(:walden)
  |> ScatterChart.width(650)
  |> ScatterChart.height(420)
  |> ScatterChart.add_series("3-Bedroom", [
    [1200.0, 285.0], [1450.0, 320.0], [1680.0, 375.0],
    [1890.0, 410.0], [2100.0, 465.0], [2350.0, 520.0],
    [1550.0, 340.0], [1750.0, 390.0], [2000.0, 445.0]
  ])
  |> ScatterChart.add_series("4-Bedroom", [
    [1800.0, 420.0], [2050.0, 485.0], [2300.0, 540.0],
    [2600.0, 610.0], [2850.0, 675.0], [3100.0, 740.0],
    [2200.0, 520.0], [2500.0, 590.0], [2750.0, 650.0]
  ])
  |> ScatterChart.symbol_sizes([6.0, 8.0])
  |> ScatterChart.series_colors(["#5470C6", "#EE6666"])
  |> ChartsEx.render()
```

### Candlestick Chart

Financial OHLC data:

```elixir
alias ChartsEx.CandlestickChart

{:ok, svg} =
  CandlestickChart.new()
  |> CandlestickChart.title("AAPL Stock Price")
  |> CandlestickChart.sub_title("Weekly — Jan to Mar 2025")
  |> CandlestickChart.theme(:dark)
  |> CandlestickChart.width(750)
  |> CandlestickChart.height(420)
  |> CandlestickChart.up_color("#26A69A")
  |> CandlestickChart.up_border_color("#26A69A")
  |> CandlestickChart.down_color("#EF5350")
  |> CandlestickChart.down_border_color("#EF5350")
  |> CandlestickChart.x_axis([
    "Jan 6", "Jan 13", "Jan 20", "Jan 27",
    "Feb 3", "Feb 10", "Feb 17", "Feb 24",
    "Mar 3", "Mar 10", "Mar 17", "Mar 24"
  ])
  |> CandlestickChart.add_series("AAPL", [
    [243.0, 248.5, 240.1, 250.3],
    [248.5, 252.0, 246.2, 254.7],
    [252.0, 245.8, 243.5, 253.0],
    [245.8, 249.2, 244.0, 251.5],
    [249.2, 256.3, 248.0, 258.1],
    [256.3, 261.0, 254.5, 263.8],
    [261.0, 258.4, 255.2, 262.5],
    [258.4, 264.7, 257.0, 266.3],
    [264.7, 260.1, 258.3, 266.0],
    [260.1, 268.5, 259.0, 270.2],
    [268.5, 272.3, 266.8, 275.0],
    [272.3, 270.8, 268.5, 274.1]
  ])
  |> ChartsEx.render()
```

### Heatmap Chart

Color-coded grid with gradient:

```elixir
alias ChartsEx.HeatmapChart

{:ok, svg} =
  HeatmapChart.new()
  |> HeatmapChart.title("Deploy Frequency by Day and Hour")
  |> HeatmapChart.theme(:grafana)
  |> HeatmapChart.width(700)
  |> HeatmapChart.height(340)
  |> HeatmapChart.x_axis(["Mon", "Tue", "Wed", "Thu", "Fri"])
  |> HeatmapChart.y_axis(["9 AM", "11 AM", "1 PM", "3 PM", "5 PM"])
  |> HeatmapChart.series(%{
    data: [
      # [x_index, y_index, value]
      [0, 0, 3],  [0, 1, 5],  [0, 2, 8],  [0, 3, 12], [0, 4, 4],
      [1, 0, 7],  [1, 1, 11], [1, 2, 15], [1, 3, 9],  [1, 4, 2],
      [2, 0, 10], [2, 1, 18], [2, 2, 22], [2, 3, 14], [2, 4, 6],
      [3, 0, 5],  [3, 1, 8],  [3, 2, 19], [3, 3, 16], [3, 4, 7],
      [4, 0, 2],  [4, 1, 6],  [4, 2, 13], [4, 3, 10], [4, 4, 1]
    ],
    min: 0,
    max: 25,
    min_color: "#E0F3F8",
    max_color: "#0B3D91"
  })
  |> ChartsEx.render()
```

### Table Chart

SVG-rendered data table with styled headers and alternating rows:

```elixir
alias ChartsEx.TableChart

{:ok, svg} =
  TableChart.new()
  |> TableChart.title("Q1 2025 — SaaS Metrics")
  |> TableChart.theme(:light)
  |> TableChart.width(680)
  |> TableChart.height(300)
  |> TableChart.data([
    ["Metric", "January", "February", "March", "Trend"],
    ["MRR", "$142,300", "$148,900", "$156,200", "+9.8%"],
    ["Churn Rate", "2.1%", "1.8%", "1.6%", "-0.5pp"],
    ["New Customers", "87", "104", "119", "+36.8%"],
    ["NPS Score", "62", "65", "71", "+9pts"],
    ["Avg. Deal Size", "$4,280", "$4,510", "$4,750", "+11.0%"]
  ])
  |> TableChart.spans([2.0, 1.0, 1.0, 1.0, 1.0])
  |> TableChart.text_aligns([:left, :right, :right, :right, :right])
  |> TableChart.header_background_color("#4A5568")
  |> TableChart.header_font_color("#FFFFFF")
  |> TableChart.body_background_colors(["#F7FAFC", "#EDF2F7"])
  |> TableChart.border_color("#CBD5E0")
  |> TableChart.cell_styles([
    %{indexes: [4], font_color: "#38A169"}
  ])
  |> ChartsEx.render()
```

### Multi Chart

Combine a bar chart and a line chart into one SVG:

```elixir
alias ChartsEx.{BarChart, LineChart, MultiChart}

bar =
  BarChart.new()
  |> BarChart.title("Monthly Revenue ($k)")
  |> BarChart.theme(:ant)
  |> BarChart.width(600)
  |> BarChart.height(300)
  |> BarChart.x_axis(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> BarChart.add_series("Product A", [42.0, 48.0, 53.0, 51.0, 60.0, 68.0])
  |> BarChart.add_series("Product B", [28.0, 32.0, 35.0, 41.0, 38.0, 45.0])

line =
  LineChart.new()
  |> LineChart.title("Cumulative Growth (%)")
  |> LineChart.theme(:ant)
  |> LineChart.width(600)
  |> LineChart.height(300)
  |> LineChart.smooth(true)
  |> LineChart.x_axis(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> LineChart.add_series("Growth", [0.0, 14.3, 25.7, 31.4, 40.0, 61.4])

{:ok, svg} =
  MultiChart.new()
  |> MultiChart.add_chart(bar)
  |> MultiChart.add_chart(line)
  |> MultiChart.gap(20.0)
  |> MultiChart.margin(%{left: 10, top: 10, right: 10, bottom: 10})
  |> ChartsEx.render()
```

## Themes

ChartsEx ships with 9 built-in themes. Pass any of them to the `.theme/2` function:

| Theme | Description |
|-------|-------------|
| `:light` | Clean white background with soft colors. Default theme. |
| `:dark` | Dark gray background with bright, high-contrast series colors. |
| `:grafana` | Monitoring-dashboard aesthetic -- dark background with greens and oranges. |
| `:ant` | Ant Design-inspired palette with blues and teals on a white background. |
| `:vintage` | Muted, warm tones (burgundy, olive, tan) with a parchment feel. |
| `:walden` | Nature-inspired soft blues and greens, light background. |
| `:westeros` | Subdued earth tones with a medieval cartography vibe. |
| `:chalk` | Bold neon colors on a dark background, chalkboard style. |
| `:shine` | Vibrant, high-saturation gradients on a dark background. |

```elixir
# List all themes programmatically
ChartsEx.Theme.list()
# => [:light, :dark, :grafana, :ant, :vintage, :walden, :westeros, :chalk, :shine]

# Apply a theme
BarChart.new() |> BarChart.theme(:chalk)
```

## Customization

Every chart supports fine-grained control over colors, fonts, margins, legends, and axes. Here is a "fully loaded" example showing many options at once:

```elixir
alias ChartsEx.BarChart

{:ok, svg} =
  BarChart.new()
  # Title
  |> BarChart.title("Engineering Headcount by Department")
  |> BarChart.sub_title("Updated March 2025")
  # Dimensions
  |> BarChart.width(750)
  |> BarChart.height(450)
  # Theme as a starting point, then override individual settings
  |> BarChart.theme(:light)
  |> BarChart.background_color("#FAFAFA")
  # Custom series palette
  |> BarChart.series_colors(["#6366F1", "#F59E0B", "#10B981"])
  # Legend
  |> BarChart.legend_align(:right)
  |> BarChart.legend_margin(%{top: 5, bottom: 15, left: 0, right: 0})
  # Margins
  |> BarChart.margin(%{left: 15, top: 20, right: 15, bottom: 15})
  # Corner radius on bars
  |> BarChart.radius(3.0)
  # Dual y-axis config
  |> BarChart.y_axis_configs([
    %{axis_font_size: 12, axis_font_color: "#333333"},
    %{axis_font_size: 12, axis_font_color: "#999999"}
  ])
  # X-axis categories
  |> BarChart.x_axis(["Platform", "Backend", "Frontend", "Data", "DevOps", "Security"])
  # Bar series
  |> BarChart.add_series("Full-Time", [24.0, 38.0, 31.0, 18.0, 12.0, 9.0],
    label_show: true,
    mark_lines: [%{category: "average"}]
  )
  |> BarChart.add_series("Contractors", [6.0, 12.0, 8.0, 5.0, 3.0, 2.0])
  # Line overlay for growth rate
  |> BarChart.add_series("YoY Growth %", [15.0, 22.0, 18.0, 30.0, 25.0, 40.0],
    category: "line",
    y_axis_index: 1,
    stroke_dash_array: "5,3",
    mark_points: [%{category: "max"}]
  )
  |> ChartsEx.render()
```

### Summary of shared builder functions

Most chart types support these common setters:

| Function | Purpose |
|----------|---------|
| `title/2` | Chart title text |
| `sub_title/2` | Subtitle below the title |
| `theme/2` | Apply a built-in theme |
| `width/2`, `height/2` | Chart dimensions in pixels |
| `margin/2` | Outer margin as `%{left: _, top: _, right: _, bottom: _}` |
| `background_color/2` | Background fill color (hex string) |
| `series_colors/2` | Series palette as a list of hex strings |
| `legend_align/2` | Legend position: `:left`, `:center`, or `:right` |
| `legend_margin/2` | Legend margin map |
| `x_axis/2` | X-axis category labels |
| `y_axis_configs/2` | Y-axis configuration list (supports dual axes) |
| `add_series/3,4` | Add a named data series with optional keyword opts |

## Three Input Modes

ChartsEx accepts chart definitions in three formats. All three produce identical SVG output.

### 1. Builder structs (recommended)

The builder API is the idiomatic way to construct charts. Each chart type has its own module with dedicated setter functions:

```elixir
alias ChartsEx.LineChart

{:ok, svg} =
  LineChart.new()
  |> LineChart.title("Monthly Active Users")
  |> LineChart.theme(:grafana)
  |> LineChart.width(650)
  |> LineChart.height(380)
  |> LineChart.smooth(true)
  |> LineChart.x_axis(["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
  |> LineChart.add_series("MAU (thousands)", [124.0, 131.0, 148.0, 162.0, 155.0, 178.0])
  |> ChartsEx.render()
```

### 2. Atom-key maps

Pass a plain Elixir map with atom keys. Use the `:type` key to specify the chart type. This is useful when chart configurations come from a database or config file:

```elixir
{:ok, svg} =
  ChartsEx.render(%{
    type: :line,
    title_text: "Monthly Active Users",
    theme: "grafana",
    width: 650,
    height: 380,
    series_smooth: true,
    x_axis_data: ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    series_list: [
      %{name: "MAU (thousands)", data: [124.0, 131.0, 148.0, 162.0, 155.0, 178.0]}
    ]
  })
```

Supported `:type` values: `:bar`, `:horizontal_bar`, `:line`, `:pie`, `:radar`, `:scatter`, `:candlestick`, `:heatmap`, `:table`, `:multi_chart`.

### 3. Raw JSON

Pass a JSON string directly. This is handy if you receive chart configs from an API or store them as JSON blobs:

```elixir
json = ~s({
  "type": "line",
  "title_text": "Monthly Active Users",
  "theme": "grafana",
  "width": 650,
  "height": 380,
  "series_smooth": true,
  "x_axis_data": ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
  "series_list": [
    {"name": "MAU (thousands)", "data": [124.0, 131.0, 148.0, 162.0, 155.0, 178.0]}
  ]
})

{:ok, svg} = ChartsEx.render(json)
```

## Phoenix / LiveView

### Component usage

ChartsEx ships with a Phoenix function component that renders charts as inline SVG inside a wrapping `<div>`:

```heex
<ChartsEx.Component.chart config={@chart} class="mx-auto max-w-2xl" id="sales-chart" />
```

The `config` attribute accepts any of the three input modes (struct, map, or JSON string).

### Manual rendering

If you prefer to render the SVG yourself:

```heex
{raw(ChartsEx.render!(@chart))}
```

### Full LiveView example

A chart that updates dynamically when assigns change:

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  alias ChartsEx.BarChart

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5_000, self(), :refresh)

    {:ok, assign(socket, chart: build_chart(fetch_metrics()))}
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, assign(socket, chart: build_chart(fetch_metrics()))}
  end

  defp build_chart({labels, values}) do
    BarChart.new()
    |> BarChart.title("Live Request Volume")
    |> BarChart.theme(:grafana)
    |> BarChart.width(620)
    |> BarChart.height(380)
    |> BarChart.x_axis(labels)
    |> BarChart.add_series("Requests/min", values)
    |> BarChart.series_colors(["#73C0DE"])
  end

  defp fetch_metrics do
    # Replace with your actual data source
    labels = ["API", "Web", "WebSocket", "Webhook", "Cron"]
    values = Enum.map(labels, fn _ -> :rand.uniform(500) * 1.0 end)
    {labels, values}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-4">System Dashboard</h1>
      <ChartsEx.Component.chart config={@chart} class="mx-auto max-w-3xl" id="req-volume" />
    </div>
    """
  end
end
```

## Raster Output

ChartsEx produces SVG strings. To convert to PNG, JPEG, or other raster formats, use [Vix](https://hex.pm/packages/vix) (libvips bindings for Elixir):

```elixir
# Add to mix.exs: {:vix, "~> 0.30"}

alias ChartsEx.BarChart

{:ok, svg} =
  BarChart.new()
  |> BarChart.title("Export Example")
  |> BarChart.x_axis(["A", "B", "C"])
  |> BarChart.add_series("Values", [10.0, 20.0, 15.0])
  |> ChartsEx.render()

# SVG -> PNG
{:ok, {image, _flags}} = Vix.Vips.Operation.svgload_buffer(svg)
:ok = Vix.Vips.Image.write_to_file(image, "chart.png")

# SVG -> JPEG (with quality setting)
:ok = Vix.Vips.Image.write_to_file(image, "chart.jpg[Q=90]")
```

## Building from Source

By default, ChartsEx uses precompiled NIF binaries (via `rustler_precompiled`) so you do not need Rust installed. To compile the Rust NIF locally instead:

```bash
export CHARTS_EX_BUILD=true
mix deps.compile charts_ex --force
```

Requirements:
- Rust 1.70+
- A C linker (usually already available on macOS and Linux)

Supported targets: `aarch64-apple-darwin`, `aarch64-unknown-linux-gnu`, `x86_64-apple-darwin`, `x86_64-unknown-linux-gnu`, `x86_64-unknown-linux-musl`.

## License

MIT
