//// A market just gives you the price of things.
//// Maybe a bit more like bid and ask is more realistic but this is enough for now

import derivative.{type Derivative}
import gleam/float
import gleam/json
import gleam/result
import gleam_community/maths.{cos, exponential, pi}
import ordered_dict.{type OrderedDict}
import security.{type Security, Bond, Stock}

pub type Ticker =
  String

pub type Price =
  Float

pub type Time =
  Float

pub type Product {
  Security(Security)
  Derivative(Derivative)
}

/// Represents the market for a singular product
pub type Market {
  Market(product: Product, ticker: Ticker, prices: OrderedDict(Time, Price))
}

pub fn to_json(m: Market) -> String {
  json.object([
    #("ticker", json.string(m.ticker)),
    #(
      "prices",
      json.array(ordered_dict.to_list(m.prices), fn(p) {
        json.object([
          #("time", json.float(p.0)),
          #("price", json.float(p.1)),
        ])
      }),
    ),
  ])
  |> json.to_string
}

pub fn random_normal(mu: Float, std: Float) {
  let u1 = float.random()
  let u2 = float.random()
  // Since float.random() is [0, 1), we need to handle 0.0 for logarithm
  let u1 = case u1 {
    0.0 -> 0.0000000001
    _ -> u1
  }
  let logu =
    float.logarithm(u1)
    |> result.unwrap(0.0)
  let sqrt_part =
    float.square_root(-2.0 *. logu)
    |> result.unwrap(0.0)

  let z0 = sqrt_part *. cos({ 2.0 *. pi() *. u2 })
  mu +. { std *. z0 }
}

pub fn gmb(start_price: Price, mu: Float, std: Float, delta_t: Time) {
  let drift = mu *. delta_t
  let epsilon = random_normal(0.0, 1.0)
  // diffusion term: sigma * epsilon * sqrt(dt)
  let diffusion =
    std
    *. epsilon
    *. {
      float.square_root(delta_t)
      |> result.unwrap(0.0)
    }
  start_price +. { start_price *. { drift +. diffusion } }
}

pub fn discount_factor(value: Float, rate: Float, time: Float) {
  exponential(rate *. time) *. value
}

pub fn get_price(m: Market, time: Time) -> Price {
  m.prices
  |> ordered_dict.get(time)
  |> result.unwrap(0.0)
}

pub fn model_price(m: Market, tick: Float) {
  // Use Geometric Brownian motion to increment the stock prices
  case m.product {
    Security(secu) -> {
      case secu {
        Stock -> {
          let mu = 0.5
          let std = 0.05
          case ordered_dict.latest(m.prices) {
            Ok(time) -> {
              let assert Ok(initial) = ordered_dict.get(m.prices, time)
              gmb(initial, mu, std, tick)
            }
            Error(_) -> 0.0
          }
        }
        Bond(payout) -> {
          discount_factor(payout, 1.0, tick)
        }
      }
    }
    Derivative(_d) -> {
      1.0
    }
  }
}
