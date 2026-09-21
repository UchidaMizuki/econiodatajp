# The live computation behind the `io_margin_available` data object shipped
# in `data/` (see `data-raw/io_margin_available.R`). Kept as a separate,
# unexported function for the same reason as io_table_available_impl():
# `tests/testthat/test-margin-available.R` can assert the shipped data still
# matches a fresh computation, and the name can't collide with the `data/`
# object it backs.
#
# Scans every tarchive pipeline generically (via io_table_parse_pipeline(),
# shared with io_table_available_impl()/io_sector_available_impl()) rather
# than hardcoding `region_type = "regional"`/`region_class = "nation"`, even
# though those are the only pipelines with margin data today -- if a future
# pipeline ever gains its own `margin_*` targets, this picks them up without
# changes.
io_margin_available_impl <- function() {
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
      io_margin_parse_name_archive(manifest$name) |>
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

#' List available trade margin/transport margin tables
#'
#' One row per table available via [io_margin_get()]/[io_margin_target()].
#' Useful for discovering which `year`s have margin data at all (only
#' benchmark years up to 2015, see [io_margin_get()]) and which
#' `sector_class` each offers, rather than assuming `"medium"` is the only
#' one that will ever exist. Precomputed and shipped as package data for the
#' same reason as [io_table_available].
#'
#' @format A tibble with one row per available table, with columns
#' `region_type`, `region_class`, `year`, `region` (matching
#' [io_table_available]'s; always `"nation"` as of writing, since that's the
#' only `region_class` with margin data today), `sector_class`,
#' `margin_type` (`"trade_margin"` or `"transport_margin"`, matching
#' [io_margin_get()]'s `margin_type`), `language`, and `name` (the archive
#' target name, for [io_margin_target()]'s `...`/
#' `tarchives::tar_read_archive_raw()`).
#'
#' @source Computed from the tarchive pipelines bundled with this package
#' by `data-raw/io_margin_available.R`; re-run that script and reinstall
#' whenever `inst/tarchives/` changes.
"io_margin_available"
