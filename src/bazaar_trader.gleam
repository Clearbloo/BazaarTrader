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
import mist.{type Connection, type ResponseData}

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
        ["echo"] -> echo_body(req)
        ["simulate"] ->
          fn(request: Request(Connection)) -> Response(ResponseData) {
            use request, content_type <- get_content_header(request)
            case content_type {
              "application/json" -> {
                mist.read_body(request, 1024 * 1024 * 10)
                |> result.map(fn(req) {
                  case bit_array.to_string(req.body) {
                    Error(Nil) -> bad_request("couldn't decode json")
                    Ok(payload) -> {
                      let data =
                        json.parse(
                          payload,
                          decode.dict(decode.string, decode.string),
                        )
                      echo data
                      respond_with_json("foo")
                    }
                  }
                })
                |> result.lazy_unwrap(fn() { bad_request("something") })
              }
              _ -> unsupported_media_type(content_type, "application/json")
            }
          }(req)

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

fn get_content_header(
  request: Request(Connection),
  request_handler: fn(Request(Connection), String) -> Response(ResponseData),
) -> Response(ResponseData) {
  case request.get_header(request, "content-type") {
    Error(Nil) -> {
      respond_with_string("Couldn't read a content-type header: ")
    }
    Ok(content_type) -> request_handler(request, content_type)
  }
}

fn echo_body(request: Request(Connection)) -> Response(ResponseData) {
  use request, content_type <- get_content_header(request)
  case content_type {
    "text/plain" -> {
      mist.read_body(request, 1024 * 1024 * 10)
      |> result.map(fn(req) {
        let body = bit_array.to_string(req.body) |> result.unwrap("")
        let resp_body = "Yo what's up, you said: " <> body
        respond_with_string(resp_body)
      })
      |> result.lazy_unwrap(fn() { bad_request("todo") })
    }
    _ -> unsupported_media_type(content_type, "text/plain")
  }
}
