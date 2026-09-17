test_that("io_margin_name_archive() defaults region to \"nation\"", {
  with_null <- io_margin_name_archive(
    region = NULL,
    margin_type = "trade_margin",
    sector_class = "medium",
    language = "ja"
  )
  expect_equal(with_null, "margin_nation_medium_trade_margin_ja")
})

test_that("io_margin_name_archive() takes an explicit region", {
  with_region <- io_margin_name_archive(
    region = "01_hokkaido",
    margin_type = "domestic_freight",
    sector_class = "medium",
    language = "en"
  )
  expect_equal(with_region, "margin_01_hokkaido_medium_domestic_freight_en")
})

test_that("io_margin_parse_name_archive() round-trips a trade_margin name", {
  parsed <- io_margin_parse_name_archive(
    "margin_nation_medium_trade_margin_ja"
  )
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$sector_class, "medium")
  expect_equal(parsed$margin_type, "trade_margin")
  expect_equal(parsed$language, "ja")
})

test_that("io_margin_parse_name_archive() round-trips a domestic_freight name", {
  parsed <- io_margin_parse_name_archive(
    "margin_nation_medium_domestic_freight_en"
  )
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$sector_class, "medium")
  expect_equal(parsed$margin_type, "domestic_freight")
  expect_equal(parsed$language, "en")
})

test_that("io_margin_parse_name_archive() drops non-matching names", {
  parsed <- io_margin_parse_name_archive(c(
    "margin_nation_medium_trade_margin_ja",
    "file_margin_nation_medium_trade_margin_ja",
    "iotable_nation_basic_producer_price_competitive_import_ja"
  ))
  expect_setequal(parsed$name, "margin_nation_medium_trade_margin_ja")
})

test_that("io_margin_resolve() passes region_type/region_class through instead of hardcoding them", {
  resolved <- io_margin_resolve(
    region_type = "regional",
    region_class = "nation",
    year = 2015,
    margin_type = "trade_margin",
    sector_class = "medium",
    language = "ja"
  )
  expect_equal(resolved$pipeline, "iotable-regional-nation-2015")
  expect_equal(resolved$name, "margin_nation_medium_trade_margin_ja")
})
