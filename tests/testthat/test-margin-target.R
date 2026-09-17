test_that("io_margin_target_raw() requires sector_class", {
  expect_snapshot(
    io_margin_target_raw(
      "x",
      region_type = "regional",
      region_class = "nation",
      year = 2015
    ),
    error = TRUE
  )
})
