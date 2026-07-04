#' Get the national input-output table
#'
#' @param year Year of the data.
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity.
#' @param competitive_import Whether to use the competitive-import
#' convention (matches the `competitive_import` argument of
#' [econioread::io_table_read_sector_types()]). `"basic"` and `"small"`
#' sector classes are only available when `TRUE`.
#' @param language Language of the table's sector names, `"ja"` or `"en"`.
#' Japanese is the authoritative source (sector *type* classification is
#' derived from the Japanese sector classification workbook); English names
#' are pre-translated from it when each tarchive is built (see
#' `translate_iotable_sector()` in `inst/tarchives/R/translate.R`), and a
#' sector with no English source name keeps its Japanese name. Defaults to
#' `NULL`, which resolves to `"en"` with a one-time message noting the
#' default.
#'
#' @return An input-output table object for the specified year.
#'
#' @export
io_table_regional_get_nation <- function(
  year,
  price_type = "producer_price",
  sector_class = c("basic", "small", "medium", "large", "template"),
  competitive_import = TRUE,
  language = NULL
) {
  sector_class <- rlang::arg_match(sector_class)
  language <- resolve_language(language)
  pipeline <- io_table_pipeline_nation(year)
  check_archive_pipeline("econiodatajp", pipeline)

  name <- io_table_name_archive(
    price_type = price_type,
    sector_class = sector_class,
    sector_class_choices = c("basic", "small", "medium", "large", "template"),
    competitive_import = competitive_import,
    language = language
  )
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = pipeline,
    names = tidyselect::all_of(name)
  )
  tarchives::tar_read_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = pipeline
  )
}

#' Get a prefectural input-output table
#'
#' @param year Year of the data.
#' @param pref Prefecture, either a numeric prefecture code (e.g. `1`, `13`)
#' or the code_name fragment used in the archive (e.g. `"01_hokkaido"`,
#' `"13_tokyo"`).
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity. Currently only
#' `"medium"` is available.
#'
#' @return An input-output table object for the specified year and
#' prefecture.
#'
#' @export
io_table_regional_get_pref <- function(
  year,
  pref,
  price_type = "producer_price",
  sector_class = "medium"
) {
  pipeline <- io_table_pipeline_pref(year)
  check_archive_pipeline("econiodatajp", pipeline)

  name <- resolve_pref_name_archive(
    "econiodatajp",
    pipeline,
    price_type = price_type,
    sector_class = sector_class,
    pref = pref
  )
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = pipeline,
    names = tidyselect::all_of(name)
  )
  tarchives::tar_read_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = pipeline
  )
}

#' Get the multiregional (interregional) input-output table
#'
#' Unlike [io_table_regional_get_pref()], this returns a single table
#' covering all prefectures at once, with region as a dimension of the
#' table itself (see [econio::io_region()]), rather than one table per
#' prefecture.
#'
#' @param year Year of the data.
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity. Currently only
#' `"large"` is available.
#'
#' @return A multiregional input-output table object for the specified year.
#'
#' @export
io_table_multiregional_get_pref <- function(
  year,
  price_type = "producer_price",
  sector_class = "large"
) {
  pipeline <- io_table_pipeline_multiregional_pref(year)
  check_archive_pipeline("econiodatajp", pipeline)

  name <- io_table_name_archive(
    price_type = price_type,
    sector_class = sector_class,
    sector_class_choices = "large",
    competitive_import = TRUE
  )
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = pipeline,
    names = tidyselect::all_of(name)
  )
  tarchives::tar_read_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = pipeline
  )
}
