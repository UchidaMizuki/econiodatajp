test_that("io_sector_name_archive() builds sector/conversion target names", {
  expect_equal(io_sector_name_archive("input", "sector"), "sector_input")
  expect_equal(io_sector_name_archive("output", "sector"), "sector_output")
  expect_equal(
    io_sector_name_archive("input", "conversion"),
    "sector_conversion_input"
  )
  expect_equal(
    io_sector_name_archive("output", "conversion"),
    "sector_conversion_output"
  )
})

test_that("io_sector_parse_name_archive() round-trips a sector name", {
  parsed <- io_sector_parse_name_archive("sector_input")
  expect_equal(parsed$type, "sector")
  expect_equal(parsed$axis, "input")
})

test_that("io_sector_parse_name_archive() round-trips a conversion name", {
  parsed <- io_sector_parse_name_archive("sector_conversion_output")
  expect_equal(parsed$type, "conversion")
  expect_equal(parsed$axis, "output")
})

test_that("io_sector_resolve() passes region_type/region_class through instead of hardcoding them", {
  resolved <- io_sector_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2020,
    axis = "input",
    type = "sector"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2020")
  expect_equal(resolved$name, "sector_input")
})

test_that("io_sector_parse_name_archive() drops non-matching names", {
  parsed <- io_sector_parse_name_archive(c(
    "sector_input",
    "sector_raw",
    "file_sector_ja",
    "iotable_nation_basic_producer_price_competitive_import_ja"
  ))
  expect_equal(parsed$name, "sector_input")
})
