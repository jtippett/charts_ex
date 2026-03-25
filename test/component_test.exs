defmodule ChartsEx.ComponentTest do
  use ExUnit.Case, async: true

  # Only run if Phoenix is available
  if Code.ensure_loaded?(Phoenix.Component) do
    import Phoenix.LiveViewTest
    import Phoenix.Component

    test "chart/1 renders SVG in a div" do
      config =
        ChartsEx.BarChart.new()
        |> ChartsEx.BarChart.title("Component Test")
        |> ChartsEx.BarChart.x_axis(["A", "B"])
        |> ChartsEx.BarChart.add_series("S", [1.0, 2.0])

      assigns = %{config: config, id: "test-chart", class: "w-full"}

      html =
        rendered_to_string(~H"""
        <ChartsEx.Component.chart config={@config} id={@id} class={@class} />
        """)

      assert html =~ "<div"
      assert html =~ ~s(id="test-chart")
      assert html =~ ~s(class="w-full")
      assert html =~ "<svg"
    end
  end
end
