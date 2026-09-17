test_that("io_sector_name_archive() builds sector/sector_conversion target names, region defaulting to nation", {
  expect_equal(
    io_sector_name_archive(axis = "input", language = "ja", type = "sector"),
    "sector_nation_input_ja"
  )
  expect_equal(
    io_sector_name_archive(axis = "output", language = "en", type = "sector"),
    "sector_nation_output_en"
  )
  expect_equal(
    io_sector_name_archive(
      axis = "input",
      language = "ja",
      type = "sector_conversion"
    ),
    "sector_conversion_nation_input_ja"
  )
  expect_equal(
    io_sector_name_archive(
      axis = "output",
      language = "en",
      type = "sector_conversion"
    ),
    "sector_conversion_nation_output_en"
  )
})

test_that("io_sector_name_archive() takes an explicit region", {
  expect_equal(
    io_sector_name_archive(
      region = "01_hokkaido",
      axis = "input",
      language = "ja",
      type = "sector"
    ),
    "sector_01_hokkaido_input_ja"
  )
})

test_that("io_sector_name_archive() builds the sector_jsic target name from whatever axis/language it's given, same as sector/sector_conversion", {
  expect_equal(
    io_sector_name_archive(
      axis = "output",
      language = "ja",
      type = "sector_jsic"
    ),
    "sector_jsic_nation_output_ja"
  )
  expect_equal(
    io_sector_name_archive(
      axis = "output",
      language = "en",
      type = "sector_jsic"
    ),
    "sector_jsic_nation_output_en"
  )
})

test_that("io_sector_parse_name_archive() round-trips a sector name", {
  parsed <- io_sector_parse_name_archive("sector_nation_input_ja")
  expect_equal(parsed$type, "sector")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "input")
  expect_equal(parsed$language, "ja")
})

test_that("io_sector_parse_name_archive() round-trips a sector_conversion name", {
  parsed <- io_sector_parse_name_archive("sector_conversion_nation_output_en")
  expect_equal(parsed$type, "sector_conversion")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "output")
  expect_equal(parsed$language, "en")
})

test_that("io_sector_parse_name_archive() round-trips a sector_jsic name with axis fixed to \"output\"", {
  parsed <- io_sector_parse_name_archive("sector_jsic_nation_output_ja")
  expect_equal(parsed$type, "sector_jsic")
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$axis, "output")
  expect_equal(parsed$language, "ja")
})

test_that("io_sector_parse_name_archive() round-trips a region other than nation", {
  parsed <- io_sector_parse_name_archive("sector_01_hokkaido_input_en")
  expect_equal(parsed$type, "sector")
  expect_equal(parsed$region, "01_hokkaido")
  expect_equal(parsed$axis, "input")
  expect_equal(parsed$language, "en")
})

test_that("io_sector_resolve() passes region_type/region_class through instead of hardcoding them", {
  resolved <- io_sector_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2020,
    axis = "input",
    language = "ja",
    type = "sector"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2020")
  expect_equal(resolved$name, "sector_nation_input_ja")
})

test_that("io_sector_resolve() resolves type = \"sector_jsic\" the same way as sector/sector_conversion, given axis and language", {
  resolved <- io_sector_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2020,
    axis = "output",
    language = "en",
    type = "sector_jsic"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2020")
  expect_equal(resolved$name, "sector_jsic_nation_output_en")
})

test_that("io_sector_parse_name_archive() drops non-matching names, including the bilingual intermediates each _ja/_en pair is split from", {
  parsed <- io_sector_parse_name_archive(c(
    "sector_nation_input_ja",
    "sector_jsic_nation_output_en",
    "sector_nation_input",
    "sector_conversion_nation_output",
    "sector_jsic_nation_output",
    "sector_raw",
    "sector_jsic_raw",
    "file_sector_ja",
    "iotable_nation_basic_producer_price_competitive_import_ja"
  ))
  expect_setequal(
    parsed$name,
    c(
      "sector_nation_input_ja",
      "sector_jsic_nation_output_en"
    )
  )
})
