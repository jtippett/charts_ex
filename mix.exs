defmodule ChartsEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jtippett/charts_ex"

  def project do
    [
      app: :charts_ex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "ChartsEx",
      description: "SVG chart rendering for Elixir powered by charts-rs",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:rustler, "~> 0.37", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      {:jason, "~> 1.4"},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files:
        [
          "lib",
          "native/charts_ex/src",
          "native/charts_ex/Cargo*",
          "native/charts_ex/Cross.toml",
          "mix.exs",
          "README.md",
          "LICENSE"
        ] ++ Path.wildcard("checksum-*.exs"),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "ChartsEx",
      extras: ["README.md"]
    ]
  end
end
