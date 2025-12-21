import derivative.{type OptionContract, Call, Put}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import market.{type Market, type Time, Market}
import ordered_dict

pub fn value_option(opt: OptionContract) {
  case opt.option_type {
    Call -> 1.0
    Put -> 2.0
  }
}

pub fn single_variable_gaussian_variance(x: List(Float)) {
  systematic_variance(x, 0.5) +. idiosyncratic_variance(x, 0.5)
}

/// Returns the list with each element raised to the power p.
pub fn raise_list(l: List(Float), p: Float) -> Result(List(Float), Nil) {
  use x <- list.try_map(l)
  float.power(x, p)
}

pub fn agg_list(l: List(t), start: t, sum_func: fn(t, t) -> t) -> t {
  use acc, x <- list.fold(l, start)
  sum_func(acc, x)
}

pub fn p_norm(l, p) -> Result(Float, Nil) {
  use rl <- result.try(raise_list(l, p))
  let sum_p = agg_list(rl, 0.0, float.add)
  float.power(sum_p, 1.0 /. p)
}

pub fn pth_moment(l: List(Float), p: Float) -> Result(Float, Nil) {
  case p_norm(l, p) {
    Ok(norm) -> Ok({ norm /. { list.length(l) |> int.to_float } })
    Error(_) -> Error(Nil)
  }
}

pub fn systematic_variance(x: List(Float), rho: Float) {
  let sum_x = x |> list.fold(0.0, fn(acc, x) { acc +. x })
  rho *. rho *. sum_x *. sum_x
}

pub fn idiosyncratic_variance(x: List(Float), rho: Float) {
  let var_x = x |> list.fold(0.0, fn(acc, x) { acc +. x *. x })
  var_x *. { 1.0 -. rho *. rho }
}

pub type SimulationError {
  NegativeSteps
  NoPrices
}

pub fn simulate(
  n: Int,
  m: Market,
  step: Time,
  sim_func: fn(Market, Time) -> Float,
) -> Result(Market, SimulationError) {
  case n {
    0 -> Ok(m)
    foo if foo < 0 -> Error(NegativeSteps)
    _ -> {
      case ordered_dict.latest(m.prices) {
        Ok(latest_time) -> {
          let new_prices =
            ordered_dict.insert(
              m.prices,
              latest_time +. step,
              sim_func(m, step),
            )
          let m = Market(..m, prices: new_prices)
          simulate(n - 1, m, step, sim_func)
        }
        Error(_) -> Error(NoPrices)
      }
    }
  }
}
