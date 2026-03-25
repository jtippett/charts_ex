defmodule ChartsEx.Serializer do
  @moduledoc false

  @doc """
  Converts a chart struct to a JSON string for the NIF.

  Drops nil fields, removes __struct__, injects the "type" key,
  and converts atom values to strings.
  """
  @spec to_json(struct(), String.t()) :: String.t()
  def to_json(chart, type) do
    chart
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {k, encode_value(v)} end)
    |> Map.new()
    |> Map.put(:type, type)
    |> Jason.encode!()
  end

  defp encode_value(v) when is_boolean(v), do: v
  defp encode_value(nil), do: nil
  defp encode_value(v) when is_atom(v), do: Atom.to_string(v)
  defp encode_value(v) when is_list(v), do: Enum.map(v, &encode_value/1)
  defp encode_value(%{__struct__: _} = v), do: v |> Map.from_struct() |> encode_value()

  defp encode_value(v) when is_map(v) do
    v
    |> Enum.reject(fn {_k, val} -> is_nil(val) end)
    |> Enum.map(fn {k, val} -> {k, encode_value(val)} end)
    |> Map.new()
  end

  defp encode_value(v), do: v
end
