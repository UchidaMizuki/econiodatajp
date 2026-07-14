#' Get an input-output table
#'
#' @param region_type Table "shape": `"regional"` for a single-region table
#' (see [econio::io_table_regional()]) or `"multiregional"` for a table with
#' an explicit region dimension (see [econio::io_table_multiregional()]).
#' @param region_class Region granularity: `"nation"` (the default) for the
#' single national table; `"pref"` for prefecture-level, either the
#' 47-prefecture interregional table (`region_type = "multiregional"`) or
#' one specific prefecture's own table (`region_type = "regional"`, see
#' `region`); or `"block"` for the official 9-region block interregional
#' table (`region_type = "multiregional"` only).
#' @param region Which single region to select within `region_class`. Only
#' applicable, and required, when `region_class = "pref"` and `region_type =
#' "regional"`, where it selects one prefecture -- a numeric prefecture code
#' (e.g. `1`, `13`) or the code_name fragment used in the archive (e.g.
#' `"01_hokkaido"`, `"13_tokyo"`). Must be `NULL` (the default) in every
#' other case: `region_class = "nation"` always covers the whole country,
#' and `region_class = "pref"`/`"block"` under `region_type =
#' "multiregional"` always cover every region in the breakdown at once --
#' there is no per-region subsetting there.
#' @param year Year of the data.
#' @param sector_class Sector classification granularity. No default --
#' must be specified. Choices depend on `region_class`: the full set
#' (`"basic"`, `"small"`, `"medium"`, `"large"`, `"template"`) for
#' `region_class = "nation"`; the only available value for one prefecture
#' (`"medium"`); the full choice set (`"coarse"`, `"medium"`, `"fine"`,
#' coarsest to finest) for `region_class = "block"`; or the only available
#' value for the `region_class = "pref"` interregional table (`"large"`).
#' @param price_type Price basis of the table, `"producer_price"` (the
#' default) or `"purchaser_price"`.
#' @param competitive_import Whether to use the competitive-import
#' convention (matches the `competitive_import` argument of
#' [econioread::io_table_read_sector_types()]). `"basic"` and `"small"`
#' sector classes are only available when `TRUE`. Only supported when
#' `region_class = "nation"`; `FALSE` errors otherwise.
#' @param language Language of the table's sector names, `"ja"` (the
#' default) or `"en"`. Japanese is the authoritative source (sector *type*
#' classification is derived from the Japanese sector classification
#' workbook); English names are pre-translated from it when each tarchive is
#' built (see `translate_iotable_sector()` in
#' `inst/tarchives/R/translate.R`), and a sector with no English source name
#' keeps its Japanese name. Only supported when `region_class = "nation"`;
#' a non-default value errors otherwise.
#'
#' @return An input-output table object for the specified year.
#'
#' @export
io_table_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  region = NULL,
  year,
  sector_class,
  price_type = c("producer_price", "purchaser_price"),
  competitive_import = TRUE,
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  price_type <- rlang::arg_match(price_type)
  language <- rlang::arg_match(language)
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
