import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute.{class, type_, value}
import lustre/effect
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import lustre_http


pub type Model {
  Model(
    steps: Int,
    market: String,
    step_size: Float,
    simulation_result: Option(SimulationData),
    error: Option(String),
  )
}

pub type SimulationData {
  SimulationData(ticker: String, prices: List(PricePoint))
}

pub type PricePoint {
  PricePoint(time: Float, price: Float)
}

pub fn init(_) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      steps: 100,
      market: "FOO",
      step_size: 0.1,
      simulation_result: None,
      error: None,
    ),
    effect.none(),
  )
}

// UPDATE

pub type Msg {
  SetSteps(String)
  SetMarket(String)
  SetStepSize(String)
  Simulate
  GotSimulationResult(Result(SimulationData, lustre_http.HttpError))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SetSteps(val) -> {
      let steps = int.parse(val) |> option.from_result |> option.unwrap(model.steps)
      #(Model(..model, steps: steps), effect.none())
    }
    SetMarket(val) -> #(Model(..model, market: val), effect.none())
    SetStepSize(val) -> {
      let size = float.parse(val) |> option.from_result |> option.unwrap(model.step_size)
      #(Model(..model, step_size: size), effect.none())
    }
    Simulate -> {
      #(model, perform_simulation(model.steps, model.market, model.step_size))
    }
    GotSimulationResult(Ok(data)) -> {
      #(Model(..model, simulation_result: Some(data), error: None), effect.none())
    }
    GotSimulationResult(Error(err)) -> {
      let err_msg = case err {
        lustre_http.NetworkError -> "Network Error"
        lustre_http.JsonError(_) -> "JSON Decode Error"
        _ -> "Unknown Error"
      }
      #(Model(..model, error: Some(err_msg)), effect.none())
    }
  }
}

// VIEW

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("container")], [
    html.h1([], [text("Bazaar Trader")]),
    view_form(model),
    view_results(model),
  ])
}

fn view_form(model: Model) -> Element(Msg) {
  html.div([], [
    html.div([class("form-group")], [
      html.label([], [text("Number of Steps")]),
      html.input([
        type_("number"),
        value(int.to_string(model.steps)),
        event.on_input(SetSteps),
      ]),
    ]),
    html.div([class("form-group")], [
      html.label([], [text("Market Ticker")]),
      html.input([
        type_("text"),
        value(model.market),
        event.on_input(SetMarket),
      ]),
    ]),
    html.div([class("form-group")], [
      html.label([], [text("Step Size")]),
      html.input([
        type_("number"),
        attribute.attribute("step", "0.01"),
        value(float.to_string(model.step_size)),
        event.on_input(SetStepSize),
      ]),
    ]),
    html.button([event.on_click(Simulate)], [text("Simulate Market")]),
  ])
}

fn view_results(model: Model) -> Element(Msg) {
  case model.error, model.simulation_result {
    Some(err), _ ->
      html.div([class("error"), attribute.attribute("style", "color: #ef4444; margin-top: 1rem;")], [
        text("Error: " <> err),
      ])
    _, Some(data) ->
      html.div([class("results")], [
        html.h2([], [text("Results for " <> data.ticker)]),
        view_prices_table(data.prices),
      ])
    _, None -> html.div([], [])
  }
}

fn view_prices_table(prices: List(PricePoint)) -> Element(Msg) {
  html.div([class("table-container")], [
    html.table([], [
      html.thead([], [
        html.tr([], [html.th([], [text("Time")]), html.th([], [text("Price")])]),
      ]),
      html.tbody(
        [],
        list.map(prices, fn(p) {
          html.tr([], [
            html.td([], [text(float.to_string(p.time))]),
            html.td([], [text(float.to_string(p.price))]),
          ])
        }),
      ),
    ]),
  ])
}

// MAIN

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// EFFECTS / HTTP

fn perform_simulation(n: Int, market: String, step: Float) -> effect.Effect(Msg) {
  let body =
    json.object([
      #("n", json.int(n)),
      #("market", json.string(market)),
      #("step", json.float(step)),
    ])

  let price_point_decoder = {
    use time <- decode.field("time", decode.float)
    use price <- decode.field("price", decode.float)
    decode.success(PricePoint(time, price))
  }

  let decoder = {
    use ticker <- decode.field("ticker", decode.string)
    use prices <- decode.field("prices", decode.list(price_point_decoder))
    decode.success(SimulationData(ticker, prices))
  }

  lustre_http.post("/simulate", body, lustre_http.expect_json(decoder, GotSimulationResult))
}
