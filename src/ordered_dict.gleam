//// OrderedDict - A dictionary wrapper that tracks key order

import gleam/dict.{type Dict}
import gleam/float
import gleam/list
import gleam/order
import gleam/result

/// Order is largest to smallest
pub type OrderedDict(k, v) {
  OrderedDict(
    map: Dict(k, v),
    order: List(k),
    order_func: fn(k, k) -> order.Order,
  )
}

pub fn new_float() {
  OrderedDict(dict.new(), list.new(), float.compare)
}

pub fn get(d: OrderedDict(key, value), k: key) -> Result(value, Nil) {
  d.map
  |> dict.get(k)
}

pub fn insert(
  d: OrderedDict(key, value),
  k: key,
  v: value,
) -> OrderedDict(key, value) {
  let order = [k, ..d.order] |> list.sort(d.order_func)
  OrderedDict(dict.insert(d.map, k, v), order, d.order_func)
}

pub fn latest(d: OrderedDict(key, value)) -> Result(value, Nil) {
  use k <- result.try(list.first(d.order))
  get(d, k)
}
