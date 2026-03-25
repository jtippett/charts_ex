defmodule ChartsEx.TableChartTest do
  use ExUnit.Case, async: true

  alias ChartsEx.TableChart

  describe "builder API" do
    test "new/0 creates an empty struct" do
      chart = TableChart.new()
      assert %TableChart{} = chart
      assert chart.title_text == nil
    end

    test "builder functions set fields" do
      chart =
        TableChart.new()
        |> TableChart.title("Sales Data")
        |> TableChart.sub_title("2024")
        |> TableChart.theme(:dark)
        |> TableChart.width(600)
        |> TableChart.height(300)
        |> TableChart.data([
          ["Name", "Q1", "Q2"],
          ["Alice", "120", "150"]
        ])
        |> TableChart.spans([2.0, 1.0, 1.0])
        |> TableChart.text_aligns([:left, :center, :right])
        |> TableChart.border_color("#333333")
        |> TableChart.header_background_color("#4A90D9")
        |> TableChart.header_font_color("#FFFFFF")
        |> TableChart.body_background_colors(["#F5F5F5", "#FFFFFF"])
        |> TableChart.background_color("#EEEEEE")

      assert chart.title_text == "Sales Data"
      assert chart.sub_title_text == "2024"
      assert chart.theme == "dark"
      assert chart.width == 600
      assert chart.height == 300
      assert chart.data == [["Name", "Q1", "Q2"], ["Alice", "120", "150"]]
      assert chart.spans == [2.0, 1.0, 1.0]
      assert chart.text_aligns == [:left, :center, :right]
      assert chart.border_color == "#333333"
      assert chart.header_background_color == "#4A90D9"
      assert chart.header_font_color == "#FFFFFF"
      assert chart.body_background_colors == ["#F5F5F5", "#FFFFFF"]
      assert chart.background_color == "#EEEEEE"
    end

    test "cell_styles/2 sets cell-level styling" do
      styles = [
        %{indexes: [1], font_color: "#FF0000", font_weight: "bold"},
        %{indexes: [2], font_color: "#00FF00"}
      ]

      chart =
        TableChart.new()
        |> TableChart.cell_styles(styles)

      assert chart.cell_styles == styles
    end
  end

  describe "to_json/1" do
    test "serializes to JSON with type field" do
      chart =
        TableChart.new()
        |> TableChart.title("Test")
        |> TableChart.data([
          ["A", "B"],
          ["1", "2"]
        ])
        |> TableChart.spans([1.0, 1.0])

      json = TableChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["type"] == "table"
      assert decoded["title_text"] == "Test"
      assert decoded["data"] == [["A", "B"], ["1", "2"]]
      assert decoded["spans"] == [1.0, 1.0]
    end

    test "omits nil fields" do
      json = TableChart.new() |> TableChart.title("X") |> TableChart.to_json()
      decoded = Jason.decode!(json)

      assert decoded["title_text"] == "X"
      refute Map.has_key?(decoded, "width")
      refute Map.has_key?(decoded, "data")
      refute Map.has_key?(decoded, "spans")
      refute Map.has_key?(decoded, "cell_styles")
    end

    test "converts atom values to strings" do
      chart =
        TableChart.new()
        |> TableChart.text_aligns([:left, :center, :right])

      json = TableChart.to_json(chart)
      decoded = Jason.decode!(json)

      assert decoded["text_aligns"] == ["left", "center", "right"]
    end
  end

  describe "render integration" do
    test "builder API and render" do
      assert {:ok, svg} =
               TableChart.new()
               |> TableChart.title("Sales Data")
               |> TableChart.width(600)
               |> TableChart.height(300)
               |> TableChart.data([
                 ["Name", "Q1", "Q2", "Q3"],
                 ["Alice", "120", "150", "180"],
                 ["Bob", "90", "110", "130"]
               ])
               |> TableChart.spans([2.0, 1.0, 1.0, 1.0])
               |> ChartsEx.render()

      assert svg =~ "<svg"
    end
  end
end
