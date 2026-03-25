defmodule ChartsExTest do
  use ExUnit.Case, async: true

  describe "render/1 with atom-key map" do
    test "renders bar chart from map" do
      assert {:ok, svg} =
               ChartsEx.render(%{
                 type: :bar,
                 width: 600,
                 height: 400,
                 title_text: "Map Test",
                 series_list: [%{name: "A", data: [1.0, 2.0, 3.0]}],
                 x_axis_data: ["X", "Y", "Z"]
               })

      assert svg =~ "<svg"
      assert svg =~ "Map Test"
    end

    test "renders line chart from map" do
      assert {:ok, svg} =
               ChartsEx.render(%{
                 type: :line,
                 series_list: [%{name: "B", data: [5.0, 10.0]}],
                 x_axis_data: ["A", "B"]
               })

      assert svg =~ "<svg"
    end
  end

  describe "render/1 with raw JSON" do
    test "renders from JSON string" do
      json =
        Jason.encode!(%{
          "type" => "bar",
          "width" => 600,
          "height" => 400,
          "series_list" => [%{"name" => "A", "data" => [1.0, 2.0]}],
          "x_axis_data" => ["X", "Y"]
        })

      assert {:ok, svg} = ChartsEx.render(json)
      assert svg =~ "<svg"
    end
  end

  describe "render!/1" do
    test "returns SVG directly on success" do
      svg =
        ChartsEx.render!(%{
          type: :bar,
          series_list: [%{name: "A", data: [1.0]}],
          x_axis_data: ["X"]
        })

      assert svg =~ "<svg"
    end

    test "raises on error" do
      assert_raise RuntimeError, ~r/render error/, fn ->
        ChartsEx.render!("not json")
      end
    end
  end

  describe "render/1 error handling" do
    test "returns error for invalid input" do
      assert {:error, _} = ChartsEx.render("bad json")
    end

    test "returns error for missing type in map" do
      assert {:error, _} = ChartsEx.render(%{width: 600})
    end
  end
end
