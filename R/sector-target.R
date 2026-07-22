#' Declare a target that reads a sector classification
#'
#' For use inside a `_targets.R` pipeline, e.g. `tar_plan(io_sector_target(...))`.
#' `io_sector_target()` uses non-standard evaluation to capture `name`, mirroring
#' [tarchives::tar_target_archive()]; `io_sector_target_raw()` takes `name` as a
#' string instead, for programmatic use such as building several targets in a
#' loop, mirroring [tarchives::tar_target_archive_raw()].
#'
#' @param name Symbol (`io_sector_target()`) or string (`io_sector_target_raw()`),
#' name of the target.
#' @inheritParams io_sector_get
#' @param ... Arguments passed to [tarchives::tar_target_archive_raw()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_sector_target <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output"),
  ...
) {
  io_sector_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    region_type = region_type,
    region_class = region_class,
    year = year,
    axis = axis,
    ...
  )
}

#' @rdname io_sector_target
#' @export
io_sector_target_raw <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output"),
  ...
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  axis <- rlang::arg_match(axis)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    axis = axis,
    type = "sector"
  )
  tarchives::tar_target_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    name_archive = resolved$name,
    ...
  )
}

#' Declare a target that reads a sector classification conversion table
#'
#' For use inside a `_targets.R` pipeline, e.g.
#' `tar_plan(io_sector_conversion_target(...))`. `io_sector_conversion_target()`
#' uses non-standard evaluation to capture `name`, mirroring
#' [tarchives::tar_target_archive()]; `io_sector_conversion_target_raw()` takes
#' `name` as a string instead, for programmatic use such as building several
#' targets in a loop, mirroring [tarchives::tar_target_archive_raw()].
#'
#' @param name Symbol (`io_sector_conversion_target()`) or string
#' (`io_sector_conversion_target_raw()`), name of the target.
#' @inheritParams io_sector_get
#' @param ... Arguments passed to [tarchives::tar_target_archive_raw()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_sector_conversion_target <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output"),
  ...
) {
  io_sector_conversion_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    region_type = region_type,
    region_class = region_class,
    year = year,
    axis = axis,
    ...
  )
}

#' @rdname io_sector_conversion_target
#' @export
io_sector_conversion_target_raw <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output"),
  ...
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  axis <- rlang::arg_match(axis)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    axis = axis,
    type = "conversion"
  )
  tarchives::tar_target_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    name_archive = resolved$name,
    ...
  )
}
