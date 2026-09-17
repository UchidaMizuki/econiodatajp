# io_sector_get() requires axis

    Code
      io_sector_get(region_type = "regional", region_class = "nation", year = 2015)
    Condition
      Error in `io_sector_get()`:
      ! `axis` must be a character vector, not absent.

# io_sector_conversion_get() requires axis

    Code
      io_sector_conversion_get(region_type = "regional", region_class = "nation",
        year = 2015)
    Condition
      Error in `io_sector_conversion_get()`:
      ! `axis` must be a character vector, not absent.

# io_sector_get() rejects an axis outside input/output

    Code
      io_sector_get(region_type = "regional", region_class = "nation", year = 2015,
        axis = "rows")
    Condition
      Error in `io_sector_get()`:
      ! `axis` must be one of "input" or "output", not "rows".

