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
#' @param axis Which axis of the table's classification to fetch, `"input"`
#' (rows) or `"output"` (columns). No default -- must be specified: the two
#' return different sector sets (endogenous plus gross-value-added sectors
#' on the input axis, endogenous plus final-demand sectors on the output
#' axis), and even the shared endogenous sectors use different codes at the
#' `"basic"` tier.
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
  axis,
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  axis <- rlang::arg_match(axis, c("input", "output"))
  language <- rlang::arg_match(language)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    axis = axis,
    language = language,
    type = "sector"
  )
  tarchives::tar_get_archive_raw(
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
#' `sector_name_from`, `sector_class_to`, and `sector_name_to`.
#'
#' @export
io_sector_conversion_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  axis,
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  axis <- rlang::arg_match(axis, c("input", "output"))
  language <- rlang::arg_match(language)
  resolved <- io_sector_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    axis = axis,
    language = language,
    type = "sector_conversion"
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
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
#' correspondence has no published equivalent for. Passing `axis = "input"`
#' errors rather than silently ignoring the argument. `sector_name`
#' therefore only ever matches the output axis's [io_sector_get()]/
#' [io_sector_conversion_get()] output; joining it against the input axis's
#' returns zero matches (confirmed empirically: the two axes' basic-level
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
#' `sector_name`, `jsic_code`, `jsic_name`, `note` (`NA` except for sectors
#' split across multiple JSIC codes or vice versa), and `jsic_revision_year`
#' (the JSIC revision `jsic_code`/`jsic_name` are keyed to).
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
    language = language,
    type = "sector_jsic"
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  )
}
