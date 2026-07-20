# The live computation behind the `io_table_available` data object shipped
# in `data/` (see `data-raw/io_table_available.R`). Kept as a separate,
# unexported function -- rather than inlined into the data-raw script --
# so `tests/testthat/test-table-available.R` can assert the shipped data
# still matches a fresh computation, catching a forgotten `data-raw`
# regeneration at `devtools::test()`/`devtools::check()` time instead of
# silently shipping stale data. Named `_impl` (not `io_table_available`)
# because that name is taken by the `data/` object itself -- a function
# and a data object can't share a name in the same package without one
# masking the other.
io_table_available_impl <- function() {
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
    dplyr::bind_rows() |>
    dplyr::arrange(dplyr::pick(!"name"))
}

#' List available input-output tables
#'
#' One row per table available via [io_table_get()]/[io_table_target()].
#' Useful for discovering which arguments they accept for a given
#' `region_class`/`year` -- in particular `sector_class`, whose choices for
#' `region_class = "block"` vary by `year` (FY2005 has three; every other
#' year has one) and so aren't listed in [io_table_get()]'s documentation.
#' Precomputed and shipped as package data (rather than a function) since
#' introspecting every tarchive pipeline is too slow to redo on every use --
#' including inside a `_targets.R` pipeline via
#' `tarchetypes::tar_eval(..., values = io_table_available)`, which
#' re-sources on every run and would otherwise pay that cost every time.
#'
#' @format A tibble with one row per available table, with columns
#' `region_type`, `region_class`, `year`, `region` (`"nation"` for every
#' table except a `region_class = "pref"`, `region_type = "regional"`
#' table, where it's a real per-prefecture code_name fragment, e.g.
#' `"01_hokkaido"` -- see [io_table_get()]'s `region`; never `NA`),
#' `sector_class`, `price_type`, `import_type`, `language`, and `name` (the
#' archive target name, for [io_table_target()]'s `...`/
#' `tarchives::tar_read_archive_raw()`).
#'
#' @source Computed from the tarchive pipelines bundled with this package
#' by `data-raw/io_table_available.R`; re-run that script and reinstall
#' whenever `inst/tarchives/` changes.
"io_table_available"
