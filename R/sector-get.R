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
#' @param language Language of the sector names, `"ja"` (the default) or
#' `"en"`, matching [io_table_get()]'s `language`.
#'
#' @return A tibble with one row per sector, with columns `sector_type`,
#' `sector_class`, and `sector_name`.
#'
#' @export
io_sector_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output"),
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  axis <- rlang::arg_match(axis)
  language <- rlang::arg_match(language)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    axis = axis,
    type = "sector"
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  ) |>
    dplyr::select(
      "sector_type",
      "sector_class",
      sector_name = tidyselect::all_of(stringr::str_c("sector_name_", language))
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
#' `sector_name_from`, `sector_class_to`, and `sector_name_to`.
#'
#' @export
io_sector_conversion_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  axis = c("input", "output"),
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  axis <- rlang::arg_match(axis)
  language <- rlang::arg_match(language)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    axis = axis,
    type = "conversion"
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  ) |>
    dplyr::select(
      "sector_type",
      "sector_class_from",
      sector_name_from = tidyselect::all_of(stringr::str_c(
        "sector_name_from_",
        language
      )),
      "sector_class_to",
      sector_name_to = tidyselect::all_of(stringr::str_c(
        "sector_name_to_",
        language
      ))
    )
}
