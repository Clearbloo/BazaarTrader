import gleam/io
import gleam/list
import gleam/result
import ordered_dict

import derivative.{type OptionContract, Call, Put}
import market.{type Market, type Time, Market}
import security.{Stock}

pub fn value_option(opt: OptionContract) {
  case opt.option_type {
    Call -> 1.0
    Put -> 2.0
  }
}

pub fn single_variable_gaussian_variance(x: List(Float)) {
  x |> fn(x) { systematic_variance(x, 0.5) +. idiosyncratic_variance(x, 0.5) }
}

pub fn systematic_variance(x: List(Float), rho: Float) {
  let sum_x = x |> list.fold(0.0, fn(acc, x) { acc +. x })
  rho *. rho *. sum_x *. sum_x
}

pub fn idiosyncratic_variance(x: List(Float), rho: Float) {
  let var_x = x |> list.fold(0.0, fn(acc, x) { acc +. x *. x })
  var_x *. { 1.0 -. rho *. rho }
}

pub fn simulate(
  n: Int,
  m: Market,
  step: Time,
  sim_func: fn(Market, Time) -> Float,
) -> Result(Market, Nil) {
  case n {
    0 -> Ok(m)
    foo if foo < 0 -> Error(Nil)
    _ -> {
      use latest_time <- result.try(ordered_dict.latest(m.prices))
      let new_prices =
        ordered_dict.insert(m.prices, latest_time +. step, sim_func(m, step))
      let m = Market(..m, prices: new_prices)
      simulate(n - 1, m, step, sim_func)
    }
  }
}

pub fn main() {
  let stock = Stock
  let some_stock = market.Security(Stock)
  let call = derivative.OptionContract(1.2, "hi", stock, Call)
  io.debug(call)
  let var = single_variable_gaussian_variance([call.strike])
  io.debug(var)

  let market = Market(some_stock, "FOO", ordered_dict.new_float())
  let new_prices = simulate(10, market, 0.1, market.model_price)
  io.debug(new_prices)
}
