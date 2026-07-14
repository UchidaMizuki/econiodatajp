#' Get an input-output table
#'
#' @param region_type Table "shape": `"regional"` for a single-region table
#' (see [econio::io_table_regional()]) or `"multiregional"` for a table with
#' an explicit region dimension (see [econio::io_table_multiregional()]).
#' `region_type` selects the table's shape; `region_class` (below) selects
#' the region breakdown used within a `"multiregional"` table.
#' @param region_class Region breakdown used within a `"multiregional"`
#' table: `"pref"` for the 47-prefecture interregional table, or `"block"`
#' for the official 9-region block interregional table. No default -- must
#' be specified when `region_type = "multiregional"`. Must be `NULL` (the
#' default) when `region_type = "regional"`; a non-`NULL` value errors in
#' that case.
#' @param region Which region the table covers. `"nation"` (the default),
#' `0`, and `"00"` all mean nation-level; any other value is a prefecture,
#' either a numeric prefecture code (e.g. `1`, `13`) or the code_name
#' fragment used in the archive (e.g. `"01_hokkaido"`, `"13_tokyo"`). Must
#' resolve to nation-level when `region_type = "multiregional"` (that table
#' always covers every region in its breakdown at once — there is no
#' per-region subsetting). This selects a single administrative unit; it is
#' a different axis from `region_class` (which selects the breakdown
#' *scheme* for a `"multiregional"` table). A future feature that subsets a
#' `"multiregional"` table's breakdown would use a separate argument (e.g.
#' `subregion`) rather than overloading `region`.
#' @param year Year of the data.
#' @param sector_class Sector classification granularity. Defaults to the
#' full choice set (`"basic"`, `"small"`, `"medium"`, `"large"`,
#' `"template"`) when `region` is nation-level; the only available value for
#' a prefecture (`"medium"`); the full choice set (`"coarse"`, `"medium"`,
#' `"fine"`, coarsest to finest) for `region_class = "block"`; or the only
#' available value for `region_class = "pref"` (`"large"`).
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param competitive_import Whether to use the competitive-import
#' convention (matches the `competitive_import` argument of
#' [econioread::io_table_read_sector_types()]). `"basic"` and `"small"`
#' sector classes are only available when `TRUE`. Only supported when
#' `region` is nation-level; `FALSE` errors otherwise.
#' @param language Language of the table's sector names, `"ja"` or `"en"`.
#' Japanese is the authoritative source (sector *type* classification is
#' derived from the Japanese sector classification workbook); English names
#' are pre-translated from it when each tarchive is built (see
#' `translate_iotable_sector()` in `inst/tarchives/R/translate.R`), and a
#' sector with no English source name keeps its Japanese name. Defaults to
#' `NULL`, which resolves to `"en"` with a one-time message noting the
#' default. Only supported when `region` is nation-level; a non-`NULL` value
#' errors otherwise.
#'
#' @return An input-output table object for the specified year.
#'
#' @export
io_table_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = NULL,
  region = "nation",
  year,
  sector_class = NULL,
  price_type = "producer_price",
  competitive_import = TRUE,
  language = NULL
) {
  region_type <- rlang::arg_match(region_type)
  resolved <- io_table_resolve(
    region_type = region_type,
    region_class = region_class,
    region = region,
    year = year,
    sector_class = sector_class,
    price_type = price_type,
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
