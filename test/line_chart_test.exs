defmodule ChartsEx.LineChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.LineChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = LineChart.new()
      assert %LineChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        LineChart.new()
        |> LineChart.title("Temperature")
        |> LineChart.sub_title("Weekly")
        |> LineChart.theme(:dark)
        |> LineChart.width(600)
        |> LineChart.height(400)
        |> LineChart.x_axis(["Mon", "Tue", "Wed"])

      assert chart.title_text == "Temperature"
      assert chart.sub_title_text == "Weekly"
      assert chart.theme == "dark"
      assert chart.width == 600
      assert chart.height == 400
      assert chart.x_axis_data == ["Mon", "Tue", "Wed"]
    end

    test "add_series/3 appends series" do
      chart =
        LineChart.new()
        |> LineChart.add_series("A", [1.0, 2.0, 3.0])
        |> LineChart.add_series("B", [4.0, 5.0, 6.0])

      assert length(chart.series_list) == 2
      assert Enum.at(chart.series_list, 0).name == "A"
      assert Enum.at(chart.series_list, 1).name == "B"
    end

    test "add_series/4 accepts options" do
      chart =
        LineChart.new()
        |> LineChart.add_series("A", [1.0, 2.0], label_show: true)

      series = hd(chart.series_list)
      assert series.label_show == true
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

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        LineChart.new()
        |> LineChart.title("Test")
        |> LineChart.x_axis(["A", "B"])
        |> LineChart.add_series("S1", [1.0, 2.0])

      json = LineChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "line"
      assert decoded["title_text"] == "Test"
      assert decoded["x_axis_data"] == ["A", "B"]
      assert [%{"name" => "S1", "data" => [1.0, 2.0]}] = decoded["series_list"]
    end

    test "omits nil fields" do
      json = LineChart.new() |> LineChart.title("X") |> LineChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "sub_title_text")
    end

    test "includes smooth and fill in JSON" do
      json =
        LineChart.new()
        |> LineChart.smooth(true)
        |> LineChart.fill(true)
        |> LineChart.to_json()

      decoded = Jason.decode!(json)
      assert decoded["series_smooth"] == true
      assert decoded["series_fill"] == true
    end
  end

  describe "render integration" do
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
  end
end
