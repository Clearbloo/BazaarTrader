import gleam/io
import gleam/list

pub fn main() {
  io.println("Hello from foo!")
}

pub fn systematic(x: List(Int)) {
  x |> list.fold(0, fn(acc, x) { acc + x * x })
}
