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

#' Get the correspondence between IO sectors and JSIC
#'
#' The official crosswalk between a table's basic-classification industry
#' sectors and the Japan Standard Industrial Classification (JSIC), as
#' published by e-stat/MIC alongside a benchmark year's sector
#' classification. The correspondence is many-to-many: some IO sectors map
#' to several JSIC codes, and some JSIC codes are themselves split across
#' several IO sectors, in which case `note` carries the source's own
#' description of the split (e.g. `"うち麦類"`, "of which: wheat"). JSIC
#' names and notes are Japanese-only in the source and have no English
#' variant; only `sector_name` is translated by `language`.
#'
#' Unlike [io_sector_get()]/[io_sector_conversion_get()], there's no `axis`
#' argument: the source only ever publishes this correspondence keyed to the
#' output/industry axis's basic-classification codes (its own header calls
#' the key a "column code"), and the input axis uses a differently-grained
#' code for basic industry sectors that this correspondence has no published
#' equivalent for.
#'
#' @inheritParams io_sector_get
#' @param region_type,region_class Currently only `region_type = "regional"`,
#' `region_class = "nation"` tables have JSIC correspondence data; see
#' [io_sector_available] to confirm which `year`s do.
#'
#' @return A tibble with one row per IO-sector/JSIC-code pair, with columns
#' `sector_name`, `jsic_code`, `jsic_name`, and `note` (`NA` except for
#' sectors split across multiple JSIC codes or vice versa).
#'
#' @export
io_sector_jsic_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  language <- rlang::arg_match(language)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    type = "jsic"
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  ) |>
    dplyr::select(
      sector_name = tidyselect::all_of(stringr::str_c(
        "sector_name_",
        language
      )),
      "jsic_code",
      "jsic_name",
      "note"
    )
}
