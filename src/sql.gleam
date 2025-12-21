//// This module contains the code to run the sql queries defined in
//// `./src/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/calendar.{type Date}
import pog

/// A row you get from running the `find_market_data` query
/// defined in `./src/sql/find_market_data.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindMarketDataRow {
  FindMarketDataRow(price: Option(Int))
}

/// Runs the `find_market_data` query
/// defined in `./src/sql/find_market_data.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_market_data(
  db: pog.Connection,
  arg_1: Date,
) -> Result(pog.Returned(FindMarketDataRow), pog.QueryError) {
  let decoder = {
    use price <- decode.field(0, decode.optional(decode.int))
    decode.success(FindMarketDataRow(price:))
  }

  "SELECT price
  FROM aapl
  WHERE date > $1;
"
  |> pog.query
  |> pog.parameter(pog.calendar_date(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
