use charts_rs::{
    BarChart, CandlestickChart, HeatmapChart, HorizontalBarChart, LineChart, MultiChart,
    PieChart, RadarChart, ScatterChart, TableChart,
};
use rustler::{Encoder, Env, NifResult, Term};

rustler::init!("Elixir.ChartsEx.Native");

mod atoms {
    rustler::atoms! { ok, error }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn render<'a>(env: Env<'a>, json: &str) -> NifResult<Term<'a>> {
    let value: serde_json::Value = match serde_json::from_str(json) {
        Ok(v) => v,
        Err(e) => return Ok((atoms::error(), format!("invalid JSON: {e}")).encode(env)),
    };

    let chart_type = match value.get("type").and_then(|v| v.as_str()) {
        Some(t) => t,
        None => {
            return Ok((atoms::error(), "missing \"type\" field".to_string()).encode(env))
        }
    };

    let result = match chart_type {
        "bar" => BarChart::from_json(json).and_then(|c| c.svg()),
        "horizontal_bar" => HorizontalBarChart::from_json(json).and_then(|c| c.svg()),
        "line" => LineChart::from_json(json).and_then(|c| c.svg()),
        "pie" => PieChart::from_json(json).and_then(|c| c.svg()),
        "radar" => RadarChart::from_json(json).and_then(|c| c.svg()),
        "scatter" => ScatterChart::from_json(json).and_then(|c| c.svg()),
        "candlestick" => CandlestickChart::from_json(json).and_then(|c| c.svg()),
        "heatmap" => HeatmapChart::from_json(json).and_then(|c| c.svg()),
        "table" => TableChart::from_json(json).and_then(|mut c| c.svg()),
        "multi_chart" => MultiChart::from_json(json).and_then(|mut c| c.svg()),
        _ => {
            return Ok((
                atoms::error(),
                format!("unknown chart type: {chart_type}"),
            )
                .encode(env))
        }
    };

    match result {
        Ok(svg) => Ok((atoms::ok(), svg).encode(env)),
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env)),
    }
}
