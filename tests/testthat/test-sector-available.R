test_that("io_sector_available data matches the live computation", {
  expect_equal(io_sector_available, io_sector_available_impl())
})
