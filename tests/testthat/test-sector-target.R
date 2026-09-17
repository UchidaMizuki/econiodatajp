test_that("io_sector_target_raw() requires axis", {
  expect_snapshot(
    io_sector_target_raw(
      "x",
      region_type = "regional",
      region_class = "nation",
      year = 2015
    ),
    error = TRUE
  )
})

test_that("io_sector_conversion_target_raw() requires axis", {
  expect_snapshot(
    io_sector_conversion_target_raw(
      "x",
      region_type = "regional",
      region_class = "nation",
      year = 2015
    ),
    error = TRUE
  )
})
