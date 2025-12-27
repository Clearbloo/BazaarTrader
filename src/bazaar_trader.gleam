//// Main api entrypoint

import gleam/bit_array
import gleam/bytes_tree
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import gleam/string
import logging
import market.{Market}
import mist.{type Connection, type ResponseData}
import ordered_dict
import security.{Stock}
import simulation

type SimArgs {
  SimArgs(n: Int, market: String, step: Float)
}

type SimulationError {
  BadPayload(String)
  MissingContentHeader
  DecodeError(json.DecodeError)
}

const index = "<html lang='en'>
  <head>
    <title>Bazaar Trader</title>
  </head>
  <body>
  Welcome!
  </body>
</html>"

fn unsupported_media_type(
  expected_type: String,
  received_type: String,
) -> Response(ResponseData) {
  response.new(415)
  |> response.set_body(
    mist.Bytes(bytes_tree.from_string(
      "Expected '" <> expected_type <> "' but got '" <> received_type <> "'",
    )),
  )
}

fn not_found() {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

fn bad_request(msg: String) {
  response.new(400)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(msg)))
}

fn get_market(_m: String) {
  let some_stock = market.Security(Stock)
  let prices = ordered_dict.insert(ordered_dict.new_float(), 0.0, 10.0)
  Market(some_stock, "FOO", prices)
}

fn handle_simulate(
  request: Request(Connection),
) -> Result(Response(ResponseData), SimulationError) {
  let decode_sim_args = {
    use n <- decode.field("n", decode.int)
    use market <- decode.field("market", decode.string)
    use step <- decode.field("step", decode.float)
    decode.success(SimArgs(n, market, step))
  }
  let header =
    request.get_header(request, "content-type")
    |> result.map_error(fn(_) { MissingContentHeader })
  use content_type <- result.try(header)
  case content_type {
    "application/json" -> {
      use req <- result.try(
        mist.read_body(request, 1024 * 1024 * 10)
        |> result.map_error(fn(_) { BadPayload("Couldn't read the body") }),
      )

      use req <- result.try(
        bit_array.to_string(req.body)
        |> result.map_error(fn(_) { BadPayload("Couldn't convert to a string") }),
      )
      let args =
        req
        |> json.parse(decode_sim_args)
        |> result.map_error(fn(e) { DecodeError(e) })
      use args <- result.try(args)
      let m = get_market(args.market)
      let sim = simulation.simulate(args.n, m, args.step, market.model_price)
      use sim <- result.try(
        sim
        |> result.map_error(fn(_) { BadPayload("Simulation failed") }),
      )
      Ok(respond_with_json(market.to_json(sim)))
    }
    _ -> Ok(unsupported_media_type(content_type, "application/json"))
  }
}

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

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
        ["simulate"] ->
          case handle_simulate(req) {
            Ok(resp) -> resp
            Error(BadPayload(msg)) -> bad_request(msg)
            Error(DecodeError(e)) -> bad_request("Json decode error")
            Error(MissingContentHeader) -> bad_request("Missing content header")
          }

        _ -> not_found()
      }
    }
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.with_ipv6
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}

fn respond_with_json(message: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(message)))
  |> response.set_header("content-type", "application/json")
}

fn respond_with_string(message: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(message)))
  |> response.set_header("content-type", "text/plain")
}
