defmodule ChartsEx.PieChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.PieChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = PieChart.new()
      assert %PieChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        PieChart.new()
        |> PieChart.title("Market Share")
        |> PieChart.sub_title("2024")
        |> PieChart.theme(:dark)
        |> PieChart.width(600)
        |> PieChart.height(400)

      assert chart.title_text == "Market Share"
      assert chart.sub_title_text == "2024"
      assert chart.theme == "dark"
      assert chart.width == 600
      assert chart.height == 400
    end

    test "add_series/3 appends series" do
      chart =
        PieChart.new()
        |> PieChart.add_series("Chrome", [60.0])
        |> PieChart.add_series("Firefox", [25.0])
        |> PieChart.add_series("Safari", [15.0])

      assert length(chart.series_list) == 3
      assert Enum.at(chart.series_list, 0).name == "Chrome"
      assert Enum.at(chart.series_list, 1).name == "Firefox"
      assert Enum.at(chart.series_list, 2).name == "Safari"
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

    test "start_angle sets the starting angle" do
      chart = PieChart.new() |> PieChart.start_angle(90.0)
      assert chart.start_angle == 90.0
    end

    test "radius sets the outer radius" do
      chart = PieChart.new() |> PieChart.radius(200.0)
      assert chart.radius == 200.0
    end
  end

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        PieChart.new()
        |> PieChart.title("Test")
        |> PieChart.add_series("A", [50.0])
        |> PieChart.add_series("B", [30.0])

      json = PieChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "pie"
      assert decoded["title_text"] == "Test"
      assert [%{"name" => "A", "data" => [50.0]}, %{"name" => "B", "data" => [30.0]}] = decoded["series_list"]
    end

    test "omits nil fields" do
      json = PieChart.new() |> PieChart.title("X") |> PieChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "inner_radius")
    end

    test "includes pie-specific fields when set" do
      json =
        PieChart.new()
        |> PieChart.inner_radius(60.0)
        |> PieChart.rose_type(true)
        |> PieChart.border_radius(5.0)
        |> PieChart.start_angle(45.0)
        |> PieChart.to_json()

      decoded = Jason.decode!(json)

      assert decoded["inner_radius"] == 60.0
      assert decoded["rose_type"] == true
      assert decoded["border_radius"] == 5.0
      assert decoded["start_angle"] == 45.0
    end
  end

  describe "render integration" do
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
  end
end
