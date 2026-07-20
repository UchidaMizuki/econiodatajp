# `region_class = "regional"`/`"block"` has no backing tarchive yet (see
# GitHub issue #5, which only covers the interregional table);
# `tarchives::tar_check_archive_pipeline()` gives a clear error in the
# meantime, so this naming scheme doesn't need to special-case it.
io_table_pipeline <- function(region_type, region_class, year) {
  stringr::str_glue("iotable-{region_type}-{region_class}-{year}")
}

# Shared by `io_table_get()`/`io_table_target()` so the region_class/region_type
# dispatch logic lives in exactly one place. Whether `region` is needed to pick
# a single table out of a pipeline (e.g. one prefecture's own table among
# `iotable-regional-pref-*`'s per-prefecture targets) isn't hardcoded against
# `region_type`/`region_class` here -- it falls directly out of whether the
# caller passed `region`, which `io_table_name_archive()` folds into the
# name (or not) on its own. `region` must already be the exact code_name
# fragment used in the archive (e.g. `"01_hokkaido"`) -- there's no
# numeric-code-to-name lookup here (that belongs to a future
# `jpcity`-based resolver, not this package). `tarchives::tar_check_archive_name()`
# reports a generic "can't find it, here's what's available" error
# (reading the pipeline's actual manifest) when that guess doesn't match
# anything, the same way `tarchives::tar_check_archive_pipeline()` already
# does for a whole missing pipeline (e.g. `region_class = "block"`,
# `region_type = "regional"`, which has no backing tarchive at all).
io_table_resolve <- function(
  region_type,
  region_class,
  year,
  region,
  sector_class,
  price_type,
  import_type,
  language
) {
  package <- "econiodatajp"
  pipeline <- io_table_pipeline(region_type, region_class, year)
  tarchives::tar_check_archive_pipeline(pipeline, package = package)

  name <- io_table_name_archive(
    region = region,
    sector_class = sector_class,
    price_type = price_type,
    import_type = import_type,
    language = language
  )
  tarchives::tar_check_archive_name(
    name,
    package = package,
    pipeline = pipeline
  )

  list(pipeline = pipeline, name = name)
}

# Doesn't validate `sector_class` itself -- valid choices vary by pipeline
# (nation: basic/small/medium/large/template; block/RIETI-pref: sector
# counts that differ by year/region, see io_table_resolve()) and there's no
# single vocabulary to check against here. io_table_resolve() validates the
# *result* instead, via tarchives::tar_check_archive_name(). Every caller
# passes `import_type`/`language` straight through rather than hardcoding
# `"competitive_import"`/`"ja"` for pref/block -- those archives don't have
# a noncompetitive-import variant today, so a non-default request there
# simply builds a name that tar_check_archive_name() won't find, the same
# generic failure as any other not-yet-published archive. `region` leads
# the name (rather than trailing it) so the naming grammar's token order
# matches `io_table_get()`'s own argument order (`region` before
# `sector_class`); it's simply omitted, not replaced by a placeholder,
# when `NULL` (`region_class = "nation"`, or any `region_type =
# "multiregional"` table) -- `io_table_parse_name_archive()`'s matching
# leading-region group is optional for the same reason. Every archive name
# always carries an explicit `_competitive_import`/`_noncompetitive_import`
# and `_ja`/`_en` suffix (never bare), so a tarchive target name alone is
# enough to tell which import convention and language it holds -- no
# archive needs to be assumed competitive-import or Japanese by omission.
# Each nation tarchive precomputes an `_en`-suffixed companion archive for
# every `iotable_{sector_class}_{price_type}_{import_type}_ja` target (see
# `translate_iotable_sector()` in inst/tarchives/R/translate.R), so English
# is just a different archive name, not a runtime transformation.
io_table_name_archive <- function(
  region = NULL,
  sector_class,
  price_type,
  import_type,
  language
) {
  region_prefix <- if (is.null(region)) "" else stringr::str_glue("{region}_")
  stringr::str_glue(
    "iotable_{region_prefix}{sector_class}_{price_type}_{import_type}_{language}"
  ) |>
    as.character()
}

# Reverses io_table_pipeline()'s naming scheme back into region_type/
# region_class/year, so io_table_available() can list what's on disk instead
# of a hardcoded set of pipelines. Vectorized: `pipeline` can be the full
# character vector from tar_archive_pipelines().
io_table_parse_pipeline <- function(pipeline) {
  m <- stringr::str_match(
    pipeline,
    "^iotable-(regional|multiregional)-(nation|pref|block)-([0-9]+)$"
  )
  data.frame(
    region_type = m[, 2],
    region_class = m[, 3],
    year = as.integer(m[, 4]),
    stringsAsFactors = FALSE
  )
}

# Reverses io_table_name_archive()'s naming scheme back into region/
# sector_class/price_type/import_type/language, so io_table_available() can
# list what a pipeline actually defines instead of a hardcoded vocabulary.
# Vectorized: `name` can be a whole manifest's `$name` column. Every archive
# carries an explicit `_competitive_import`/`_noncompetitive_import` and
# `_ja`/`_en` suffix (see io_table_name_archive()), so both groups are
# mandatory here, not optional; the leading `_{pref_code}_{pref_name}`
# region group is the only optional one, since only
# `iotable-regional-pref-*` archives (one selected by `region` in
# io_table_get()) have it -- `region` stays a plain column here for every
# other target, which never has one (always `NA`), rather than being
# dropped entirely.
#
# A pipeline's manifest also lists its non-table targets (e.g. the
# `tar_change()`-generated `file_...`/`file..._change` targets that
# download and track each source workbook); those don't match this naming
# scheme at all and are silently dropped rather than returned as NA rows.
io_table_parse_name_archive <- function(name) {
  m <- stringr::str_match(
    name,
    "^iotable_(?:([0-9]{2})_([a-z]+)_)?([^_]+)_(producer_price|purchaser_price)_((?:non)?competitive_import)_(ja|en)$"
  )
  data.frame(
    region = dplyr::if_else(
      is.na(m[, 2]),
      NA_character_,
      stringr::str_c(m[, 2], "_", m[, 3])
    ),
    sector_class = m[, 4],
    price_type = m[, 5],
    import_type = m[, 6],
    language = m[, 7],
    name = m[, 1],
    stringsAsFactors = FALSE
  ) |>
    dplyr::filter(!is.na(name))
}
