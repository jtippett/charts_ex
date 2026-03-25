defmodule ChartsEx.NativeTest do
  use ExUnit.Case, async: true

  test "renders bar chart from JSON" do
    json =
      Jason.encode!(%{
        "type" => "bar",
        "width" => 600,
        "height" => 400,
        "title_text" => "Test",
        "series_list" => [%{"name" => "A", "data" => [1.0, 2.0, 3.0]}],
        "x_axis_data" => ["X", "Y", "Z"]
      })

    assert {:ok, svg} = ChartsEx.Native.render(json)
    assert svg =~ "<svg"
  end

  test "returns error for invalid JSON" do
    assert {:error, msg} = ChartsEx.Native.render("not json")
    assert msg =~ "invalid JSON"
  end

  test "returns error for missing type" do
    json = Jason.encode!(%{"width" => 600})
    assert {:error, msg} = ChartsEx.Native.render(json)
    assert msg =~ "type"
  end

  test "returns error for unknown chart type" do
    json = Jason.encode!(%{"type" => "nope"})
    assert {:error, msg} = ChartsEx.Native.render(json)
    assert msg =~ "unknown chart type"
  end
end
