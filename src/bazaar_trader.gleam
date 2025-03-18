import gleam/io
import gleam/list
import gleam/option

pub type Security {
  Stock
}

pub type OptionContract {
  CallOption(strike: Float, maturity: String, underlying: Security)
  PutOption(strike: Float, underlying: Security)
}

pub fn value_option(_opt: OptionContract) {
  todo
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
  let some_stock = Stock
  let call = CallOption(1.2, "hi", some_stock)
  io.debug(call)
  let var = single_variable_gaussian_variance([call.strike])
  io.debug(var)
}
