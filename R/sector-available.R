# The live computation behind the `io_sector_available` data object shipped
# in `data/` (see `data-raw/io_sector_available.R`). Kept as a separate,
# unexported function -- rather than inlined into the data-raw script -- so
# `tests/testthat/test-sector-available.R` can assert the shipped data still
# matches a fresh computation, catching a forgotten `data-raw` regeneration
# at `devtools::test()`/`devtools::check()` time instead of silently
# shipping stale data. Named `_impl` (not `io_sector_available`) for the same
# reason as `io_table_available_impl()`: that name is taken by the `data/`
# object itself.
#
# Scans every tarchive pipeline generically (via io_table_parse_pipeline(),
# shared with io_table_available_impl()) rather than hardcoding
# `region_type = "regional"`/`region_class = "nation"`, even though those are
# the only pipelines with sector data today -- if a future pipeline ever
# gains its own `sector_*`/`sector_conversion_*` targets, this picks them up
# without changes.
io_sector_available_impl <- function() {
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
      io_sector_parse_name_archive(manifest$name) |>
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

#' List available sector classifications
#'
#' One row per sector classification, conversion, JSIC correspondence, or
#' JSIC-own-hierarchy table available via [io_sector_get()]/
#' [io_sector_conversion_get()]/[io_sector_jsic_get()]/
#' [io_jsic_conversion_get()]/[io_sector_target()]/
#' [io_sector_conversion_target()]/[io_sector_jsic_target()]/
#' [io_jsic_conversion_target()]. Useful for discovering which years
#' have sector data, since not every `io_table_get()` pipeline does.
#' Precomputed and shipped as package data (rather than a function) for the
#' same reason as [io_table_available]: introspecting every tarchive
#' pipeline is too slow to redo on every use.
#'
#' @format A tibble with one row per available sector table, with columns
#' `region_type`, `region_class`, `year`, `region` (matching
#' [io_table_available]'s; always `"nation"` as of writing, since that's the
#' only `region_class` with sector data today), `type` (the accessor
#' function it backs, `"sector"` for [io_sector_get()], `"sector_conversion"`
#' for [io_sector_conversion_get()], `"sector_jsic"` for
#' [io_sector_jsic_get()], or `"jsic_conversion"` for
#' [io_jsic_conversion_get()] -- always exactly `io_<type>_get()`'s
#' `<type>`), `axis` (`"input"` or `"output"`; always `"output"` for
#' `type = "sector_jsic"`, since [io_sector_jsic_get()]'s own `axis`
#' argument only ever accepts `"output"` -- a known, fixed fact about the
#' data, not a real choice; `NA` for `type = "jsic_conversion"`, which has
#' no connection to an IO table's axis at all), and `name` (the archive
#' target name, for [io_sector_target()]'s
#' / [io_sector_conversion_target()]'s / [io_sector_jsic_target()]'s /
#' [io_jsic_conversion_target()]'s
#' `...`/ `tarchives::tar_read_archive_raw()` -- derivable from `region`/
#' `type`/`axis` via the same logic [io_sector_get()]'s family uses
#' internally, see `io_sector_name_archive()`).
#'
#' @source Computed from the tarchive pipelines bundled with this package
#' by `data-raw/io_sector_available.R`; re-run that script and reinstall
#' whenever `inst/tarchives/` changes.
"io_sector_available"
