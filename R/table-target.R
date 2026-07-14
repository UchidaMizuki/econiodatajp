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
  year,
  region_type = c("regional", "multiregional"),
  region = "nation",
  price_type = "producer_price",
  sector_class = NULL,
  region_class = NULL,
  competitive_import = TRUE,
  language = NULL,
  ...
) {
  region_type <- rlang::arg_match(region_type)
  resolved <- io_table_resolve(
    year = year,
    region_type = region_type,
    region = region,
    price_type = price_type,
    sector_class = sector_class,
    region_class = region_class,
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
