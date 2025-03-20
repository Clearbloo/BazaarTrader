pub type Security {
  Stock(value: Float, mu: Float, std: Float, time: Float)
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
