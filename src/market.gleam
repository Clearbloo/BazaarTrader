//// A market just gives you the price of things.
//// Maybe a bit more like bid and ask is more realistic but this is enough for now

import derivative.{type Derivative}
import gleam/float
import gleam/result
import gleam_community/maths.{cos, exponential, pi}
import gleeunit/should
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
  Market(product: Product, ticket: Ticker, prices: OrderedDict(Time, Price))
}

pub fn random_normal(mu: Float, std: Float) {
  let u1 = float.random()
  let u2 = float.random()
  should.not_equal(u1, u2)
  should.not_equal(u1, 0.0)
  should.not_equal(u2, 0.0)
  let logu =
    float.logarithm(u1)
    |> result.unwrap(0.0)
  let z0 = {
    -2.0 *. logu *. cos({ 2.0 *. pi() *. u2 })
  }
  mu *. std *. z0
}

pub fn gmb(start_price: Price, mu: Float, std: Float, delta_t: Time) {
  let drift = mu *. delta_t
  let dw = random_normal(mu, std)
  let diffusion = std *. dw
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
          let tick = 0.1
          case ordered_dict.latest(m.prices) {
            Ok(initial) -> gmb(initial, mu, std, tick)
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
