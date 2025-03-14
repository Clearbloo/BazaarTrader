import bazaar_trader
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn systematic_test() {
  bazaar_trader.systematic_variance([1.0, 2.0, 3.0], 0.5)
  |> should.equal(9.0)
}

pub fn idiosyncratic_test() {
  bazaar_trader.idiosyncratic_variance([1.0, 2.0, 3.0], 0.5)
  |> should.equal(10.5)
}

pub fn single_variable_guassian_test() {
  bazaar_trader.single_variable_gaussian_variance([1.0, 2.0, 3.0])
  |> should.equal(19.5)
}
