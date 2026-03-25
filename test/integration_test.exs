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
                 [10.0, 8.0],
                 [20.0, 15.0],
                 [30.0, 22.0]
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
                 min: 0,
                 max: 20,
                 min_color: "#C6E48B",
                 max_color: "#196127"
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
      bar =
        ChartsEx.BarChart.new()
        |> ChartsEx.BarChart.width(300)
        |> ChartsEx.BarChart.height(200)
        |> ChartsEx.BarChart.x_axis(["A"])
        |> ChartsEx.BarChart.add_series("S", [1.0])

      line =
        ChartsEx.LineChart.new()
        |> ChartsEx.LineChart.width(300)
        |> ChartsEx.LineChart.height(200)
        |> ChartsEx.LineChart.x_axis(["A"])
        |> ChartsEx.LineChart.add_series("S", [1.0])

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
