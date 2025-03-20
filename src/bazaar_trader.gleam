import gleam/io
import gleam/list
import market
import model

pub fn value_option(opt: model.OptionContract) {
  case opt.option_type {
    model.Call -> 1.0
    model.Put -> 2.0
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

pub fn main() {
  let some_stock = model.Stock(10.0, 1.0, 0.1, 1.0)
  let call = model.OptionContract(1.2, "hi", some_stock, model.Call)
  io.debug(call)
  let var = single_variable_gaussian_variance([call.strike])
  io.debug(var)
  let new_price = market.update_price(some_stock, 1.0)
  io.debug(new_price)
}
