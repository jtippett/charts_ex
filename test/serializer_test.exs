defmodule ChartsEx.SerializerTest do
  use ExUnit.Case, async: true

  alias ChartsEx.Serializer

  test "to_json/2 drops nil fields and injects type" do
    struct_map = %{
      __struct__: SomeChart,
      title_text: "Hello",
      width: 600,
      unused: nil
    }

    json = Serializer.to_json(struct_map, "bar")
    decoded = Jason.decode!(json)

    assert decoded["type"] == "bar"
    assert decoded["title_text"] == "Hello"
    assert decoded["width"] == 600
    refute Map.has_key?(decoded, "unused")
    refute Map.has_key?(decoded, "__struct__")
  end

  test "to_json/2 converts atom values to strings" do
    struct_map = %{
      __struct__: SomeChart,
      legend_align: :center,
      legend_category: :round_rect
    }

    json = Serializer.to_json(struct_map, "bar")
    decoded = Jason.decode!(json)

    assert decoded["legend_align"] == "center"
    assert decoded["legend_category"] == "round_rect"
  end

  test "to_json/2 passes through nested maps and lists" do
    struct_map = %{
      __struct__: SomeChart,
      series_list: [%{name: "A", data: [1.0, 2.0]}],
      margin: %{left: 10, top: 5, right: 10, bottom: 5}
    }

    json = Serializer.to_json(struct_map, "line")
    decoded = Jason.decode!(json)

    assert decoded["type"] == "line"
    assert [%{"name" => "A", "data" => [1.0, 2.0]}] = decoded["series_list"]
    assert %{"left" => 10} = decoded["margin"]
  end
end
