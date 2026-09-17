test_that("io_margin_get() requires sector_class", {
  expect_snapshot(
    io_margin_get(
      region_type = "regional",
      region_class = "nation",
      year = 2015
    ),
    error = TRUE
  )
})

test_that("io_margin_get() rejects a margin_type outside trade_margin/domestic_freight", {
  expect_snapshot(
    io_margin_get(
      region_type = "regional",
      region_class = "nation",
      year = 2015,
      margin_type = "commercial_margin",
      sector_class = "medium"
    ),
    error = TRUE
  )
})
