#' Declare a target that reads an input-output table
#'
#' For use inside a `_targets.R` pipeline, e.g. `tar_plan(io_table_target(...))`.
#'
#' @param name Symbol, name of the target.
#' @inheritParams io_table_get
#' @param ... Arguments passed to [tarchives::tar_target_archive()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_table_target <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  region = NULL,
  year,
  sector_class,
  price_type = "producer_price",
  competitive_import = TRUE,
  language = c("ja", "en"),
  ...
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
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
  tarchives::tar_target_archive_raw(
    name = targets::tar_deparse_language(substitute(name)),
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    name_archive = resolved$name,
    ...
  )
}
