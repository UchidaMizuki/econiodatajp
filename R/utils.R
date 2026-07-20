# `region_class = "regional"`/`"block"` has no backing tarchive yet (see
# GitHub issue #5, which only covers the interregional table);
# `tarchives::tar_check_archive_pipeline()` gives a clear error in the
# meantime, so this naming scheme doesn't need to special-case it.
io_table_pipeline <- function(region_type, region_class, year) {
  stringr::str_glue("iotable-{region_type}-{region_class}-{year}")
}

# Shared by `io_table_get()`/`io_table_target()` so the region_class/region_type
# dispatch logic lives in exactly one place. `region` always resolves to
# *something* (see io_table_name_archive()'s `"nation"` default) -- every
# table covers some region, and "the whole nation as one scope" is itself a
# region, not an absence of one. No `region_class`/`region_type` branching
# decides whether `region` is "required": a caller who omits it for the one
# case that truly needs a specific value (`region_type = "regional"`,
# `region_class = "pref"`) gets `"nation"`, which never matches one of the
# 47 real per-prefecture archive names, so `tarchives::tar_check_archive_name()`
# reports its existing generic "can't find it, here's what's available"
# error (reading the pipeline's actual manifest), the same way
# `tarchives::tar_check_archive_pipeline()` already does for a whole missing
# pipeline (e.g. `region_class = "block"`, `region_type = "regional"`, which
# has no backing tarchive at all). `region` must already be the exact
# code_name fragment used in the archive (e.g. `"01_hokkaido"`) when it
# does need a specific value -- there's no numeric-code-to-name lookup here
# (that belongs to a future `jpcity`-based resolver, not this package).
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
# `sector_class`); it defaults to `"nation"` (never omitted, never a
# placeholder) for every table whose scope is the whole country --
# `region_class = "nation"`, and every `region_type = "multiregional"`
# table too, since being broken into prefecture/block *detail* internally
# is `region_class`, not a different `region` scope. A caller passing a
# stray `NA` isn't special-cased either: `%||%` only substitutes for
# `NULL`, so `NA` flows straight into the glue below as the literal text
# `"NA"`, which -- like `"nation"` misapplied to a `region_class = "pref"`
# request -- simply won't match a real archive and hits the same generic
# not-found error above. Every archive name always carries an explicit
# `_competitive_import`/`_noncompetitive_import` and `_ja`/`_en` suffix
# (never bare), so a tarchive target name alone is enough to tell which
# import convention and language it holds -- no archive needs to be
# assumed competitive-import or Japanese by omission. Each nation tarchive
# precomputes an `_en`-suffixed companion archive for every
# `iotable_nation_{sector_class}_{price_type}_{import_type}_ja` target
# (see `translate_iotable_sector()` in inst/tarchives/R/translate.R), so
# English is just a different archive name, not a runtime transformation.
io_table_name_archive <- function(
  region = NULL,
  sector_class,
  price_type,
  import_type,
  language
) {
  region <- region %||% "nation"
  stringr::str_glue(
    "iotable_{region}_{sector_class}_{price_type}_{import_type}_{language}"
  ) |>
    as.character()
}

# Reverses io_table_pipeline()'s naming scheme back into region_type/
# region_class/year, so io_table_available() can list what's on disk instead
# of a hardcoded set of pipelines. Vectorized: `pipeline` can be the full
# character vector from tar_archive_pipelines().
io_table_parse_pipeline <- function(pipeline) {
  matched <- stringr::str_match(
    pipeline,
    "^iotable-(regional|multiregional)-(nation|pref|block)-([0-9]+)$"
  )
  tibble::tibble(
    region_type = matched[, 2],
    region_class = matched[, 3],
    year = as.integer(matched[, 4])
  )
}

# Reverses io_table_name_archive()'s naming scheme back into region/
# sector_class/price_type/import_type/language, so io_table_available() can
# list what a pipeline actually defines instead of a hardcoded vocabulary.
# Vectorized: `name` can be a whole manifest's `$name` column. Every archive
# carries an explicit `_competitive_import`/`_noncompetitive_import` and
# `_ja`/`_en` suffix (see io_table_name_archive()), so both groups are
# mandatory here, not optional -- and so is the leading region group,
# since `region` defaults to `"nation"` rather than being omitted (see
# io_table_name_archive()), so `region` is never `NA` in the parsed output.
# The region group itself is deliberately `(.+)`, not a hardcoded shape
# like a 2-digit prefecture code -- a future region_class (e.g.
# municipalities, which use 5-digit codes) would look completely
# different, and this doesn't need to know that vocabulary. It relies
# only on `sector_class` being a single underscore-free token (`[^_]+`)
# immediately before the fixed `price_type`/`import_type`/`language`
# vocabulary that follows: greedy backtracking on `(.+)` finds the unique
# split point right before that final token, whatever `region` itself
# looks like (`"nation"`, `"01_hokkaido"`, or anything else).
#
# A pipeline's manifest also lists its non-table targets (e.g. the
# `tar_change()`-generated `file_...`/`file..._change` targets that
# download and track each source workbook); those don't match this naming
# scheme at all and are silently dropped rather than returned as NA rows.
io_table_parse_name_archive <- function(name) {
  matched <- stringr::str_match(
    name,
    "^iotable_(.+)_([^_]+)_(producer_price|purchaser_price)_((?:non)?competitive_import)_(ja|en)$"
  )
  tibble::tibble(
    region = matched[, 2],
    sector_class = matched[, 3],
    price_type = matched[, 4],
    import_type = matched[, 5],
    language = matched[, 6],
    name = matched[, 1]
  ) |>
    dplyr::filter(!is.na(name))
}
