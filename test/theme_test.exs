defmodule ChartsEx.ThemeTest do
  use ExUnit.Case, async: true

  alias ChartsEx.Theme

  test "list/0 returns all theme atoms" do
    themes = Theme.list()
    assert :light in themes
    assert :dark in themes
    assert :grafana in themes
    assert length(themes) == 9
  end

  test "validate!/1 accepts valid themes" do
    assert Theme.validate!(:dark) == "dark"
    assert Theme.validate!(:grafana) == "grafana"
  end

  test "validate!/1 raises on unknown theme" do
    assert_raise ArgumentError, ~r/unknown theme/, fn ->
      Theme.validate!(:nope)
    end
  end
end
