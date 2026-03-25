defmodule ChartsEx.HeatmapChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.HeatmapChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = HeatmapChart.new()
      assert %HeatmapChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        HeatmapChart.new()
        |> HeatmapChart.title("Activity")
        |> HeatmapChart.sub_title("2024")
        |> HeatmapChart.theme(:dark)
        |> HeatmapChart.width(600)
        |> HeatmapChart.height(400)
        |> HeatmapChart.x_axis(["Mon", "Tue", "Wed"])
        |> HeatmapChart.y_axis(["Morning", "Afternoon"])

      assert chart.title_text == "Activity"
      assert chart.sub_title_text == "2024"
      assert chart.theme == "dark"
      assert chart.width == 600
      assert chart.height == 400
      assert chart.x_axis_data == ["Mon", "Tue", "Wed"]
      assert chart.y_axis_data == ["Morning", "Afternoon"]
    end

    test "series/2 sets heatmap data" do
      series_data = %{
        data: [[0, 0, 5], [1, 0, 10]],
        min: 0,
        max: 30,
        min_color: "#C6E48B",
        max_color: "#196127"
      }

      chart =
        HeatmapChart.new()
        |> HeatmapChart.series(series_data)

      assert chart.series == series_data
      assert chart.series.data == [[0, 0, 5], [1, 0, 10]]
      assert chart.series.min == 0
      assert chart.series.max == 30
      assert chart.series.min_color == "#C6E48B"
      assert chart.series.max_color == "#196127"
    end
  end

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        HeatmapChart.new()
        |> HeatmapChart.title("Test")
        |> HeatmapChart.x_axis(["A", "B"])
        |> HeatmapChart.y_axis(["X", "Y"])
        |> HeatmapChart.series(%{
          data: [[0, 0, 5]],
          min: 0,
          max: 10,
          min_color: "#C6E48B",
          max_color: "#196127"
        })

      json = HeatmapChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "heatmap"
      assert decoded["title_text"] == "Test"
      assert decoded["x_axis_data"] == ["A", "B"]
      assert decoded["y_axis_data"] == ["X", "Y"]
      assert decoded["series"]["data"] == [[0, 0, 5]]
      assert decoded["series"]["min"] == 0
      assert decoded["series"]["max"] == 10
    end

    test "omits nil fields" do
      json = HeatmapChart.new() |> HeatmapChart.title("X") |> HeatmapChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "series")
    end
  end

  describe "render integration" do
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
                   [0, 0, 5],
                   [0, 1, 10],
                   [1, 0, 15],
                   [1, 1, 20],
                   [2, 0, 25],
                   [2, 1, 30]
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
end
