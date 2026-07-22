#' Get a sector classification
#'
#' The sector names and classification tiers (`"basic"`, `"small"`,
#' `"medium"`, `"large"`, `"template"`) that [io_table_get()]'s tables are
#' classified by. See [io_sector_conversion_get()] for the crosswalk between
#' tiers.
#'
#' @param region_type Table "shape" whose sector classification to fetch,
#' `"regional"` (the default) or `"multiregional"` -- see [io_table_get()].
#' @param region_class Region granularity whose sector classification to
#' fetch, `"nation"` (the default), `"pref"`, or `"block"` -- see
#' [io_table_get()]. Not every `region_type`/`region_class`/`year`
#' combination has sector data; see [io_sector_available] to list which do.
#' @param year Year of the data.
#' @param axis Which axis of the classification to fetch, `"input"` or
#' `"output"`. The two aren't identical: e-stat's classification workbook
#' omits a handful of industry codes (memo items such as scrap-material
#' rows) from the output side, so `axis = "output"` backfills them from the
#' input axis, matching how the real IO table labels those sectors
#' identically on both axes.
#'
#' @return A tibble with one row per sector, with columns `sector_type`,
#' `sector_class`, `sector_name_ja`, and `sector_name_en`.
#'
#' @export
io_sector_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output")
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
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    names = tidyselect::all_of(resolved$name)
  )
  tarchives::tar_read_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  )
}

#' Get a sector classification conversion table
#'
#' The crosswalk between sector classification tiers (`"basic"` ->
#' `"small"`/`"medium"`/`"large"`/`"template"`) that [io_table_get()] uses
#' internally to reclassify a table from its `"basic"` sector classification
#' to a coarser one. See [io_sector_get()] for the sector names and tiers
#' themselves.
#'
#' @inheritParams io_sector_get
#'
#' @return A tibble with one row per `sector_class_from`/`sector_class_to`
#' sector pair, with columns `sector_type`, `sector_class_from`,
#' `sector_class_to`, `sector_name_from`, and `sector_name_to`.
#'
#' @export
io_sector_conversion_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output")
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
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = resolved$pipeline,
    names = tidyselect::all_of(resolved$name)
  )
  tarchives::tar_read_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  )
}
