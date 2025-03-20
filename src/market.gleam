import gleam/float
import gleam/result
import gleam_community/maths/elementary
import gleeunit/should
import model

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
    -2.0 *. logu *. elementary.cos({ 2.0 *. elementary.pi() *. u2 })
  }
  mu *. std *. z0
}

pub fn gmb(value: Float, mu: Float, std: Float, delta_t: Float) {
  let drift = mu *. delta_t
  let dw = random_normal(mu, std)
  let diffusion = std *. dw
  value *. { drift +. diffusion }
}

pub fn discount_factor(value: Float, rate: Float, time: Float) {
  elementary.exponential(rate *. time) *. value
}

pub fn update_price(secu: model.Security, tick: Float) {
  // Use Geometric Brownian motion to increment the stock prices
  case secu {
    model.Stock(value, mu, std, _) -> {
      gmb(value, mu, std, tick)
    }
    model.Bond(payout) -> {
      discount_factor(payout, 1.0, tick)
    }
  }
}
