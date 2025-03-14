import bazaar_trader
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn systematic_test() {
  bazaar_trader.systematic([1, 2, 3])
  |> should.equal(14)
}
