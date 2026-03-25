defmodule ChartsEx.Component do
  @moduledoc """
  Phoenix function component for rendering charts inline.

  ## Usage in LiveView/HEEx templates

      <ChartsEx.Component.chart config={@chart} />
      <ChartsEx.Component.chart config={@chart} class="mx-auto max-w-2xl" id="revenue" />

  The chart is rendered as inline SVG wrapped in a `<div>`.
  """

  if Code.ensure_loaded?(Phoenix.Component) do
    use Phoenix.Component
    import Phoenix.HTML, only: [raw: 1]

    @doc """
    Renders a chart as inline SVG.

    ## Attributes

      * `config` (required) — a chart struct, atom-key map, or JSON string
      * `class` — optional CSS class for the wrapping div
      * `id` — optional DOM id for the wrapping div
    """
    attr :config, :any, required: true
    attr :class, :string, default: nil
    attr :id, :string, default: nil

    def chart(assigns) do
      svg = ChartsEx.render!(assigns.config)
      assigns = Phoenix.Component.assign(assigns, :svg, svg)

      ~H"""
      <div id={@id} class={@class}>{raw(@svg)}</div>
      """
    end
  end
end
