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
