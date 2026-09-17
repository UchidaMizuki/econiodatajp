#' Declare a target that reads a trade margin or domestic freight table
#'
#' For use inside a `_targets.R` pipeline, e.g. `tar_plan(io_margin_target(...))`.
#' `io_margin_target()` uses non-standard evaluation to capture `name`, mirroring
#' [tarchives::tar_target_archive()]; `io_margin_target_raw()` takes `name` as a
#' string instead, for programmatic use such as building several targets in a
#' loop, mirroring [tarchives::tar_target_archive_raw()].
#'
#' @param name Symbol (`io_margin_target()`) or string (`io_margin_target_raw()`),
#' name of the target.
#' @inheritParams io_margin_get
#' @param ... Arguments passed to [tarchives::tar_target_archive_raw()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_margin_target <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  margin_type = c("trade_margin", "domestic_freight"),
  sector_class,
  language = c("ja", "en"),
  ...
) {
  io_margin_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    margin_type = margin_type,
    sector_class = sector_class,
    language = language,
    ...
  )
}

#' @rdname io_margin_target
#' @export
io_margin_target_raw <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  margin_type = c("trade_margin", "domestic_freight"),
  sector_class,
  language = c("ja", "en"),
  ...
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  margin_type <- rlang::arg_match(margin_type)
  language <- rlang::arg_match(language)
  resolved <- io_margin_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    margin_type = margin_type,
    sector_class = sector_class,
    language = language
  )
  tarchives::tar_target_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    name_archive = resolved$name,
    ...
  )
}
