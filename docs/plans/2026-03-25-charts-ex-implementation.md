# charts_ex Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a release-quality Elixir NIF wrapper for charts-rs with typed builder API, all 10 chart types, Phoenix component, and precompiled binaries.

**Architecture:** Elixir structs with builder functions serialize to JSON via a shared Serializer, then pass through a single Rustler NIF that dispatches to charts-rs `from_json()` → `svg()`. Three input modes: builder structs, atom-key maps, raw JSON.

**Tech Stack:** Elixir 1.15+, Rustler 0.37, rustler_precompiled 0.8, charts-rs 0.3, Jason 1.4

**Reference:** Design doc at `docs/plans/2026-03-25-charts-ex-design.md`

---

### Task 1: Scaffold Mix Project

**Files:**
- Create: `mix.exs`
- Create: `.formatter.exs`
- Create: `.gitignore`
- Create: `lib/charts_ex.ex`

**Step 1: Initialize project files**

Create `mix.exs`:

```elixir
defmodule ChartsEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/TODO/charts_ex"

  def project do
    [
      app: :charts_ex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "ChartsEx",
      description: "SVG chart rendering for Elixir powered by charts-rs",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:rustler, "~> 0.37", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "native/charts_ex/src",
        "native/charts_ex/Cargo*",
        "native/charts_ex/Cross.toml",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "ChartsEx",
      extras: ["README.md"]
    ]
  end
end
```

Create `.formatter.exs`:

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

Create `.gitignore`:

```
/_build/
/cover/
/deps/
/doc/
/.fetch
erl_crash.dump
*.ez
charts_ex-*.tar
/tmp/
native/charts_ex/target/
```

Create a placeholder `lib/charts_ex.ex`:

```elixir
defmodule ChartsEx do
  @moduledoc """
  SVG chart rendering for Elixir powered by charts-rs.
  """
end
```

**Step 2: Install dependencies**

Run: `mix deps.get`
Expected: Dependencies fetched successfully.

**Step 3: Verify compilation**

Run: `mix compile`
Expected: Compiles without errors.

**Step 4: Commit**

```bash
git init
git add mix.exs .formatter.exs .gitignore lib/charts_ex.ex
git commit -m "feat: scaffold charts_ex Mix project"
```

---

### Task 2: Set Up Rust NIF Crate

**Files:**
- Create: `native/charts_ex/Cargo.toml`
- Create: `native/charts_ex/src/lib.rs`
- Create: `native/charts_ex/Cross.toml`

**Step 1: Create Cargo.toml**

```toml
[package]
name = "charts_ex"
version = "0.1.0"
edition = "2021"

[lib]
name = "charts_ex"
path = "src/lib.rs"
crate-type = ["cdylib"]

[dependencies]
charts-rs = { version = "0.3", default-features = false }
rustler = { version = "0.37", default-features = false, features = ["derive"] }
serde_json = "1"

[features]
default = ["nif_version_2_15"]
nif_version_2_15 = ["rustler/nif_version_2_15"]
nif_version_2_16 = ["rustler/nif_version_2_16"]
nif_version_2_17 = ["rustler/nif_version_2_17"]
```

**Step 2: Create the NIF source**

```rust
use charts_rs::{
    BarChart, CandlestickChart, HeatmapChart, HorizontalBarChart, LineChart, MultiChart,
    PieChart, RadarChart, ScatterChart, TableChart,
};
use rustler::{Encoder, Env, NifResult, Term};

rustler::init!("Elixir.ChartsEx.Native");

mod atoms {
    rustler::atoms! { ok, error }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn render<'a>(env: Env<'a>, json: &str) -> NifResult<Term<'a>> {
    let value: serde_json::Value = match serde_json::from_str(json) {
        Ok(v) => v,
        Err(e) => return Ok((atoms::error(), format!("invalid JSON: {e}")).encode(env)),
    };

    let chart_type = match value.get("type").and_then(|v| v.as_str()) {
        Some(t) => t,
        None => {
            return Ok((atoms::error(), "missing \"type\" field".to_string()).encode(env))
        }
    };

    let result = match chart_type {
        "bar" => BarChart::from_json(json).and_then(|c| c.svg()),
        "horizontal_bar" => HorizontalBarChart::from_json(json).and_then(|c| c.svg()),
        "line" => LineChart::from_json(json).and_then(|c| c.svg()),
        "pie" => PieChart::from_json(json).and_then(|c| c.svg()),
        "radar" => RadarChart::from_json(json).and_then(|c| c.svg()),
        "scatter" => ScatterChart::from_json(json).and_then(|c| c.svg()),
        "candlestick" => CandlestickChart::from_json(json).and_then(|c| c.svg()),
        "heatmap" => HeatmapChart::from_json(json).and_then(|c| c.svg()),
        "table" => TableChart::from_json(json).and_then(|c| c.svg()),
        "multi_chart" => MultiChart::from_json(json).and_then(|c| c.svg()),
        _ => {
            return Ok((
                atoms::error(),
                format!("unknown chart type: {chart_type}"),
            )
                .encode(env))
        }
    };

    match result {
        Ok(svg) => Ok((atoms::ok(), svg).encode(env)),
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env)),
    }
}
```

**Step 3: Create Cross.toml**

```toml
[build.env]
passthrough = [
  "RUSTLER_NIF_VERSION"
]
```

**Step 4: Verify Rust compilation**

Run: `cd native/charts_ex && cargo build && cd ../..`
Expected: Compiles successfully (may take a while on first build for charts-rs dependencies).

**Step 5: Commit**

```bash
git add native/
git commit -m "feat: add Rust NIF crate with charts-rs dispatch"
```

---

### Task 3: Create Native Elixir Module

**Files:**
- Create: `lib/charts_ex/native.ex`

**Step 1: Write the failing test**

Create `test/test_helper.exs`:

```elixir
ExUnit.start()
```

Create `test/native_test.exs`:

```elixir
defmodule ChartsEx.NativeTest do
  use ExUnit.Case, async: true

  test "renders bar chart from JSON" do
    json = Jason.encode!(%{
      "type" => "bar",
      "width" => 600,
      "height" => 400,
      "title_text" => "Test",
      "series_list" => [%{"name" => "A", "data" => [1.0, 2.0, 3.0]}],
      "x_axis_data" => ["X", "Y", "Z"]
    })

    assert {:ok, svg} = ChartsEx.Native.render(json)
    assert svg =~ "<svg"
  end

  test "returns error for invalid JSON" do
    assert {:error, msg} = ChartsEx.Native.render("not json")
    assert msg =~ "invalid JSON"
  end

  test "returns error for missing type" do
    json = Jason.encode!(%{"width" => 600})
    assert {:error, msg} = ChartsEx.Native.render(json)
    assert msg =~ "type"
  end

  test "returns error for unknown chart type" do
    json = Jason.encode!(%{"type" => "nope"})
    assert {:error, msg} = ChartsEx.Native.render(json)
    assert msg =~ "unknown chart type"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `mix test test/native_test.exs`
Expected: FAIL — module `ChartsEx.Native` not found.

**Step 3: Implement Native module**

Create `lib/charts_ex/native.ex`:

```elixir
defmodule ChartsEx.Native do
  @moduledoc false

  use RustlerPrecompiled,
    otp_app: :charts_ex,
    crate: "charts_ex",
    base_url: "https://github.com/TODO/charts_ex/releases/download/v#{Mix.Project.config()[:version]}",
    force_build: System.get_env("CHARTS_EX_BUILD") in ["1", "true"],
    version: Mix.Project.config()[:version],
    nif_versions: ["2.17", "2.16", "2.15"],
    targets: [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "x86_64-unknown-linux-musl"
    ]

  def render(_json), do: :erlang.nif_error(:nif_not_loaded)
end
```

**Step 4: Build and run tests**

Run: `CHARTS_EX_BUILD=true mix test test/native_test.exs`
Expected: All 4 tests pass. The first build will take a few minutes while charts-rs compiles.

**Step 5: Commit**

```bash
git add lib/charts_ex/native.ex test/
git commit -m "feat: add Rustler Native module with NIF bridge"
```

---

### Task 4: Create Chart Behaviour, Theme, and Serializer

**Files:**
- Create: `lib/charts_ex/chart.ex`
- Create: `lib/charts_ex/theme.ex`
- Create: `lib/charts_ex/serializer.ex`

**Step 1: Write failing tests**

Create `test/theme_test.exs`:

```elixir
defmodule ChartsEx.ThemeTest do
  use ExUnit.Case, async: true

  alias ChartsEx.Theme

  test "list/0 returns all theme atoms" do
    themes = Theme.list()
    assert :light in themes
    assert :dark in themes
    assert :grafana in themes
    assert length(themes) == 9
  end

  test "validate!/1 accepts valid themes" do
    assert Theme.validate!(:dark) == "dark"
    assert Theme.validate!(:grafana) == "grafana"
  end

  test "validate!/1 raises on unknown theme" do
    assert_raise ArgumentError, ~r/unknown theme/, fn ->
      Theme.validate!(:nope)
    end
  end
end
```

Create `test/serializer_test.exs`:

```elixir
defmodule ChartsEx.SerializerTest do
  use ExUnit.Case, async: true

  alias ChartsEx.Serializer

  test "to_json/2 drops nil fields and injects type" do
    struct_map = %{
      __struct__: SomeChart,
      title_text: "Hello",
      width: 600,
      unused: nil
    }

    json = Serializer.to_json(struct_map, "bar")
    decoded = Jason.decode!(json)

    assert decoded["type"] == "bar"
    assert decoded["title_text"] == "Hello"
    assert decoded["width"] == 600
    refute Map.has_key?(decoded, "unused")
    refute Map.has_key?(decoded, "__struct__")
  end

  test "to_json/2 converts atom values to strings" do
    struct_map = %{
      __struct__: SomeChart,
      legend_align: :center,
      legend_category: :round_rect
    }

    json = Serializer.to_json(struct_map, "bar")
    decoded = Jason.decode!(json)

    assert decoded["legend_align"] == "center"
    assert decoded["legend_category"] == "round_rect"
  end

  test "to_json/2 passes through nested maps and lists" do
    struct_map = %{
      __struct__: SomeChart,
      series_list: [%{name: "A", data: [1.0, 2.0]}],
      margin: %{left: 10, top: 5, right: 10, bottom: 5}
    }

    json = Serializer.to_json(struct_map, "line")
    decoded = Jason.decode!(json)

    assert decoded["type"] == "line"
    assert [%{"name" => "A", "data" => [1.0, 2.0]}] = decoded["series_list"]
    assert %{"left" => 10} = decoded["margin"]
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `mix test test/theme_test.exs test/serializer_test.exs`
Expected: FAIL — modules not found.

**Step 3: Implement Chart behaviour**

Create `lib/charts_ex/chart.ex`:

```elixir
defmodule ChartsEx.Chart do
  @moduledoc "Behaviour implemented by all chart type modules."

  @callback to_json(struct()) :: String.t()
end
```

**Step 4: Implement Theme module**

Create `lib/charts_ex/theme.ex`:

```elixir
defmodule ChartsEx.Theme do
  @moduledoc """
  Built-in chart themes from charts-rs.

  Available themes: `:light`, `:dark`, `:grafana`, `:ant`, `:vintage`,
  `:walden`, `:westeros`, `:chalk`, `:shine`.
  """

  @themes ~w(light dark grafana ant vintage walden westeros chalk shine)a

  @doc "Returns the list of available theme atoms."
  @spec list() :: [atom()]
  def list, do: @themes

  @doc """
  Validates a theme name and returns its string representation.

  Raises `ArgumentError` if the theme is not recognized.
  """
  @spec validate!(atom()) :: String.t()
  def validate!(name) when name in @themes, do: Atom.to_string(name)

  def validate!(name) do
    raise ArgumentError,
          "unknown theme #{inspect(name)}, expected one of: #{inspect(@themes)}"
  end
end
```

**Step 5: Implement Serializer module**

Create `lib/charts_ex/serializer.ex`:

```elixir
defmodule ChartsEx.Serializer do
  @moduledoc false

  @doc """
  Converts a chart struct to a JSON string for the NIF.

  Drops nil fields, removes __struct__, injects the "type" key,
  and converts atom values to strings.
  """
  @spec to_json(struct(), String.t()) :: String.t()
  def to_json(chart, type) do
    chart
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {k, encode_value(v)} end)
    |> Map.new()
    |> Map.put(:type, type)
    |> Jason.encode!()
  end

  defp encode_value(v) when is_atom(v), do: Atom.to_string(v)
  defp encode_value(v) when is_list(v), do: Enum.map(v, &encode_value/1)
  defp encode_value(%{__struct__: _} = v), do: v |> Map.from_struct() |> encode_value()

  defp encode_value(v) when is_map(v) do
    v
    |> Enum.reject(fn {_k, val} -> is_nil(val) end)
    |> Enum.map(fn {k, val} -> {k, encode_value(val)} end)
    |> Map.new()
  end

  defp encode_value(v), do: v
end
```

**Step 6: Run tests**

Run: `mix test test/theme_test.exs test/serializer_test.exs`
Expected: All tests pass.

**Step 7: Commit**

```bash
git add lib/charts_ex/chart.ex lib/charts_ex/theme.ex lib/charts_ex/serializer.ex test/theme_test.exs test/serializer_test.exs
git commit -m "feat: add Chart behaviour, Theme validation, and Serializer"
```

---

### Task 5: Implement BarChart Module (Template for All Charts)

**Files:**
- Create: `lib/charts_ex/bar_chart.ex`
- Create: `test/bar_chart_test.exs`

**Step 1: Write the failing test**

Create `test/bar_chart_test.exs`:

```elixir
defmodule ChartsEx.BarChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.BarChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = BarChart.new()
      assert %BarChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        BarChart.new()
        |> BarChart.title("Sales")
        |> BarChart.sub_title("2024 Q1")
        |> BarChart.theme(:dark)
        |> BarChart.width(800)
        |> BarChart.height(500)
        |> BarChart.x_axis(["Jan", "Feb", "Mar"])

      assert chart.title_text == "Sales"
      assert chart.sub_title_text == "2024 Q1"
      assert chart.theme == "dark"
      assert chart.width == 800
      assert chart.height == 500
      assert chart.x_axis_data == ["Jan", "Feb", "Mar"]
    end

    test "add_series/3 appends series" do
      chart =
        BarChart.new()
        |> BarChart.add_series("A", [1.0, 2.0, 3.0])
        |> BarChart.add_series("B", [4.0, 5.0, 6.0])

      assert length(chart.series_list) == 2
      assert Enum.at(chart.series_list, 0).name == "A"
      assert Enum.at(chart.series_list, 1).name == "B"
    end

    test "add_series/4 accepts options" do
      chart =
        BarChart.new()
        |> BarChart.add_series("A", [1.0, 2.0], label_show: true, category: "line")

      series = hd(chart.series_list)
      assert series.label_show == true
      assert series.category == "line"
    end
  end

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        BarChart.new()
        |> BarChart.title("Test")
        |> BarChart.x_axis(["A", "B"])
        |> BarChart.add_series("S1", [1.0, 2.0])

      json = BarChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "bar"
      assert decoded["title_text"] == "Test"
      assert decoded["x_axis_data"] == ["A", "B"]
      assert [%{"name" => "S1", "data" => [1.0, 2.0]}] = decoded["series_list"]
    end

    test "omits nil fields" do
      json = BarChart.new() |> BarChart.title("X") |> BarChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "sub_title_text")
    end
  end

  describe "render integration" do
    test "renders SVG via NIF" do
      assert {:ok, svg} =
               BarChart.new()
               |> BarChart.title("Test Bar Chart")
               |> BarChart.width(600)
               |> BarChart.height(400)
               |> BarChart.x_axis(["Mon", "Tue", "Wed"])
               |> BarChart.add_series("Downloads", [120.0, 200.0, 150.0])
               |> ChartsEx.render()

      assert svg =~ "<svg"
      assert svg =~ "Test Bar Chart"
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `CHARTS_EX_BUILD=true mix test test/bar_chart_test.exs`
Expected: FAIL — module `ChartsEx.BarChart` not found.

**Step 3: Implement BarChart module**

Create `lib/charts_ex/bar_chart.ex`:

```elixir
defmodule ChartsEx.BarChart do
  @moduledoc """
  Vertical bar chart with optional line overlay and dual y-axis support.

  ## Example

      alias ChartsEx.BarChart

      BarChart.new()
      |> BarChart.title("Weekly Downloads")
      |> BarChart.theme(:grafana)
      |> BarChart.x_axis(["Mon", "Tue", "Wed", "Thu", "Fri"])
      |> BarChart.add_series("Hex", [120.0, 200.0, 150.0, 80.0, 70.0])
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
    :series_fill,
    # Bar-specific
    :radius
  ]

  @doc "Creates a new empty bar chart."
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
    * `:category` - override series type: `"line"` or `"bar"`
    * `:y_axis_index` - which y-axis to use (0 or 1)
    * `:mark_lines` - list of mark lines, e.g. `[%{category: "average"}]`
    * `:mark_points` - list of mark points, e.g. `[%{category: "max"}]`
    * `:colors` - per-bar colors as list of hex strings
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

  @doc "Sets the bar corner radius."
  def radius(chart, r), do: %{chart | radius: r}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "bar")
end
```

**Step 4: Implement ChartsEx.render/1 (needed for integration test)**

Update `lib/charts_ex.ex`:

```elixir
defmodule ChartsEx do
  @moduledoc """
  SVG chart rendering for Elixir powered by charts-rs.

  ## Usage

  Three input modes are supported:

  ### Builder structs (recommended)

      alias ChartsEx.BarChart

      BarChart.new()
      |> BarChart.title("Downloads")
      |> BarChart.x_axis(["Mon", "Tue", "Wed"])
      |> BarChart.add_series("Hex", [120.0, 200.0, 150.0])
      |> ChartsEx.render()

  ### Atom-key maps

      ChartsEx.render(%{
        type: :bar,
        title_text: "Downloads",
        series_list: [%{name: "Hex", data: [120.0, 200.0]}],
        x_axis_data: ["Mon", "Tue"]
      })

  ### Raw JSON

      ChartsEx.render(~s({"type": "bar", ...}))

  """

  @type_map %{
    bar: "bar",
    horizontal_bar: "horizontal_bar",
    line: "line",
    pie: "pie",
    radar: "radar",
    scatter: "scatter",
    candlestick: "candlestick",
    heatmap: "heatmap",
    table: "table",
    multi_chart: "multi_chart"
  }

  @doc """
  Renders a chart to SVG.

  Accepts a chart struct, atom-key map with `:type`, or raw JSON string.

  Returns `{:ok, svg_string}` or `{:error, message}`.
  """
  @spec render(struct() | map() | String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def render(%mod{} = chart) do
    chart |> mod.to_json() |> ChartsEx.Native.render()
  end

  def render(map) when is_map(map) do
    map
    |> stringify_map()
    |> Jason.encode!()
    |> ChartsEx.Native.render()
  end

  def render(json) when is_binary(json) do
    ChartsEx.Native.render(json)
  end

  @doc """
  Like `render/1` but raises on error.
  """
  @spec render!(struct() | map() | String.t()) :: String.t()
  def render!(input) do
    case render(input) do
      {:ok, svg} -> svg
      {:error, msg} -> raise RuntimeError, "ChartsEx render error: #{msg}"
    end
  end

  defp stringify_map(map) when is_map(map) do
    Map.new(map, fn
      {:type, v} when is_atom(v) -> {"type", Map.get(@type_map, v, Atom.to_string(v))}
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_value(v)}
      {k, v} -> {k, stringify_value(v)}
    end)
  end

  defp stringify_value(v) when is_map(v), do: stringify_map(v)
  defp stringify_value(v) when is_list(v), do: Enum.map(v, &stringify_value/1)
  defp stringify_value(v) when is_atom(v) and not is_nil(v) and not is_boolean(v), do: Atom.to_string(v)
  defp stringify_value(v), do: v
end
```

**Step 5: Run all tests**

Run: `CHARTS_EX_BUILD=true mix test`
Expected: All tests pass.

**Step 6: Commit**

```bash
git add lib/charts_ex.ex lib/charts_ex/bar_chart.ex test/bar_chart_test.exs
git commit -m "feat: add BarChart module with builder API and render pipeline"
```

---

### Task 6: Implement LineChart

**Files:**
- Create: `lib/charts_ex/line_chart.ex`
- Create: `test/line_chart_test.exs`

**Step 1: Write the failing test**

Create `test/line_chart_test.exs`:

```elixir
defmodule ChartsEx.LineChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.LineChart

  test "builder API and render" do
    assert {:ok, svg} =
             LineChart.new()
             |> LineChart.title("Temperature")
             |> LineChart.width(600)
             |> LineChart.height(400)
             |> LineChart.x_axis(["Mon", "Tue", "Wed"])
             |> LineChart.add_series("City A", [22.0, 25.0, 28.0])
             |> LineChart.add_series("City B", [18.0, 20.0, 24.0], label_show: true)
             |> ChartsEx.render()

    assert svg =~ "<svg"
    assert svg =~ "Temperature"
  end

  test "smooth and fill options" do
    chart =
      LineChart.new()
      |> LineChart.smooth(true)
      |> LineChart.fill(true)

    assert chart.series_smooth == true
    assert chart.series_fill == true
  end
end
```

**Step 2: Run test to verify it fails**

Run: `CHARTS_EX_BUILD=true mix test test/line_chart_test.exs`
Expected: FAIL.

**Step 3: Implement LineChart**

Create `lib/charts_ex/line_chart.ex`:

```elixir
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
    :y_axis_configs, :y_axis_hidden,
    :grid_stroke_color, :grid_stroke_width,
    :series_list, :series_stroke_width, :series_label_font_color,
    :series_label_font_size, :series_label_font_weight, :series_label_formatter,
    :series_colors, :series_symbol, :series_smooth, :series_fill
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  def margin(chart, m), do: %{chart | margin: m}
  def y_axis_configs(chart, configs), do: %{chart | y_axis_configs: configs}
  def series_colors(chart, colors), do: %{chart | series_colors: colors}
  def background_color(chart, color), do: %{chart | background_color: color}
  def legend_align(chart, align), do: %{chart | legend_align: align}
  def legend_margin(chart, m), do: %{chart | legend_margin: m}

  @doc "Enables smooth curve interpolation."
  def smooth(chart, val \\ true), do: %{chart | series_smooth: val}

  @doc "Enables area fill below the line."
  def fill(chart, val \\ true), do: %{chart | series_fill: val}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "line")
end
```

**Step 4: Run tests**

Run: `CHARTS_EX_BUILD=true mix test test/line_chart_test.exs`
Expected: Pass.

**Step 5: Commit**

```bash
git add lib/charts_ex/line_chart.ex test/line_chart_test.exs
git commit -m "feat: add LineChart module"
```

---

### Task 7: Implement PieChart

**Files:**
- Create: `lib/charts_ex/pie_chart.ex`
- Create: `test/pie_chart_test.exs`

**Step 1: Write test**

Create `test/pie_chart_test.exs`:

```elixir
defmodule ChartsEx.PieChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.PieChart

  test "builder API and render" do
    assert {:ok, svg} =
             PieChart.new()
             |> PieChart.title("Browser Share")
             |> PieChart.width(600)
             |> PieChart.height(400)
             |> PieChart.add_series("Chrome", [60.0])
             |> PieChart.add_series("Firefox", [25.0])
             |> PieChart.add_series("Safari", [15.0])
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end

  test "donut chart with inner_radius" do
    chart =
      PieChart.new()
      |> PieChart.inner_radius(80.0)
      |> PieChart.rose_type(true)
      |> PieChart.border_radius(5.0)

    assert chart.inner_radius == 80.0
    assert chart.rose_type == true
    assert chart.border_radius == 5.0
  end
end
```

**Step 2: Implement PieChart**

Create `lib/charts_ex/pie_chart.ex`:

```elixir
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

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  def margin(chart, m), do: %{chart | margin: m}
  def series_colors(chart, colors), do: %{chart | series_colors: colors}
  def background_color(chart, color), do: %{chart | background_color: color}
  def legend_align(chart, align), do: %{chart | legend_align: align}
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
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/pie_chart_test.exs`
Expected: Pass.

```bash
git add lib/charts_ex/pie_chart.ex test/pie_chart_test.exs
git commit -m "feat: add PieChart module"
```

---

### Task 8: Implement HorizontalBarChart

**Files:**
- Create: `lib/charts_ex/horizontal_bar_chart.ex`
- Create: `test/horizontal_bar_chart_test.exs`

**Step 1: Write test**

Create `test/horizontal_bar_chart_test.exs`:

```elixir
defmodule ChartsEx.HorizontalBarChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.HorizontalBarChart

  test "builder API and render" do
    assert {:ok, svg} =
             HorizontalBarChart.new()
             |> HorizontalBarChart.title("Ranking")
             |> HorizontalBarChart.width(600)
             |> HorizontalBarChart.height(400)
             |> HorizontalBarChart.x_axis(["Go", "Rust", "Elixir"])
             |> HorizontalBarChart.add_series("Stars", [5000.0, 8000.0, 3000.0])
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/horizontal_bar_chart.ex`:

```elixir
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

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  def margin(chart, m), do: %{chart | margin: m}
  def y_axis_configs(chart, configs), do: %{chart | y_axis_configs: configs}
  def series_colors(chart, colors), do: %{chart | series_colors: colors}
  def background_color(chart, color), do: %{chart | background_color: color}
  def legend_align(chart, align), do: %{chart | legend_align: align}

  @doc "Sets label position. One of `:inside`, `:top`, `:right`, `:bottom`, `:left`."
  def label_position(chart, pos), do: %{chart | series_label_position: pos}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "horizontal_bar")
end
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/horizontal_bar_chart_test.exs`

```bash
git add lib/charts_ex/horizontal_bar_chart.ex test/horizontal_bar_chart_test.exs
git commit -m "feat: add HorizontalBarChart module"
```

---

### Task 9: Implement RadarChart

**Files:**
- Create: `lib/charts_ex/radar_chart.ex`
- Create: `test/radar_chart_test.exs`

**Step 1: Write test**

Create `test/radar_chart_test.exs`:

```elixir
defmodule ChartsEx.RadarChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.RadarChart

  test "builder API and render" do
    assert {:ok, svg} =
             RadarChart.new()
             |> RadarChart.title("Skills")
             |> RadarChart.width(600)
             |> RadarChart.height(400)
             |> RadarChart.indicators([
               %{name: "Elixir", max: 100.0},
               %{name: "Rust", max: 100.0},
               %{name: "Go", max: 100.0}
             ])
             |> RadarChart.add_series("Dev A", [90.0, 70.0, 60.0])
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/radar_chart.ex`:

```elixir
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
    :title_text, :title_font_size, :title_font_color, :title_font_weight,
    :title_margin, :title_align, :title_height,
    :sub_title_text, :sub_title_font_size, :sub_title_font_color,
    :sub_title_font_weight, :sub_title_margin, :sub_title_align, :sub_title_height,
    :width, :height, :margin, :font_family, :background_color, :theme,
    :legend_font_size, :legend_font_color, :legend_font_weight,
    :legend_align, :legend_margin, :legend_category, :legend_show,
    :x_axis_data, :x_axis_font_size, :x_axis_font_color,
    :y_axis_configs,
    :grid_stroke_color, :grid_stroke_width,
    :series_list, :series_stroke_width, :series_label_font_color,
    :series_label_font_size, :series_label_font_weight, :series_label_formatter,
    :series_colors, :series_symbol, :series_smooth, :series_fill,
    # Radar-specific
    :indicators
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  def margin(chart, m), do: %{chart | margin: m}
  def series_colors(chart, colors), do: %{chart | series_colors: colors}
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets radar indicators. Each is `%{name: \"Label\", max: 100.0}`."
  def indicators(chart, indicators) when is_list(indicators),
    do: %{chart | indicators: indicators}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "radar")
end
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/radar_chart_test.exs`

```bash
git add lib/charts_ex/radar_chart.ex test/radar_chart_test.exs
git commit -m "feat: add RadarChart module"
```

---

### Task 10: Implement ScatterChart

**Files:**
- Create: `lib/charts_ex/scatter_chart.ex`
- Create: `test/scatter_chart_test.exs`

**Step 1: Write test**

Create `test/scatter_chart_test.exs`:

```elixir
defmodule ChartsEx.ScatterChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.ScatterChart

  test "builder API and render" do
    assert {:ok, svg} =
             ScatterChart.new()
             |> ScatterChart.title("Height vs Weight")
             |> ScatterChart.width(600)
             |> ScatterChart.height(400)
             |> ScatterChart.add_series("Group A", [
               [161.2, 51.6], [167.5, 59.0], [159.5, 49.2]
             ])
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end

  test "symbol sizes" do
    chart = ScatterChart.new() |> ScatterChart.symbol_sizes([5.0, 10.0])
    assert chart.series_symbol_sizes == [5.0, 10.0]
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/scatter_chart.ex`:

```elixir
defmodule ChartsEx.ScatterChart do
  @moduledoc """
  Scatter plot for X/Y coordinate data.

  ## Example

      ScatterChart.new()
      |> ScatterChart.title("Correlation")
      |> ScatterChart.add_series("Sample", [[1.0, 2.0], [3.0, 4.0], [5.0, 3.0]])
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
    :x_axis_name_gap, :x_axis_name_rotate, :x_axis_margin,
    :x_axis_hidden, :x_axis_config, :x_boundary_gap,
    :y_axis_configs, :y_axis_hidden,
    :grid_stroke_color, :grid_stroke_width,
    :series_list, :series_stroke_width, :series_label_font_color,
    :series_label_font_size, :series_label_font_weight, :series_label_formatter,
    :series_colors, :series_symbol, :series_smooth, :series_fill,
    # Scatter-specific
    :series_symbol_sizes
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  def margin(chart, m), do: %{chart | margin: m}
  def y_axis_configs(chart, configs), do: %{chart | y_axis_configs: configs}
  def series_colors(chart, colors), do: %{chart | series_colors: colors}
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets symbol sizes per series as a list of floats."
  def symbol_sizes(chart, sizes) when is_list(sizes),
    do: %{chart | series_symbol_sizes: sizes}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "scatter")
end
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/scatter_chart_test.exs`

```bash
git add lib/charts_ex/scatter_chart.ex test/scatter_chart_test.exs
git commit -m "feat: add ScatterChart module"
```

---

### Task 11: Implement CandlestickChart

**Files:**
- Create: `lib/charts_ex/candlestick_chart.ex`
- Create: `test/candlestick_chart_test.exs`

**Step 1: Write test**

Create `test/candlestick_chart_test.exs`:

```elixir
defmodule ChartsEx.CandlestickChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.CandlestickChart

  test "builder API and render" do
    assert {:ok, svg} =
             CandlestickChart.new()
             |> CandlestickChart.title("Stock Price")
             |> CandlestickChart.width(800)
             |> CandlestickChart.height(500)
             |> CandlestickChart.x_axis(["2024-01", "2024-02", "2024-03"])
             |> CandlestickChart.add_series("AAPL", [
               [20.0, 34.0, 10.0, 38.0],
               [40.0, 35.0, 30.0, 50.0],
               [31.0, 38.0, 33.0, 44.0]
             ])
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end

  test "custom candle colors" do
    chart =
      CandlestickChart.new()
      |> CandlestickChart.up_color("#26A69A")
      |> CandlestickChart.down_color("#EF5350")

    assert chart.candlestick_up_color == "#26A69A"
    assert chart.candlestick_down_color == "#EF5350"
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/candlestick_chart.ex`:

```elixir
defmodule ChartsEx.CandlestickChart do
  @moduledoc """
  Candlestick (OHLC) chart for financial data.

  Each data point is `[open, close, low, high]`.

  ## Example

      CandlestickChart.new()
      |> CandlestickChart.title("AAPL")
      |> CandlestickChart.x_axis(["Jan", "Feb", "Mar"])
      |> CandlestickChart.add_series("Price", [
        [20.0, 34.0, 10.0, 38.0],
        [40.0, 35.0, 30.0, 50.0],
        [31.0, 38.0, 33.0, 44.0]
      ])
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
    :x_axis_name_gap, :x_axis_name_rotate, :x_axis_margin,
    :x_axis_hidden, :x_boundary_gap,
    :y_axis_configs, :y_axis_hidden,
    :grid_stroke_color, :grid_stroke_width,
    :series_list, :series_stroke_width, :series_label_font_color,
    :series_label_font_size, :series_label_font_weight, :series_label_formatter,
    :series_colors, :series_symbol, :series_smooth, :series_fill,
    # Candlestick-specific
    :candlestick_up_color, :candlestick_up_border_color,
    :candlestick_down_color, :candlestick_down_border_color
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}

  def add_series(chart, name, data, opts \\ []) do
    series = %{name: name, data: data} |> Map.merge(Map.new(opts))
    %{chart | series_list: (chart.series_list || []) ++ [series]}
  end

  def margin(chart, m), do: %{chart | margin: m}
  def series_colors(chart, colors), do: %{chart | series_colors: colors}
  def background_color(chart, color), do: %{chart | background_color: color}

  @doc "Sets the color for up (bullish) candles."
  def up_color(chart, color), do: %{chart | candlestick_up_color: color}

  @doc "Sets the border color for up candles."
  def up_border_color(chart, color), do: %{chart | candlestick_up_border_color: color}

  @doc "Sets the color for down (bearish) candles."
  def down_color(chart, color), do: %{chart | candlestick_down_color: color}

  @doc "Sets the border color for down candles."
  def down_border_color(chart, color), do: %{chart | candlestick_down_border_color: color}

  @impl ChartsEx.Chart
  def to_json(chart), do: ChartsEx.Serializer.to_json(chart, "candlestick")
end
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/candlestick_chart_test.exs`

```bash
git add lib/charts_ex/candlestick_chart.ex test/candlestick_chart_test.exs
git commit -m "feat: add CandlestickChart module"
```

---

### Task 12: Implement HeatmapChart

**Files:**
- Create: `lib/charts_ex/heatmap_chart.ex`
- Create: `test/heatmap_chart_test.exs`

**Step 1: Write test**

Create `test/heatmap_chart_test.exs`:

```elixir
defmodule ChartsEx.HeatmapChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.HeatmapChart

  test "builder API and render" do
    assert {:ok, svg} =
             HeatmapChart.new()
             |> HeatmapChart.title("Heatmap")
             |> HeatmapChart.width(600)
             |> HeatmapChart.height(400)
             |> HeatmapChart.x_axis(["Mon", "Tue", "Wed"])
             |> HeatmapChart.y_axis(["Morning", "Afternoon"])
             |> HeatmapChart.series(%{
               data: [
                 [0, 0, 5], [0, 1, 10], [1, 0, 15],
                 [1, 1, 20], [2, 0, 25], [2, 1, 30]
               ],
               min: 0,
               max: 30,
               min_color: "#C6E48B",
               max_color: "#196127"
             })
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/heatmap_chart.ex`:

```elixir
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
    :title_text, :title_font_size, :title_font_color, :title_font_weight,
    :title_margin, :title_align, :title_height,
    :sub_title_text, :sub_title_font_size, :sub_title_font_color,
    :sub_title_font_weight, :sub_title_margin, :sub_title_align, :sub_title_height,
    :width, :height, :margin, :font_family, :background_color, :theme,
    :legend_font_size, :legend_font_color, :legend_font_weight,
    :legend_align, :legend_margin, :legend_category, :legend_show,
    :x_axis_data, :x_axis_height, :x_axis_stroke_color,
    :x_axis_font_size, :x_axis_font_color, :x_axis_font_weight,
    :x_axis_name_gap, :x_axis_name_rotate, :x_axis_margin, :x_axis_hidden,
    :series_list, :series_label_font_color, :series_label_font_size,
    :series_label_font_weight, :series_label_formatter, :series_colors,
    # Heatmap-specific
    :series, :y_axis_data
  ]

  def new, do: %__MODULE__{}
  def title(chart, text), do: %{chart | title_text: text}
  def sub_title(chart, text), do: %{chart | sub_title_text: text}
  def theme(chart, name), do: %{chart | theme: ChartsEx.Theme.validate!(name)}
  def width(chart, w), do: %{chart | width: w}
  def height(chart, h), do: %{chart | height: h}
  def x_axis(chart, labels), do: %{chart | x_axis_data: labels}
  def margin(chart, m), do: %{chart | margin: m}
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
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/heatmap_chart_test.exs`

```bash
git add lib/charts_ex/heatmap_chart.ex test/heatmap_chart_test.exs
git commit -m "feat: add HeatmapChart module"
```

---

### Task 13: Implement TableChart

**Files:**
- Create: `lib/charts_ex/table_chart.ex`
- Create: `test/table_chart_test.exs`

**Step 1: Write test**

Create `test/table_chart_test.exs`:

```elixir
defmodule ChartsEx.TableChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.TableChart

  test "builder API and render" do
    assert {:ok, svg} =
             TableChart.new()
             |> TableChart.title("Sales Data")
             |> TableChart.width(600)
             |> TableChart.height(300)
             |> TableChart.data([
               ["Name", "Q1", "Q2", "Q3"],
               ["Alice", "120", "150", "180"],
               ["Bob", "90", "110", "130"]
             ])
             |> TableChart.spans([2.0, 1.0, 1.0, 1.0])
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/table_chart.ex`:

```elixir
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
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/table_chart_test.exs`

```bash
git add lib/charts_ex/table_chart.ex test/table_chart_test.exs
git commit -m "feat: add TableChart module"
```

---

### Task 14: Implement MultiChart

**Files:**
- Create: `lib/charts_ex/multi_chart.ex`
- Create: `test/multi_chart_test.exs`

**Step 1: Write test**

Create `test/multi_chart_test.exs`:

```elixir
defmodule ChartsEx.MultiChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.{MultiChart, BarChart, LineChart}

  test "builder API and render" do
    bar =
      BarChart.new()
      |> BarChart.title("Bar")
      |> BarChart.width(300)
      |> BarChart.height(200)
      |> BarChart.x_axis(["A", "B"])
      |> BarChart.add_series("S1", [10.0, 20.0])

    line =
      LineChart.new()
      |> LineChart.title("Line")
      |> LineChart.width(300)
      |> LineChart.height(200)
      |> LineChart.x_axis(["A", "B"])
      |> LineChart.add_series("S2", [15.0, 25.0])

    assert {:ok, svg} =
             MultiChart.new()
             |> MultiChart.add_chart(bar)
             |> MultiChart.add_chart(line)
             |> MultiChart.gap(10.0)
             |> ChartsEx.render()

    assert svg =~ "<svg"
  end
end
```

**Step 2: Implement**

Create `lib/charts_ex/multi_chart.ex`:

```elixir
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
    child_charts: [],
    :gap,
    :margin,
    :background_color
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
        chart_json = if x, do: Map.put(chart_json, "x", x), else: chart_json
        chart_json = if y, do: Map.put(chart_json, "y", y), else: chart_json
        chart_json
      end)

    base =
      %{type: "multi_chart", child_charts: child_charts}
      |> then(fn m -> if multi.gap, do: Map.put(m, :gap, multi.gap), else: m end)
      |> then(fn m -> if multi.margin, do: Map.put(m, :margin, multi.margin), else: m end)
      |> then(fn m ->
        if multi.background_color, do: Map.put(m, :background_color, multi.background_color), else: m
      end)

    Jason.encode!(base)
  end
end
```

**Step 3: Run tests and commit**

Run: `CHARTS_EX_BUILD=true mix test test/multi_chart_test.exs`

```bash
git add lib/charts_ex/multi_chart.ex test/multi_chart_test.exs
git commit -m "feat: add MultiChart module"
```

---

### Task 15: Implement Map and JSON Input Paths

**Files:**
- Create: `test/charts_ex_test.exs`

**Step 1: Write tests**

Create `test/charts_ex_test.exs`:

```elixir
defmodule ChartsExTest do
  use ExUnit.Case, async: true

  describe "render/1 with atom-key map" do
    test "renders bar chart from map" do
      assert {:ok, svg} =
               ChartsEx.render(%{
                 type: :bar,
                 width: 600,
                 height: 400,
                 title_text: "Map Test",
                 series_list: [%{name: "A", data: [1.0, 2.0, 3.0]}],
                 x_axis_data: ["X", "Y", "Z"]
               })

      assert svg =~ "<svg"
      assert svg =~ "Map Test"
    end

    test "renders line chart from map" do
      assert {:ok, svg} =
               ChartsEx.render(%{
                 type: :line,
                 series_list: [%{name: "B", data: [5.0, 10.0]}],
                 x_axis_data: ["A", "B"]
               })

      assert svg =~ "<svg"
    end
  end

  describe "render/1 with raw JSON" do
    test "renders from JSON string" do
      json =
        Jason.encode!(%{
          "type" => "bar",
          "width" => 600,
          "height" => 400,
          "series_list" => [%{"name" => "A", "data" => [1.0, 2.0]}],
          "x_axis_data" => ["X", "Y"]
        })

      assert {:ok, svg} = ChartsEx.render(json)
      assert svg =~ "<svg"
    end
  end

  describe "render!/1" do
    test "returns SVG directly on success" do
      svg =
        ChartsEx.render!(%{
          type: :bar,
          series_list: [%{name: "A", data: [1.0]}],
          x_axis_data: ["X"]
        })

      assert svg =~ "<svg"
    end

    test "raises on error" do
      assert_raise RuntimeError, ~r/render error/, fn ->
        ChartsEx.render!("not json")
      end
    end
  end

  describe "render/1 error handling" do
    test "returns error for invalid input" do
      assert {:error, _} = ChartsEx.render("bad json")
    end

    test "returns error for missing type in map" do
      assert {:error, _} = ChartsEx.render(%{width: 600})
    end
  end
end
```

**Step 2: Run tests**

Run: `CHARTS_EX_BUILD=true mix test test/charts_ex_test.exs`
Expected: All tests pass (ChartsEx.render/1 was already implemented in Task 5).

**Step 3: Commit**

```bash
git add test/charts_ex_test.exs
git commit -m "test: add integration tests for map and JSON input paths"
```

---

### Task 16: Implement Phoenix Component

**Files:**
- Create: `lib/charts_ex/component.ex`
- Create: `test/component_test.exs`

**Step 1: Write test**

Create `test/component_test.exs`:

```elixir
defmodule ChartsEx.ComponentTest do
  use ExUnit.Case, async: true

  # Only run if Phoenix is available
  if Code.ensure_loaded?(Phoenix.Component) do
    import Phoenix.LiveViewTest

    test "chart/1 renders SVG in a div" do
      config =
        ChartsEx.BarChart.new()
        |> ChartsEx.BarChart.title("Component Test")
        |> ChartsEx.BarChart.x_axis(["A", "B"])
        |> ChartsEx.BarChart.add_series("S", [1.0, 2.0])

      assigns = %{config: config, id: "test-chart", class: "w-full"}

      html =
        rendered_to_string(~H"""
        <ChartsEx.Component.chart config={@config} id={@id} class={@class} />
        """)

      assert html =~ "<div"
      assert html =~ ~s(id="test-chart")
      assert html =~ ~s(class="w-full")
      assert html =~ "<svg"
    end
  end
end
```

**Note:** This test requires `phoenix_live_view` as a dev/test dependency. Add to `mix.exs`:

```elixir
{:phoenix_live_view, "~> 1.0", only: [:dev, :test]}
```

**Step 2: Implement**

Create `lib/charts_ex/component.ex`:

```elixir
defmodule ChartsEx.Component do
  @moduledoc """
  Phoenix function component for rendering charts inline.

  ## Usage in LiveView/HEEx templates

      <ChartsEx.Component.chart config={@chart} />
      <ChartsEx.Component.chart config={@chart} class="mx-auto max-w-2xl" id="revenue" />

  The chart is rendered as inline SVG wrapped in a `<div>`.
  """

  if Code.ensure_loaded?(Phoenix.Component) do
    use Phoenix.Component

    @doc """
    Renders a chart as inline SVG.

    ## Attributes

      * `config` (required) — a chart struct, atom-key map, or JSON string
      * `class` — optional CSS class for the wrapping div
      * `id` — optional DOM id for the wrapping div
    """
    attr :config, :any, required: true
    attr :class, :string, default: nil
    attr :id, :string, default: nil

    def chart(assigns) do
      svg = ChartsEx.render!(assigns.config)
      assigns = Phoenix.Component.assign(assigns, :svg, svg)

      ~H"""
      <div id={@id} class={@class}>{raw(@svg)}</div>
      """
    end
  end
end
```

**Step 3: Run tests**

Run: `CHARTS_EX_BUILD=true mix test test/component_test.exs`
Expected: Pass (or skip if Phoenix not available).

**Step 4: Commit**

```bash
git add lib/charts_ex/component.ex test/component_test.exs mix.exs
git commit -m "feat: add Phoenix function component for chart rendering"
```

---

### Task 17: Write README

**Files:**
- Create: `README.md`

**Step 1: Write README**

Create `README.md`:

````markdown
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
````

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with usage examples"
```

---

### Task 18: Add GitHub Actions CI and Release Workflow

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`

**Step 1: Create CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  MIX_ENV: test
  CHARTS_EX_BUILD: true

jobs:
  test:
    name: Test (OTP ${{ matrix.otp }} / Elixir ${{ matrix.elixir }})
    runs-on: ubuntu-latest
    strategy:
      matrix:
        otp: ["26.0", "27.0"]
        elixir: ["1.16.0", "1.17.0"]
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: ${{ matrix.otp }}
          elixir-version: ${{ matrix.elixir }}
      - uses: dtolnay/rust-toolchain@stable
      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
            native/charts_ex/target
          key: ${{ runner.os }}-mix-${{ matrix.otp }}-${{ matrix.elixir }}-${{ hashFiles('mix.lock', 'native/charts_ex/Cargo.lock') }}
      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - run: mix test
      - run: mix format --check-formatted

  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "27.0"
          elixir-version: "1.17.0"
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - run: mix deps.get
      - run: cd native/charts_ex && cargo clippy -- -D warnings
```

**Step 2: Create release workflow for precompiled binaries**

Create `.github/workflows/release.yml`:

```yaml
name: Build precompiled NIFs

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  build_release:
    name: NIF ${{ matrix.nif }} - ${{ matrix.job.target }}
    runs-on: ${{ matrix.job.os }}
    strategy:
      fail-fast: false
      matrix:
        nif: ["2.15", "2.16", "2.17"]
        job:
          - { target: aarch64-apple-darwin, os: macos-14 }
          - { target: x86_64-apple-darwin, os: macos-13 }
          - { target: aarch64-unknown-linux-gnu, os: ubuntu-latest, use-cross: true }
          - { target: x86_64-unknown-linux-gnu, os: ubuntu-latest }
          - { target: x86_64-unknown-linux-musl, os: ubuntu-latest, use-cross: true }
    env:
      CHARTS_EX_BUILD: true
      RUSTLER_NIF_VERSION: ${{ matrix.nif }}
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        if: ${{ !matrix.job.use-cross }}
        with:
          otp-version: "27.0"
          elixir-version: "1.17.0"
      - uses: dtolnay/rust-toolchain@stable
        with:
          targets: ${{ matrix.job.target }}
      - uses: cross-rs/cross-action@v1
        if: ${{ matrix.job.use-cross }}
        with:
          command: ""
      - run: |
          if [ "${{ matrix.job.use-cross }}" = "true" ]; then
            cd native/charts_ex && cross build --release --target=${{ matrix.job.target }}
          else
            cd native/charts_ex && cargo build --release --target=${{ matrix.job.target }}
          fi
      - uses: softprops/action-gh-release@v2
        with:
          files: |
            native/charts_ex/target/${{ matrix.job.target }}/release/libcharts_ex.*
```

**Note:** The release workflow will need refinement based on `rustler_precompiled`'s exact expectations for artifact naming. The `mix rustler_precompiled.download` task handles checksum generation.

**Step 3: Commit**

```bash
git add .github/
git commit -m "ci: add GitHub Actions for CI and precompiled binary releases"
```

---

### Task 19: Full Integration Test Suite

**Files:**
- Create: `test/integration_test.exs`

**Step 1: Write comprehensive integration tests**

Create `test/integration_test.exs`:

```elixir
defmodule ChartsEx.IntegrationTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Integration tests verifying every chart type renders SVG through the full pipeline.
  """

  describe "all chart types render valid SVG" do
    test "bar chart with all options" do
      assert {:ok, svg} =
               ChartsEx.BarChart.new()
               |> ChartsEx.BarChart.title("Full Bar")
               |> ChartsEx.BarChart.sub_title("Subtitle")
               |> ChartsEx.BarChart.theme(:dark)
               |> ChartsEx.BarChart.width(800)
               |> ChartsEx.BarChart.height(500)
               |> ChartsEx.BarChart.x_axis(["A", "B", "C", "D"])
               |> ChartsEx.BarChart.add_series("S1", [10.0, 20.0, 30.0, 40.0], label_show: true)
               |> ChartsEx.BarChart.add_series("S2", [15.0, 25.0, 35.0, 45.0])
               |> ChartsEx.BarChart.margin(%{left: 10, top: 5, right: 10, bottom: 5})
               |> ChartsEx.BarChart.legend_align(:center)
               |> ChartsEx.render()

      assert svg =~ "<svg"
      assert svg =~ "Full Bar"
    end

    test "line chart with smooth and fill" do
      assert {:ok, svg} =
               ChartsEx.LineChart.new()
               |> ChartsEx.LineChart.title("Smooth Line")
               |> ChartsEx.LineChart.x_axis(["1", "2", "3", "4"])
               |> ChartsEx.LineChart.add_series("Temp", [20.0, 22.0, 21.0, 25.0])
               |> ChartsEx.LineChart.smooth(true)
               |> ChartsEx.LineChart.fill(true)
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "pie chart as donut" do
      assert {:ok, svg} =
               ChartsEx.PieChart.new()
               |> ChartsEx.PieChart.title("Donut")
               |> ChartsEx.PieChart.inner_radius(60.0)
               |> ChartsEx.PieChart.add_series("A", [40.0])
               |> ChartsEx.PieChart.add_series("B", [30.0])
               |> ChartsEx.PieChart.add_series("C", [30.0])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "radar chart" do
      assert {:ok, svg} =
               ChartsEx.RadarChart.new()
               |> ChartsEx.RadarChart.title("Radar")
               |> ChartsEx.RadarChart.indicators([
                 %{name: "A", max: 100.0},
                 %{name: "B", max: 100.0},
                 %{name: "C", max: 100.0}
               ])
               |> ChartsEx.RadarChart.add_series("P1", [80.0, 60.0, 90.0])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "scatter chart" do
      assert {:ok, svg} =
               ChartsEx.ScatterChart.new()
               |> ChartsEx.ScatterChart.title("Scatter")
               |> ChartsEx.ScatterChart.add_series("Points", [
                 [10.0, 8.0], [20.0, 15.0], [30.0, 22.0]
               ])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "candlestick chart" do
      assert {:ok, svg} =
               ChartsEx.CandlestickChart.new()
               |> ChartsEx.CandlestickChart.title("OHLC")
               |> ChartsEx.CandlestickChart.x_axis(["Day 1", "Day 2"])
               |> ChartsEx.CandlestickChart.add_series("Stock", [
                 [20.0, 34.0, 10.0, 38.0],
                 [40.0, 35.0, 30.0, 50.0]
               ])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "horizontal bar chart" do
      assert {:ok, svg} =
               ChartsEx.HorizontalBarChart.new()
               |> ChartsEx.HorizontalBarChart.title("Horizontal")
               |> ChartsEx.HorizontalBarChart.x_axis(["Go", "Rust"])
               |> ChartsEx.HorizontalBarChart.add_series("Stars", [5000.0, 8000.0])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "heatmap chart" do
      assert {:ok, svg} =
               ChartsEx.HeatmapChart.new()
               |> ChartsEx.HeatmapChart.title("Heat")
               |> ChartsEx.HeatmapChart.x_axis(["A", "B"])
               |> ChartsEx.HeatmapChart.y_axis(["X", "Y"])
               |> ChartsEx.HeatmapChart.series(%{
                 data: [[0, 0, 5], [0, 1, 10], [1, 0, 15], [1, 1, 20]],
                 min: 0, max: 20,
                 min_color: "#C6E48B", max_color: "#196127"
               })
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "table chart" do
      assert {:ok, svg} =
               ChartsEx.TableChart.new()
               |> ChartsEx.TableChart.title("Table")
               |> ChartsEx.TableChart.data([
                 ["Name", "Score"],
                 ["Alice", "95"],
                 ["Bob", "87"]
               ])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end

    test "multi chart" do
      bar = ChartsEx.BarChart.new()
            |> ChartsEx.BarChart.width(300) |> ChartsEx.BarChart.height(200)
            |> ChartsEx.BarChart.x_axis(["A"]) |> ChartsEx.BarChart.add_series("S", [1.0])

      line = ChartsEx.LineChart.new()
             |> ChartsEx.LineChart.width(300) |> ChartsEx.LineChart.height(200)
             |> ChartsEx.LineChart.x_axis(["A"]) |> ChartsEx.LineChart.add_series("S", [1.0])

      assert {:ok, svg} =
               ChartsEx.MultiChart.new()
               |> ChartsEx.MultiChart.add_chart(bar)
               |> ChartsEx.MultiChart.add_chart(line)
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end
  end

  describe "theme rendering" do
    for theme <- ChartsEx.Theme.list() do
      test "renders with #{theme} theme" do
        assert {:ok, svg} =
                 ChartsEx.BarChart.new()
                 |> ChartsEx.BarChart.theme(unquote(theme))
                 |> ChartsEx.BarChart.x_axis(["A", "B"])
                 |> ChartsEx.BarChart.add_series("S", [1.0, 2.0])
                 |> ChartsEx.render()

        assert svg =~ "<svg"
      end
    end
  end
end
```

**Step 2: Run all tests**

Run: `CHARTS_EX_BUILD=true mix test`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add test/integration_test.exs
git commit -m "test: add comprehensive integration test suite for all chart types and themes"
```

---

## Summary

19 tasks covering:
- **Tasks 1-3:** Project scaffold, Rust NIF, Native module
- **Task 4:** Core infrastructure (behaviour, theme, serializer)
- **Task 5:** BarChart (template for all chart modules) + ChartsEx render pipeline
- **Tasks 6-14:** Remaining 9 chart types
- **Task 15:** Map/JSON input path tests
- **Task 16:** Phoenix component
- **Task 17:** README documentation
- **Task 18:** GitHub Actions CI + release
- **Task 19:** Full integration test suite
