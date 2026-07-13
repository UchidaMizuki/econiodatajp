#' Get an input-output table
#'
#' @param year Year of the data.
#' @param region_type Table "shape": `"regional"` for a single-region table
#' (see [econio::io_table_regional()]) or `"multiregional"` for a table with
#' an explicit region dimension (see [econio::io_table_multiregional()]).
#' `region_type` selects the table's shape; `region_class` (below) selects
#' the region breakdown used within a `"multiregional"` table.
#' @param area Which area the table covers. `"nation"` (the default), `0`,
#' and `"00"` all mean nation-level; any other value is a prefecture, either
#' a numeric prefecture code (e.g. `1`, `13`) or the code_name fragment used
#' in the archive (e.g. `"01_hokkaido"`, `"13_tokyo"`). Must resolve to
#' nation-level when `region_type = "multiregional"` (that table always
#' covers every region in its breakdown at once — there is no
#' per-region subsetting).
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity. Defaults to the
#' full choice set (`"basic"`, `"small"`, `"medium"`, `"large"`,
#' `"template"`) when `area` is nation-level; the only available value for a
#' prefecture (`"medium"`); the full choice set (`"small"`, `"medium"`,
#' `"large"`, coarsest to finest) for `region_class = "block"`; or the only
#' available value for `region_class = "pref"` (`"large"`).
#' @param region_class Region breakdown used within a `"multiregional"`
#' table: `"pref"` (the default) for the 47-prefecture interregional table,
#' or `"block"` for the official 9-region block interregional table.
#' Ignored when `region_type = "regional"`; a non-default value errors in
#' that case.
#' @param competitive_import Whether to use the competitive-import
#' convention (matches the `competitive_import` argument of
#' [econioread::io_table_read_sector_types()]). `"basic"` and `"small"`
#' sector classes are only available when `TRUE`. Only supported when `area`
#' is nation-level; `FALSE` errors otherwise.
#' @param language Language of the table's sector names, `"ja"` or `"en"`.
#' Japanese is the authoritative source (sector *type* classification is
#' derived from the Japanese sector classification workbook); English names
#' are pre-translated from it when each tarchive is built (see
#' `translate_iotable_sector()` in `inst/tarchives/R/translate.R`), and a
#' sector with no English source name keeps its Japanese name. Defaults to
#' `NULL`, which resolves to `"en"` with a one-time message noting the
#' default. Only supported when `area` is nation-level; a non-`NULL` value
#' errors otherwise.
#'
#' @return An input-output table object for the specified year.
#'
#' @export
io_table_get <- function(
  year,
  region_type = c("regional", "multiregional"),
  area = "nation",
  price_type = "producer_price",
  sector_class = NULL,
  region_class = c("pref", "block"),
  competitive_import = TRUE,
  language = NULL
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  resolved <- io_table_resolve(
    year = year,
    region_type = region_type,
    area = area,
    price_type = price_type,
    sector_class = sector_class,
    region_class = region_class,
    competitive_import = competitive_import,
    language = language
  )
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    names = tidyselect::all_of(resolved$name)
  )
  tarchives::tar_read_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  )
}
