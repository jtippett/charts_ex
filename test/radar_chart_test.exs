defmodule ChartsEx.RadarChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.RadarChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = RadarChart.new()
      assert %RadarChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        RadarChart.new()
        |> RadarChart.title("Skills")
        |> RadarChart.sub_title("2024")
        |> RadarChart.theme(:dark)
        |> RadarChart.width(600)
        |> RadarChart.height(400)

      assert chart.title_text == "Skills"
      assert chart.sub_title_text == "2024"
      assert chart.theme == "dark"
      assert chart.width == 600
      assert chart.height == 400
    end

    test "indicators/2 sets radar indicators" do
      indicators = [
        %{name: "Elixir", max: 100.0},
        %{name: "Rust", max: 100.0},
        %{name: "Go", max: 100.0}
      ]

      chart =
        RadarChart.new()
        |> RadarChart.indicators(indicators)

      assert chart.indicators == indicators
    end

    test "add_series/3 appends series" do
      chart =
        RadarChart.new()
        |> RadarChart.add_series("Dev A", [90.0, 70.0, 60.0])
        |> RadarChart.add_series("Dev B", [60.0, 80.0, 90.0])

      assert length(chart.series_list) == 2
      assert Enum.at(chart.series_list, 0).name == "Dev A"
      assert Enum.at(chart.series_list, 1).name == "Dev B"
    end

    test "add_series/4 accepts options" do
      chart =
        RadarChart.new()
        |> RadarChart.add_series("A", [1.0, 2.0, 3.0], label_show: true)

      series = hd(chart.series_list)
      assert series.label_show == true
    end
  end

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        RadarChart.new()
        |> RadarChart.title("Test")
        |> RadarChart.indicators([
          %{name: "A", max: 100.0},
          %{name: "B", max: 100.0}
        ])
        |> RadarChart.add_series("S1", [80.0, 70.0])

      json = RadarChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "radar"
      assert decoded["title_text"] == "Test"

      assert [%{"name" => "A", "max" => 100.0}, %{"name" => "B", "max" => 100.0}] =
               decoded["indicators"]

      assert [%{"name" => "S1", "data" => [80.0, 70.0]}] = decoded["series_list"]
    end

    test "omits nil fields" do
      json = RadarChart.new() |> RadarChart.title("X") |> RadarChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "indicators")
    end
  end

  describe "render integration" do
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
end
