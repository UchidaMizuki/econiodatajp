test_that("io_sector_get() requires axis", {
  expect_snapshot(
    io_sector_get(
      region_type = "regional",
      region_class = "nation",
      year = 2015
    ),
    error = TRUE
  )
})

test_that("io_sector_conversion_get() requires axis", {
  expect_snapshot(
    io_sector_conversion_get(
      region_type = "regional",
      region_class = "nation",
      year = 2015
    ),
    error = TRUE
  )
})

test_that("io_sector_get() rejects an axis outside input/output", {
  expect_snapshot(
    io_sector_get(
      region_type = "regional",
      region_class = "nation",
      year = 2015,
      axis = "rows"
    ),
    error = TRUE
  )
})
