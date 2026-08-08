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
#' @param region Which single region to select within `region_class`,
#' matching [io_table_get()]'s `region`. Defaults to `NULL`, which resolves
#' to `"nation"` -- as of writing, sector data only exists for `region_class
#' = "nation"` pipelines, so there's no other value to pass yet; the
#' argument exists so a future `region_class = "pref"`/`"block"` sector
#' archive (keyed per-prefecture/per-block the same way [io_table_get()]'s
#' tables are) wouldn't need a signature change to support it.
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
  region = NULL,
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
    region = region,
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
  region = NULL,
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
    region = region,
    axis = axis,
    type = "sector_conversion"
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
#' JSIC has been revised multiple times, and different benchmark years'
#' correspondence tables are keyed to different JSIC revisions (e.g. the
#' 2011 table uses the 2007 revision, while 2015/2020 use the 2013
#' revision); `jsic_revision_year` records which revision `jsic_code`/
#' `jsic_name` come from so results from different `year`s aren't compared
#' as if they used the same JSIC codes.
#'
#' Unlike [io_sector_get()]/[io_sector_conversion_get()], `axis` only ever
#' accepts `"output"`: the source only ever publishes this correspondence
#' keyed to the output/industry axis's basic-classification codes (its own
#' header calls the key a "column code"), and the input axis uses a
#' differently-grained code for basic industry sectors that this
#' correspondence has no published equivalent for. Passing `axis =
#' "input"` errors rather than silently ignoring the argument, and the
#' result's own `axis` column is always `"output"` too, so joining
#' `sector_name` against the wrong axis's [io_sector_get()]/
#' [io_sector_conversion_get()] output doesn't silently return zero matches
#' (confirmed empirically: every `sector_name` here matches the output
#' axis's and none match the input axis's, since the two axes' basic-level
#' sector codes -- and therefore `sector_name`, which embeds the code --
#' differ).
#'
#' @inheritParams io_sector_get
#' @param region_type,region_class Currently only `region_type = "regional"`,
#' `region_class = "nation"` tables have JSIC correspondence data; see
#' [io_sector_available] to confirm which `year`s do.
#' @param axis Always `"output"` -- see Details.
#'
#' @return A tibble with one row per IO-sector/JSIC-code pair, with columns
#' `sector_name`, `axis` (always `"output"`), `jsic_code`, `jsic_name`,
#' `note` (`NA` except for sectors split across multiple JSIC codes or vice
#' versa), and `jsic_revision_year` (the JSIC revision `jsic_code`/
#' `jsic_name` are keyed to).
#'
#' @export
io_sector_jsic_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  axis = c("output"),
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
    region = region,
    axis = axis,
    type = "sector_jsic"
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
      "axis",
      "jsic_code",
      "jsic_name",
      "note",
      "jsic_revision_year"
    )
}

#' Get the JSIC classification's own hierarchy crosswalk
#'
#' The official crosswalk between JSIC's own classification tiers --
#' industry ("detail", the finest, 4-digit) up to group (3-digit), major
#' group (2-digit), and division (a letter, the coarsest) -- as published
#' by 総務省 (MIC) as a standalone hierarchy file for a given JSIC
#' revision. Unlike [io_sector_jsic_get()], this has no connection to IO
#' sectors at all: it's JSIC's own internal structure, letting a
#' JSIC-coded value (e.g. from external establishment/employment
#' statistics) be rolled up to a coarser JSIC tier independently of any IO
#' table. Only returns Japanese names for now -- there's no `language`
#' argument yet, unlike most of this family -- even though an official
#' English source has since been found for this revision; see issue #31.
#'
#' JSIC has been revised multiple times; `jsic_revision_year` records which
#' revision a given row is keyed to, the same as [io_sector_jsic_get()]'s
#' column of the same name.
#'
#' @inheritParams io_sector_get
#' @param region_type,region_class Currently only `region_type =
#' "regional"`, `region_class = "nation"` pipelines carry this data, and not
#' for every `year` [io_sector_jsic_get()] covers -- e.g. no
#' machine-readable source was found for `year = 2011`'s JSIC revision as
#' of writing. See [io_sector_available] to confirm which `year`s do.
#'
#' @return A tibble with one row per industry-code/coarser-tier pair, with
#' columns `jsic_class_from` (always `"detail"`), `jsic_code_from`,
#' `jsic_name_from`, `jsic_class_to` (`"group"`, `"major_group"`, or
#' `"division"`), `jsic_code_to`, `jsic_name_to`, and `jsic_revision_year`.
#'
#' @export
io_jsic_conversion_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    type = "jsic_conversion"
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  )
}
