import gleam/dict

// A market just gives you the price of things.
// Maybe a bit more like bid and ask but this is enough for now
pub type Market {
  Market(dict.Dict(Product, Float))
}

pub type Product {
  Security
  Derivative
}

pub type Security {
  Stock(mu: Float, std: Float, time: Float)
  Bond(payout: Float)
}

pub type OptionType {
  Call
  Put
}

pub type OptionContract {
  OptionContract(
    strike: Float,
    maturity: String,
    underlying: Security,
    option_type: OptionType,
  )
}
