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

pub fn repeat_n(
  n: Int,
  input: Result(value, String),
  func: fn(Result(value, String)) -> Result(value, String),
) {
  case n {
    0 -> input
    _ if n < 0 -> Error("Cannot repeat a negative number of times")
    _ -> func(input) |> repeat_n(n - 1, _, func)
  }
}

pub fn main() {
  let some_stock = model.Stock(10.0, 1.0, 0.1, 1.0)
  let call = model.OptionContract(1.2, "hi", some_stock, model.Call)
  io.debug(call)
  let var = single_variable_gaussian_variance([call.strike])
  io.debug(var)

  repeat_n(10, Ok(some_stock), fn(stock: Result(model.Security, String)) {
    case stock {
      Ok(some_stock) -> {
        let new_price = market.update_price(some_stock, 1.0)
        io.debug(new_price)
        let some_stock = model.Stock(..some_stock, value: new_price)
        Ok(some_stock)
      }
      Error(s) -> Error(s)
    }
  })
}
