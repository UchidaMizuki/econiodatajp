test_that("io_sector_name_archive() builds sector/sector_conversion target names, region defaulting to nation", {
  expect_equal(
    io_sector_name_archive(axis = "input", type = "sector"),
    "sector_nation_input"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", type = "sector"),
    "sector_nation_output"
  )
  expect_equal(
    io_sector_name_archive(axis = "input", type = "sector_conversion"),
    "sector_conversion_nation_input"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", type = "sector_conversion"),
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

test_that("io_sector_name_archive() builds the sector_jsic target name from whatever axis it's given, same as sector/sector_conversion", {
  expect_equal(
    io_sector_name_archive(axis = "output", type = "sector_jsic"),
    "sector_jsic_nation_output"
  )
})

test_that("io_sector_name_archive() builds the jsic_conversion target name without the sector_ prefix, region defaulting to nation", {
  expect_equal(
    io_sector_name_archive(axis = "input", type = "jsic_conversion"),
    "jsic_conversion_nation"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", type = "jsic_conversion"),
    "jsic_conversion_nation"
  )
})

test_that("io_sector_parse_name_archive() round-trips a sector name", {
  parsed <- io_sector_parse_name_archive("sector_nation_input")
  expect_equal(parsed$type, "sector")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "input")
})

test_that("io_sector_parse_name_archive() round-trips a sector_conversion name", {
  parsed <- io_sector_parse_name_archive("sector_conversion_nation_output")
  expect_equal(parsed$type, "sector_conversion")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "output")
})

test_that("io_sector_parse_name_archive() round-trips a sector_jsic name with axis fixed to \"output\"", {
  parsed <- io_sector_parse_name_archive("sector_jsic_nation_output")
  expect_equal(parsed$type, "sector_jsic")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "output")
})

test_that("io_sector_parse_name_archive() round-trips a jsic_conversion name with no axis", {
  parsed <- io_sector_parse_name_archive("jsic_conversion_nation")
  expect_equal(parsed$type, "jsic_conversion")
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

test_that("io_sector_resolve() resolves type = \"sector_jsic\" the same way as sector/sector_conversion, given axis", {
  resolved <- io_sector_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2020,
    axis = "output",
    type = "sector_jsic"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2020")
  expect_equal(resolved$name, "sector_jsic_nation_output")
})

test_that("io_sector_resolve() doesn't require axis for type = \"jsic_conversion\"", {
  resolved <- io_sector_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2020,
    type = "jsic_conversion"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2020")
  expect_equal(resolved$name, "jsic_conversion_nation")
})

test_that("io_sector_parse_name_archive() drops non-matching names, including intermediate raw targets that share a root with a real archive name", {
  parsed <- io_sector_parse_name_archive(c(
    "sector_nation_input",
    "sector_jsic_nation_output",
    "jsic_conversion_nation",
    "sector_raw",
    "sector_jsic_raw",
    "jsic_class_raw",
    "file_sector_ja",
    "iotable_nation_basic_producer_price_competitive_import_ja"
  ))
  expect_setequal(
    parsed$name,
    c(
      "sector_nation_input",
      "sector_jsic_nation_output",
      "jsic_conversion_nation"
    )
  )
})
