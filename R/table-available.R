#' List available input-output tables
#'
#' Introspects every tarchive pipeline bundled with the package and returns
#' one row per table it provides. Useful for discovering which arguments
#' [io_table_get()]/[io_table_target()] accept for a given `region_class`/
#' `year` -- in particular `sector_class`, whose choices for `region_class =
#' "block"` vary by `year` (FY2005 has three; every other year has one) and
#' so aren't listed in [io_table_get()]'s documentation.
#'
#' @return A data frame with one row per available table, with columns
#' `region_type`, `region_class`, `year`, `name` (the archive target name,
#' for [io_table_target()]'s `...`/`tarchives::tar_read_archive_raw()`),
#' `price_type`, `competitive_import`, `sector_class`, `language`, and
#' `region` (only non-`NA` for a `region_class = "pref"`, `region_type =
#' "regional"` table -- see [io_table_get()]'s `region`). Known gap: today
#' this omits `region_class = "pref"`, `region_type = "regional"` rows (one
#' per prefecture) -- their target names don't follow the naming scheme
#' this introspects (see `io_table_parse_name_archive()` in `R/utils.R`).
#'
#' @export
io_table_available <- function() {
  package <- "econiodatajp"
  pipelines <- tarchives::tar_archive_pipelines(package = package)
  pipeline_info <- io_table_parse_pipeline(pipelines)
  pipeline_info$pipeline <- pipelines

  pipeline_info |>
    purrr::pmap(function(pipeline, region_type, region_class, year) {
      manifest <- tarchives::tar_manifest_archive(
        package = package,
        pipeline = pipeline
      )
      io_table_parse_name_archive(manifest$name) |>
        dplyr::mutate(
          region_type = region_type,
          region_class = region_class,
          year = year,
          .before = 1
        )
    }) |>
    dplyr::bind_rows()
}
