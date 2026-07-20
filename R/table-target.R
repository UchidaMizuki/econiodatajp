#' Declare a target that reads an input-output table
#'
#' For use inside a `_targets.R` pipeline, e.g. `tar_plan(io_table_target(...))`.
#' `io_table_target()` uses non-standard evaluation to capture `name`, mirroring
#' [tarchives::tar_target_archive()]; `io_table_target_raw()` takes `name` as a
#' string instead, for programmatic use such as building several targets in a
#' loop, mirroring [tarchives::tar_target_archive_raw()].
#'
#' @param name Symbol (`io_table_target()`) or string (`io_table_target_raw()`),
#' name of the target.
#' @inheritParams io_table_get
#' @param ... Arguments passed to [tarchives::tar_target_archive_raw()].
#'
#' @inherit tarchives::tar_target_archive return
#'
#' @export
io_table_target <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  sector_class,
  price_type = c("producer_price", "purchaser_price"),
  import_type = c("competitive_import", "noncompetitive_import"),
  language = c("ja", "en"),
  ...
) {
  io_table_target_raw(
    name = targets::tar_deparse_language(substitute(name)),
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    sector_class = sector_class,
    price_type = price_type,
    import_type = import_type,
    language = language,
    ...
  )
}

#' @rdname io_table_target
#' @export
io_table_target_raw <- function(
  name,
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  sector_class,
  price_type = c("producer_price", "purchaser_price"),
  import_type = c("competitive_import", "noncompetitive_import"),
  language = c("ja", "en"),
  ...
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
  tarchives::tar_target_archive_raw(
    name = name,
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    name_archive = resolved$name,
    ...
  )
}
