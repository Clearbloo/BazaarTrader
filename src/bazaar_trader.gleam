import derivative.{type OptionContract, Call, Put}
import gleam/bit_array
import gleam/bytes_tree
import gleam/erlang/process
import gleam/float
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import logging
import market.{type Market, type Time, Market}
import mist.{type Connection, type ResponseData}
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

const index = "<html lang='en'>
  <head>
    <title>Mist Example</title>
  </head>
  <body>
    Hello, world!
  </body>
</html>"

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_tree.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      logging.log(
        logging.Info,
        "Got a request from: " <> string.inspect(mist.get_client_info(req.body)),
      )
      logging.log(
        logging.Info,
        "Path segments" <> string.inspect(request.path_segments(req)),
      )
      case request.path_segments(req) {
        [] ->
          response.new(200)
          |> response.prepend_header("my-value", "abc")
          |> response.prepend_header("my-value", "123")
          |> response.set_body(mist.Bytes(bytes_tree.from_string(index)))
        ["echo"] -> echo_body(req)
        ["simulate"] -> todo

        _ -> not_found
      }
    }
    |> mist.new
    |> mist.bind("localhost")
    |> mist.with_ipv6
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}

fn respond_with_json(message: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(message)))
  |> response.set_header("content-type", "text/json")
}

fn respond_with_string(message: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(message)))
  |> response.set_header("content-type", "text/plain")
}

fn echo_body(request: Request(Connection)) -> Response(ResponseData) {
  case request.get_header(request, "content-type") {
    Error(Nil) -> {
      respond_with_string("Couldn't read a content-type header: ")
    }
    Ok(content_type) -> {
      case content_type {
        "text/plain" -> {
          mist.read_body(request, 1024 * 1024 * 10)
          |> result.map(fn(req) {
            let body = bit_array.to_string(req.body) |> result.unwrap("")
            let resp_body = "Yo what's up, you said: " <> body
            respond_with_string(resp_body)
          })
          |> result.lazy_unwrap(fn() {
            response.new(400)
            |> response.set_body(mist.Bytes(bytes_tree.new()))
          })
        }
        _ -> respond_with_string("Don't know how to handle " <> content_type)
      }
    }
  }
}
