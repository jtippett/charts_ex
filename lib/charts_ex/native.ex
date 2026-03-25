defmodule ChartsEx.Native do
  @moduledoc false

  use RustlerPrecompiled,
    otp_app: :charts_ex,
    crate: "charts_ex",
    base_url:
      "https://github.com/jtippett/charts_ex/releases/download/v#{Mix.Project.config()[:version]}",
    force_build: System.get_env("CHARTS_EX_BUILD") in ["1", "true"],
    version: Mix.Project.config()[:version],
    nif_versions: ["2.17", "2.16", "2.15"],
    targets: [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu"
    ]

  def render(_json), do: :erlang.nif_error(:nif_not_loaded)
end
