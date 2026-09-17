# io_margin_get() requires sector_class

    Code
      io_margin_get(region_type = "regional", region_class = "nation", year = 2015)
    Condition
      Error:
      ! Failed to evaluate glue component {sector_class}
      Caused by error in `io_margin_get()`:
      ! argument "sector_class" is missing, with no default

# io_margin_get() rejects a margin_type outside trade_margin/domestic_freight

    Code
      io_margin_get(region_type = "regional", region_class = "nation", year = 2015,
        margin_type = "commercial_margin", sector_class = "medium")
    Condition
      Error in `io_margin_get()`:
      ! `margin_type` must be one of "trade_margin" or "domestic_freight", not "commercial_margin".

