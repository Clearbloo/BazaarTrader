import bazaar_trader as bazaar
import derivative.{Call}
import gleam/float
import gleeunit
import gleeunit/should
import market.{Market}
import ordered_dict
import security.{Stock}

pub fn main() {
  gleeunit.main()
}

fn approx(a: Float, b: Float, tolerance: Float) {
  float.absolute_value(a -. b) <. tolerance
}

pub fn systematic_test() {
  bazaar.systematic_variance([1.0, 2.0, 3.0], 0.5)
  |> should.equal(9.0)
}

pub fn idiosyncratic_test() {
  bazaar.idiosyncratic_variance([1.0, 2.0, 3.0], 0.5)
  |> should.equal(10.5)
}

pub fn single_variable_guassian_test() {
  bazaar.single_variable_gaussian_variance([1.0, 2.0, 3.0])
  |> should.equal(19.5)
}

pub fn stock_test() {
  let stock = Stock
  let some_stock = market.Security(Stock)
  let call = derivative.OptionContract(1.2, "hi", stock, Call)
  let var = bazaar.single_variable_gaussian_variance([call.strike])
  var
  |> should.equal(1.44)

  let prices = ordered_dict.insert(ordered_dict.new_float(), 0.0, 10.0)
  let market = Market(some_stock, "FOO", prices)
  let m = bazaar.simulate(10, market, 0.1, market.model_price) |> should.be_ok

  ordered_dict.latest(m.prices)
  |> should.be_ok
  |> ordered_dict.get(m.prices, _)
  |> should.be_ok
  |> approx(0.9453719581290366, 0.1)
  |> should.be_true
}
