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
