test_that("io_table_name_archive() defaults region to \"nation\"", {
  with_null <- io_table_name_archive(
    region = NULL,
    sector_class = "medium",
    price_type = "producer_price",
    import_type = "competitive_import",
    language = "ja"
  )
  expect_equal(
    with_null,
    "iotable_nation_medium_producer_price_competitive_import_ja"
  )
})

test_that("io_table_name_archive() does not special-case NA region", {
  with_na <- io_table_name_archive(
    region = NA_character_,
    sector_class = "medium",
    price_type = "producer_price",
    import_type = "competitive_import",
    language = "ja"
  )
  expect_equal(
    with_na,
    "iotable_NA_medium_producer_price_competitive_import_ja"
  )
})

test_that("io_table_parse_name_archive() round-trips a \"nation\" region", {
  parsed <- io_table_parse_name_archive(
    "iotable_nation_medium_producer_price_competitive_import_ja"
  )
  expect_equal(parsed$region, "nation")
  expect_equal(parsed$sector_class, "medium")
})

test_that("io_table_parse_name_archive() round-trips a per-prefecture region", {
  parsed <- io_table_parse_name_archive(
    "iotable_01_hokkaido_105_producer_price_competitive_import_ja"
  )
  expect_equal(parsed$region, "01_hokkaido")
  expect_equal(parsed$sector_class, "105")
})
