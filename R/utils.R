io_table_pipeline_regional_nation <- function(year) {
  stringr::str_glue("iotable-regional-nation-{year}")
}

io_table_pipeline_regional_pref <- function(year) {
  stringr::str_glue("iotable-regional-pref-{year}")
}

# No backing tarchive exists (see GitHub issue #5's `region_class = "block"`
# discussion, which only covers the interregional table); this pipeline
# name exists so a single block's own table -- if that data ever gets
# published and added -- has a natural place to slot in, without needing a
# dedicated "not supported" error today. `check_archive_pipeline()` gives a
# clear error in the meantime.
io_table_pipeline_regional_block <- function(year) {
  stringr::str_glue("iotable-regional-block-{year}")
}

# Named `..._pref_nation()` rather than `..._pref()` because "nation" here
# is doing the same job `region` does for `io_table_pipeline_regional_*()`
# -- it's not `region_class` (that's `pref`), it's *which* member of that
# granularity this table covers, and today that's always "every
# prefecture at once" ("nation"), since there's no per-region subsetting
# yet. It therefore slots in after `region_class`, the same position
# `region` would take, so a future partial-region table can slot its own
# qualifier in right beside it without renaming this one.
io_table_pipeline_multiregional_pref_nation <- function(year) {
  stringr::str_glue("iotable-multiregional-pref-nation-{year}")
}

# No backing tarchive exists yet (see GitHub issue #5); `check_archive_pipeline()`
# in the `region_class == "block"` branch of `io_table_resolve()` gives a clear
# error until one is added.
io_table_pipeline_multiregional_block_nation <- function(year) {
  stringr::str_glue("iotable-multiregional-block-nation-{year}")
}

# Shared by `io_table_get()`/`io_table_target()` so the region_class/region_type
# dispatch logic lives in exactly one place. `region_class` picks the region
# granularity (`"nation"`, `"pref"`, or `"block"`); `region` then picks a
# single member of that granularity and is required exactly when
# `region_class != "nation"` and `region_type = "regional"` (one region's
# own table) -- everywhere else it must be `NULL`, since `"nation"` always
# covers the whole country and a `"multiregional"` table always covers every
# region in its breakdown at once. There's no backing tarchive for a single
# block's own table yet, so that combination falls through to
# `check_archive_pipeline()`'s generic "can't find pipeline" error rather
# than a dedicated one.
io_table_resolve <- function(
  region_type,
  region_class,
  region,
  year,
  sector_class,
  price_type,
  competitive_import,
  language
) {
  package <- "econiodatajp"
  region_needed <- region_class != "nation" && region_type == "regional"
  if (region_needed && is.null(region)) {
    rlang::abort(stringr::str_glue(
      '`region` must be specified when `region_class = "{region_class}"` and ',
      '`region_type = "regional"`.'
    ))
  }
  if (!region_needed && !is.null(region)) {
    rlang::abort(
      '`region` isn\'t supported when `region_class = "nation"` or `region_type = "multiregional"`.'
    )
  }

  if (region_class == "nation") {
    if (region_type != "regional") {
      rlang::abort(
        '`region_class = "nation"` requires `region_type = "regional"`.'
      )
    }
    pipeline <- io_table_pipeline_regional_nation(year)
    check_archive_pipeline(package, pipeline)
    name <- io_table_name_archive(
      price_type = price_type,
      sector_class = sector_class,
      competitive_import = competitive_import,
      language = language
    )
    check_archive_name(
      package,
      pipeline,
      name,
      price_type = price_type,
      competitive_import = competitive_import,
      language = language
    )
  } else if (region_needed) {
    pipeline <- switch(
      region_class,
      pref = io_table_pipeline_regional_pref(year),
      block = io_table_pipeline_regional_block(year)
    )
    check_archive_pipeline(package, pipeline)
    name <- resolve_pref_name_archive(
      package,
      pipeline,
      price_type = price_type,
      sector_class = sector_class,
      competitive_import = competitive_import,
      language = language,
      pref = region
    )
  } else if (region_type == "multiregional") {
    pipeline <- switch(
      region_class,
      pref = io_table_pipeline_multiregional_pref_nation(year),
      block = io_table_pipeline_multiregional_block_nation(year)
    )
    check_archive_pipeline(package, pipeline)
    name <- io_table_name_archive(
      price_type = price_type,
      sector_class = sector_class,
      competitive_import = competitive_import,
      language = language
    )
    check_archive_name(
      package,
      pipeline,
      name,
      price_type = price_type,
      competitive_import = competitive_import,
      language = language
    )
  }

  list(pipeline = pipeline, name = name)
}

check_archive_pipeline <- function(package, pipeline) {
  pipelines <- tarchives::tar_archive_pipelines(package = package)
  if (!pipeline %in% pipelines) {
    rlang::abort(stringr::str_glue(
      "Can't find pipeline \"{pipeline}\" in package \"{package}\".\n",
      "Available pipelines: {stringr::str_c(pipelines, collapse = ', ')}."
    ))
  }
  invisible(pipeline)
}

# Doesn't validate `sector_class` itself -- valid choices vary by pipeline
# (nation: basic/small/medium/large/template; block: sector counts that
# differ by year, see io_table_resolve()) and there's no single vocabulary
# to check against here. io_table_resolve() validates the *result*
# instead, via check_archive_name(). Every caller passes
# `competitive_import`/`language` straight through rather than hardcoding
# `TRUE`/`"ja"` for pref/block -- those archives don't have
# noncompetitive-import or `_en` variants today, so a non-default request
# there simply builds a name that check_archive_name() (or
# resolve_pref_name_archive()'s own matching) won't find, the same generic
# failure as any other not-yet-published archive. Each nation tarchive
# precomputes an `_en`-suffixed companion archive for every
# `iotable_{price_type}[_noncompetitive_import]_{sector_class}` target (see
# `translate_iotable_sector()` in inst/tarchives/R/translate.R), so English
# is just a different archive name, not a runtime transformation.
io_table_name_archive <- function(
  price_type,
  sector_class,
  competitive_import,
  language
) {
  name <- stringr::str_glue("iotable_{price_type}")
  if (!competitive_import) {
    name <- stringr::str_glue("{name}_noncompetitive_import")
  }
  name <- stringr::str_glue("{name}_{sector_class}")
  if (language == "en") {
    name <- stringr::str_glue("{name}_en")
  }
  as.character(name)
}

# Confirms `name` (built by io_table_name_archive()) is actually one of
# `pipeline`'s targets, listing the pipeline's real sector_class choices
# for the requested `price_type`/`competitive_import`/`language` in the
# error otherwise (falling back to every sector_class the pipeline has at
# all if that combination has none, e.g. `competitive_import = FALSE` for
# a pipeline that only ever publishes competitive-import tables, so the
# error still suggests something) -- read back from the manifest
# (io_table_parse_name_archive()) rather than checked against a hardcoded
# vocabulary, since valid choices vary by pipeline and, for `region_class
# = "block"`, by year too (FY2005 has three sector granularities; every
# other year has one -- see the sibling
# iotable-multiregional-block-nation-1970..1995 tarchives).
check_archive_name <- function(
  package,
  pipeline,
  name,
  price_type,
  competitive_import,
  language
) {
  manifest <- tarchives::tar_manifest_archive(
    package = package,
    pipeline = pipeline
  )
  if (!name %in% manifest$name) {
    info <- io_table_parse_name_archive(manifest$name)
    sector_classes <- unique(info$sector_class[
      info$price_type == price_type &
        info$competitive_import == competitive_import &
        info$language == language
    ])
    if (length(sector_classes) == 0) {
      sector_classes <- unique(info$sector_class)
    }
    rlang::abort(stringr::str_glue(
      "Can't find target \"{name}\" in pipeline \"{pipeline}\".\n",
      "Available sector_class choices: {stringr::str_c(sector_classes, collapse = ', ')}."
    ))
  }
  invisible(name)
}

# `pref` accepts either a numeric prefecture code (e.g. `1`, `13`) or the
# code_name fragment used in archive target names (e.g. `"01_hokkaido"`).
# Resolved dynamically against the pipeline's manifest instead of a
# hardcoded code/name lookup table, so this can later be swapped for a
# `jpcity`-based resolver without changing the public API. The match prefix
# is built by `io_table_name_archive()` (same naming convention as the
# nation/multiregional archives) so `competitive_import`/`language` aren't
# hardcoded to "nation-only" here -- a `pref`/`block` request for a
# combination with no backing archive yet (e.g. `language = "en"`) simply
# matches zero targets below, the same generic failure mode as a missing
# pipeline.
resolve_pref_name_archive <- function(
  package,
  pipeline,
  price_type,
  sector_class,
  competitive_import,
  language,
  pref
) {
  prefix <- io_table_name_archive(
    price_type = price_type,
    sector_class = sector_class,
    competitive_import = competitive_import,
    language = language
  )

  pref <- as.character(pref)
  if (stringr::str_detect(pref, "^[0-9]+$")) {
    code <- stringr::str_pad(pref, width = 2, pad = "0")
    pattern <- stringr::str_glue("^{prefix}.*_{code}_[^_]+$")
  } else {
    pattern <- stringr::str_glue("^{prefix}.*_{pref}$")
  }

  manifest <- tarchives::tar_manifest_archive(
    package = package,
    pipeline = pipeline
  )
  matches <- manifest$name[stringr::str_detect(manifest$name, pattern)]
  if (length(matches) == 0) {
    rlang::abort(stringr::str_glue(
      "Can't find a target matching pref = \"{pref}\" in pipeline \"{pipeline}\"."
    ))
  }
  if (length(matches) > 1) {
    rlang::abort(stringr::str_glue(
      "Multiple targets match pref = \"{pref}\" in pipeline \"{pipeline}\": ",
      "{stringr::str_c(matches, collapse = ', ')}."
    ))
  }
  matches
}

# Reverses io_table_pipeline_*()'s naming scheme back into region_type/
# region_class/year, so io_table_available() can list what's on disk instead
# of a hardcoded set of pipelines. Vectorized: `pipeline` can be the full
# character vector from tar_archive_pipelines(). The optional `(?:-nation)?`
# group absorbs the extra "-nation" segment that only the `multiregional`
# pipelines have, right after `region_class` (see
# io_table_pipeline_multiregional_pref_nation()) -- it plays the same role
# `region` does for `io_table_pipeline_regional_*()`, just with no per-region
# subsetting yet, so it's always "nation" (every region at once) today. This
# is unrelated to `region_class = "nation"` (`iotable-regional-nation-{year}`),
# which the same `(nation|pref|block)` group also matches directly.
io_table_parse_pipeline <- function(pipeline) {
  m <- stringr::str_match(
    pipeline,
    "^iotable-(regional|multiregional)-(nation|pref|block)(?:-nation)?-([0-9]+)$"
  )
  data.frame(
    region_type = m[, 2],
    region_class = m[, 3],
    year = as.integer(m[, 4]),
    stringsAsFactors = FALSE
  )
}

# Reverses io_table_name_archive()'s naming scheme back into price_type/
# competitive_import/sector_class/language/region, so sector_class choices
# (check_archive_name()) and io_table_available() can both be read back from
# whatever targets a pipeline actually defines instead of a hardcoded
# vocabulary. Vectorized: `name` can be a whole manifest's `$name` column.
# Only "nation" archives have `_noncompetitive_import`/`_en` (see
# io_table_name_archive()).
#
# A pipeline's manifest also lists its non-table targets (e.g. the
# `tar_change()`-generated `file_...`/`file..._change` targets that
# download and track each source workbook); those don't match this naming
# scheme at all and are silently dropped rather than returned as NA rows.
#
# Known gap: the `iotable-regional-pref-*` archives' per-prefecture targets
# (one selected by `region` in io_table_get()) aren't reversed by this
# pattern at all and so are silently dropped too, same as the file_...
# targets above -- each is hand-named per prefecture (in each archive's own
# R/iotable_producer_price/{code}_{name}.R) as
# `iotable_{price_type}_{sector_class}_raw_{pref_code}_{pref_name}`, with a
# literal `_raw` that io_table_name_archive() never generates and that
# `resolve_pref_name_archive()`'s own matching only tolerates via a
# wildcard (`.*`), not by naming it. io_table_available() therefore currently
# omits `region_class = "pref"`, `region_type = "regional"` rows; `region`
# stays a plain column here for `region_class = "block"`, which never has
# one (always `NA`), rather than being dropped entirely.
io_table_parse_name_archive <- function(name) {
  m <- stringr::str_match(
    name,
    "^iotable_(producer_price|purchaser_price)(_noncompetitive_import)?_([^_]+)(_en)?(?:_([0-9]{2})_(.+))?$"
  )
  m <- m[!is.na(m[, 1]), , drop = FALSE]
  data.frame(
    name = m[, 1],
    price_type = m[, 2],
    competitive_import = is.na(m[, 3]),
    sector_class = m[, 4],
    language = ifelse(is.na(m[, 5]), "ja", "en"),
    region = ifelse(
      is.na(m[, 6]),
      NA_character_,
      stringr::str_c(m[, 6], "_", m[, 7])
    ),
    stringsAsFactors = FALSE
  )
}
