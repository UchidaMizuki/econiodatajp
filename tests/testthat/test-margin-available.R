test_that("io_margin_available data matches the live computation", {
  expect_equal(io_margin_available, io_margin_available_impl())
})
