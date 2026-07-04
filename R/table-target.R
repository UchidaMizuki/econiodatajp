#' Declare a target that reads the national input-output table
#'
#' For use inside a `_targets.R` pipeline, e.g.
#' `tar_plan(io_table_regional_target_nation(...))`.
#'
#' @param name Symbol, name of the target.
#' @param year Year of the data.
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity.
#' @param competitive_import Whether to use the competitive-import
#' convention (matches the `competitive_import` argument of
#' [econioread::io_table_read_sector_types()]). `"basic"` and `"small"`
#' sector classes are only available when `TRUE`.
#' @param language Language of the table's sector names, `"ja"` or `"en"`.
#' See [io_table_regional_get_nation()] for details. Defaults to `NULL`,
#' which resolves to `"en"` with a one-time message noting the default. This
#' selects between two precomputed archives (`_en`-suffixed or not) — it does
#' not translate at build time.
#' @param ... Arguments passed to [tarchives::tar_target_archive()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_table_regional_target_nation <- function(
  name,
  year,
  price_type = "producer_price",
  sector_class = c("basic", "small", "medium", "large", "template"),
  competitive_import = TRUE,
  language = NULL,
  ...
) {
  sector_class <- rlang::arg_match(sector_class)
  language <- resolve_language(language)
  pipeline <- io_table_pipeline_nation(year)
  check_archive_pipeline("econiodatajp", pipeline)

  name_archive <- io_table_name_archive(
    price_type = price_type,
    sector_class = sector_class,
    sector_class_choices = c("basic", "small", "medium", "large", "template"),
    competitive_import = competitive_import,
    language = language
  )
  tarchives::tar_target_archive_raw(
    name = targets::tar_deparse_language(substitute(name)),
    package = "econiodatajp",
    pipeline = pipeline,
    name_archive = name_archive,
    ...
  )
}

#' Declare a target that reads a prefectural input-output table
#'
#' For use inside a `_targets.R` pipeline, e.g.
#' `tar_plan(io_table_regional_target_pref(...))`.
#'
#' @param name Symbol, name of the target.
#' @param year Year of the data.
#' @param pref Prefecture, either a numeric prefecture code (e.g. `1`, `13`)
#' or the code_name fragment used in the archive (e.g. `"01_hokkaido"`,
#' `"13_tokyo"`).
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity. Currently only
#' `"medium"` is available.
#' @param ... Arguments passed to [tarchives::tar_target_archive()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_table_regional_target_pref <- function(
  name,
  year,
  pref,
  price_type = "producer_price",
  sector_class = "medium",
  ...
) {
  pipeline <- io_table_pipeline_pref(year)
  check_archive_pipeline("econiodatajp", pipeline)

  name_archive <- resolve_pref_name_archive(
    "econiodatajp",
    pipeline,
    price_type = price_type,
    sector_class = sector_class,
    pref = pref
  )
  tarchives::tar_target_archive_raw(
    name = targets::tar_deparse_language(substitute(name)),
    package = "econiodatajp",
    pipeline = pipeline,
    name_archive = name_archive,
    ...
  )
}

#' Declare a target that reads the multiregional (interregional) input-output table
#'
#' For use inside a `_targets.R` pipeline, e.g.
#' `tar_plan(io_table_multiregional_target_pref(...))`. Unlike
#' [io_table_regional_target_pref()], this reads a single table covering all
#' prefectures at once (see [io_table_multiregional_get_pref()]).
#'
#' @param name Symbol, name of the target.
#' @param year Year of the data.
#' @param price_type Price basis of the table. Currently only
#' `"producer_price"` is available.
#' @param sector_class Sector classification granularity. Currently only
#' `"large"` is available.
#' @param ... Arguments passed to [tarchives::tar_target_archive()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_table_multiregional_target_pref <- function(
  name,
  year,
  price_type = "producer_price",
  sector_class = "large",
  ...
) {
  pipeline <- io_table_pipeline_multiregional_pref(year)
  check_archive_pipeline("econiodatajp", pipeline)

  name_archive <- io_table_name_archive(
    price_type = price_type,
    sector_class = sector_class,
    sector_class_choices = "large",
    competitive_import = TRUE
  )
  tarchives::tar_target_archive_raw(
    name = targets::tar_deparse_language(substitute(name)),
    package = "econiodatajp",
    pipeline = pipeline,
    name_archive = name_archive,
    ...
  )
}
