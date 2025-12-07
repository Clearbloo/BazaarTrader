import security.{type Security}

pub type Derivative {
  Option
  Future
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
