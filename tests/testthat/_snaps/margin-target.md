# io_margin_target_raw() requires sector_class

    Code
      io_margin_target_raw("x", region_type = "regional", region_class = "nation",
        year = 2015)
    Condition
      Error:
      ! Failed to evaluate glue component {sector_class}
      Caused by error in `io_margin_target_raw()`:
      ! argument "sector_class" is missing, with no default

