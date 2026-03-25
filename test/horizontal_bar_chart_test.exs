defmodule ChartsEx.HorizontalBarChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.HorizontalBarChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = HorizontalBarChart.new()
      assert %HorizontalBarChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        HorizontalBarChart.new()
        |> HorizontalBarChart.title("Ranking")
        |> HorizontalBarChart.sub_title("2024")
        |> HorizontalBarChart.theme(:dark)
        |> HorizontalBarChart.width(600)
        |> HorizontalBarChart.height(400)
        |> HorizontalBarChart.x_axis(["Go", "Rust", "Elixir"])

      assert chart.title_text == "Ranking"
      assert chart.sub_title_text == "2024"
      assert chart.theme == "dark"
      assert chart.width == 600
      assert chart.height == 400
      assert chart.x_axis_data == ["Go", "Rust", "Elixir"]
    end

    test "add_series/3 appends series" do
      chart =
        HorizontalBarChart.new()
        |> HorizontalBarChart.add_series("A", [1.0, 2.0, 3.0])
        |> HorizontalBarChart.add_series("B", [4.0, 5.0, 6.0])

      assert length(chart.series_list) == 2
      assert Enum.at(chart.series_list, 0).name == "A"
      assert Enum.at(chart.series_list, 1).name == "B"
    end

    test "add_series/4 accepts options" do
      chart =
        HorizontalBarChart.new()
        |> HorizontalBarChart.add_series("A", [1.0, 2.0], label_show: true)

      series = hd(chart.series_list)
      assert series.label_show == true
    end

    test "label_position/2 sets series_label_position" do
      chart =
        HorizontalBarChart.new()
        |> HorizontalBarChart.label_position(:right)

      assert chart.series_label_position == :right
    end
  end

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        HorizontalBarChart.new()
        |> HorizontalBarChart.title("Test")
        |> HorizontalBarChart.x_axis(["A", "B"])
        |> HorizontalBarChart.add_series("S1", [1.0, 2.0])

      json = HorizontalBarChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "horizontal_bar"
      assert decoded["title_text"] == "Test"
      assert decoded["x_axis_data"] == ["A", "B"]
      assert [%{"name" => "S1", "data" => [1.0, 2.0]}] = decoded["series_list"]
    end

    test "omits nil fields" do
      json = HorizontalBarChart.new() |> HorizontalBarChart.title("X") |> HorizontalBarChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "sub_title_text")
    end

    test "does not have radius field" do
      chart = HorizontalBarChart.new()
      refute Map.has_key?(Map.from_struct(chart), :radius)
    end
  end

  describe "render integration" do
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
end
