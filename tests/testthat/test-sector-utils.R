test_that("io_sector_name_archive() builds sector/conversion target names, region defaulting to nation", {
  expect_equal(
    io_sector_name_archive(axis = "input", type = "sector"),
    "sector_nation_input"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", type = "sector"),
    "sector_nation_output"
  )
  expect_equal(
    io_sector_name_archive(axis = "input", type = "conversion"),
    "sector_conversion_nation_input"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", type = "conversion"),
    "sector_conversion_nation_output"
  )
})

test_that("io_sector_name_archive() takes an explicit region", {
  expect_equal(
    io_sector_name_archive(
      region = "01_hokkaido",
      axis = "input",
      type = "sector"
    ),
    "sector_01_hokkaido_input"
  )
})

test_that("io_sector_name_archive() builds the jsic target name without an axis, region defaulting to nation", {
  expect_equal(
    io_sector_name_archive(axis = "input", type = "jsic"),
    "sector_jsic_nation"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", type = "jsic"),
    "sector_jsic_nation"
  )
})

test_that("io_sector_parse_name_archive() round-trips a sector name", {
  parsed <- io_sector_parse_name_archive("sector_nation_input")
  expect_equal(parsed$type, "sector")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "input")
})

test_that("io_sector_parse_name_archive() round-trips a conversion name", {
  parsed <- io_sector_parse_name_archive("sector_conversion_nation_output")
  expect_equal(parsed$type, "conversion")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "output")
})

test_that("io_sector_parse_name_archive() round-trips a jsic name with no axis", {
  parsed <- io_sector_parse_name_archive("sector_jsic_nation")
  expect_equal(parsed$type, "jsic")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, NA_character_)
})

test_that("io_sector_parse_name_archive() round-trips a region other than nation", {
  parsed <- io_sector_parse_name_archive("sector_01_hokkaido_input")
  expect_equal(parsed$type, "sector")
  expect_equal(parsed$region, "01_hokkaido")
  expect_equal(parsed$axis, "input")
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
  expect_equal(resolved$name, "sector_nation_input")
})

test_that("io_sector_resolve() doesn't require axis for type = \"jsic\"", {
  resolved <- io_sector_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2020,
    type = "jsic"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2020")
  expect_equal(resolved$name, "sector_jsic_nation")
})

test_that("io_sector_parse_name_archive() drops non-matching names", {
  parsed <- io_sector_parse_name_archive(c(
    "sector_nation_input",
    "sector_jsic_nation",
    "sector_raw",
    "file_sector_ja",
    "iotable_nation_basic_producer_price_competitive_import_ja"
  ))
  expect_setequal(parsed$name, c("sector_nation_input", "sector_jsic_nation"))
})
