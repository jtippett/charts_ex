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
