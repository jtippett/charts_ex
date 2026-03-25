defmodule ChartsEx.Chart do
  @moduledoc "Behaviour implemented by all chart type modules."

  @callback to_json(struct()) :: String.t()
end
