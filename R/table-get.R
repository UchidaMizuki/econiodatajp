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
#' @param year Year of the data.
#' @param region Which single region to select within `region_class`. Only
#' applicable, and required, when `region_class = "pref"` and `region_type =
#' "regional"`, where it selects one prefecture by the code_name fragment
#' used in the archive (e.g. `"01_hokkaido"`, `"13_tokyo"` -- see
#' [io_table_available()] to list them). Must be `NULL` (the default) in
#' every other case: `region_class = "nation"` always covers the whole
#' country, and `region_class = "pref"`/`"block"` under `region_type =
#' "multiregional"` always cover every region in the breakdown at once --
#' there is no per-region subsetting there.
#' @param sector_class Sector classification granularity. No default --
#' must be specified. For `region_class = "nation"`, the full set
#' (`"basic"`, `"small"`, `"medium"`, `"large"`, `"template"`) -- each a
#' direct translation of a real official Japanese classification tier
#' name. No official documentation gives a common tier name to the
#' `region_class = "pref"` or `"block"` tables' sector granularities, only
#' their sector counts, so `sector_class` there is that count as a string
#' instead: for `region_class = "pref"` with `region_type = "regional"`
#' (one prefecture's own table), each prefecture publishes its own count
#' (e.g. `"105"` for Hokkaido, `"187"` for Osaka); for `region_class =
#' "pref"` with `region_type = "multiregional"` (the interregional table),
#' the count varies by `year` (`"26"` for `year = 2005`, `"31"` for `year =
#' 2011`); for `region_class = "block"`, the count varies by `year` too
#' (`"12"`/`"29"`/`"53"` for `year = 2005`; a single year-specific count
#' otherwise) -- see [io_table_available()] to list them all.
#' @param price_type Price basis of the table, `"producer_price"` (the
#' default) or `"purchaser_price"`.
#' @param import_type Import convention used in the table,
#' `"competitive_import"` (the default) or `"noncompetitive_import"`
#' (matches `competitive_import = TRUE`/`FALSE` in
#' [econioread::io_table_read_sector_types()]). `"basic"` and `"small"`
#' sector classes are only available for `"competitive_import"`. Only
#' `"competitive_import"` is supported when `region_class` isn't
#' `"nation"`.
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
  year,
  region = NULL,
  sector_class,
  price_type = c("producer_price", "purchaser_price"),
  import_type = c("competitive_import", "noncompetitive_import"),
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  price_type <- rlang::arg_match(price_type)
  import_type <- rlang::arg_match(import_type)
  language <- rlang::arg_match(language)
  resolved <- io_table_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    sector_class = sector_class,
    price_type = price_type,
    import_type = import_type,
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
