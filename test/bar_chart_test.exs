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
