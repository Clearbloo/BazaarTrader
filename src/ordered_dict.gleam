//// OrderedDict - A dictionary wrapper that tracks key order

import gleam/dict.{type Dict}
import gleam/float
import gleam/list
import gleam/order

/// Order is largest to smallest
pub type OrderedDict(k, v) {
  OrderedDict(
    values: Dict(k, v),
    order: List(k),
    order_func: fn(k, k) -> order.Order,
  )
}

pub fn new_float() {
  OrderedDict(dict.new(), list.new(), fn(x, y) {
    float.compare(x, y) |> order.negate
  })
}

pub fn get(d: OrderedDict(key, value), k: key) -> Result(value, Nil) {
  d.values
  |> dict.get(k)
}

pub fn insert(
  d: OrderedDict(key, value),
  k: key,
  v: value,
) -> OrderedDict(key, value) {
  let already_exists = dict.has_key(d.values, k)
  let order = case already_exists {
    True -> d.order
    False -> {
      case d.order {
        [] -> [k]
        [first, ..] -> {
          case d.order_func(k, first) {
            order.Lt -> [k, ..d.order]
            _ -> [k, ..d.order] |> list.sort(d.order_func)
          }
        }
      }
    }
  }
  OrderedDict(dict.insert(d.values, k, v), order, d.order_func)
}

pub fn latest(d: OrderedDict(key, value)) -> Result(key, Nil) {
  list.first(d.order)
}

pub fn to_list(d: OrderedDict(k, v)) -> List(#(k, v)) {
  use k <- list.map(d.order)
  let assert Ok(v) = dict.get(d.values, k)
  #(k, v)
}
