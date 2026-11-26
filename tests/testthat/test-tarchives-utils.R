test_that("download_file() keeps a file matching its extension", {
  utils <- source_tarchives_utils()
  source <- write_source_file(as.raw(c(0x50, 0x4b, 0x03, 0x04, 0x00)), "xlsx")
  destfile <- tempfile(fileext = ".xlsx")

  utils$download_file(file_url(source), destfile, quiet = TRUE)

  expect_equal(
    readBin(destfile, "raw", n = 4),
    as.raw(c(0x50, 0x4b, 0x03, 0x04))
  )
})

test_that("download_file() doesn't check files with other extensions", {
  utils <- source_tarchives_utils()
  source <- write_source_file(charToRaw("a,b\n1,2\n"), "csv")
  destfile <- tempfile(fileext = ".csv")

  utils$download_file(file_url(source), destfile, quiet = TRUE)

  expect_equal(readLines(destfile), c("a,b", "1,2"))
})

test_that("download_file() rejects an HTML page saved as a spreadsheet", {
  utils <- source_tarchives_utils()
  source <- write_source_file(
    charToRaw("<!DOCTYPE html>\n<html><body>Not found</body></html>"),
    "xlsx"
  )
  destfile <- tempfile(fileext = ".xlsx")

  expect_error(
    utils$download_file(file_url(source), destfile, quiet = TRUE),
    "HTML page",
    class = "econiodatajp_error_download"
  )
  expect_equal(file.exists(destfile), FALSE)
})

test_that("download_file() rejects a file of the wrong format", {
  utils <- source_tarchives_utils()
  source <- write_source_file(charToRaw("%PDF-1.7"), "xls")
  destfile <- tempfile(fileext = ".xls")

  expect_error(
    utils$download_file(file_url(source), destfile, quiet = TRUE),
    class = "econiodatajp_error_download"
  )
})

test_that("download_file() names the URL when the download fails", {
  utils <- source_tarchives_utils()
  url <- file_url(file.path(tempdir(), "missing{1}.xlsx"))

  expect_error(
    utils$download_file(url, tempfile(fileext = ".xlsx"), quiet = TRUE),
    "missing{1}.xlsx",
    fixed = TRUE,
    class = "econiodatajp_error_download"
  )
})
