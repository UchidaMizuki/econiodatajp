test_that("io_table_available data matches the live computation", {
  expect_equal(io_table_available, io_table_available_impl())
})
