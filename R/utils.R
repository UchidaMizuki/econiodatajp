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

# Named `..._nation_pref()` rather than `..._pref()` because this pipeline
# only ever covers every prefecture at once today (there's no per-region
# subsetting yet) -- a future partial-region table would slot its own
# qualifier in between `multiregional` and `pref`/`block`, mirroring how
# `io_table_pipeline_regional_*()` already puts the region right after
# `regional`.
io_table_pipeline_multiregional_nation_pref <- function(year) {
  stringr::str_glue("iotable-multiregional-nation-pref-{year}")
}

# No backing tarchive exists yet (see GitHub issue #5); `check_archive_pipeline()`
# in the `region_class == "block"` branch of `io_table_resolve()` gives a clear
# error until one is added.
io_table_pipeline_multiregional_nation_block <- function(year) {
  stringr::str_glue("iotable-multiregional-nation-block-{year}")
}

# `competitive_import`/`language` are only meaningful for `region_class =
# "nation"` today (the pref/block tarchives don't have noncompetitive-import
# or `_en` archives yet), so a non-default value for either elsewhere errors
# instead of being silently ignored. `language` is already validated to
# `"ja"`/`"en"` by the caller, so a plain `!=` comparison (rather than
# `is.null()`) is enough to detect a non-default value.
check_nation_only_args <- function(competitive_import, language) {
  if (!isTRUE(competitive_import) || language != "ja") {
    rlang::abort(
      '`competitive_import` and `language` are only supported when `region_class = "nation"`.'
    )
  }
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
    check_archive_pipeline("econiodatajp", pipeline)
    name <- io_table_name_archive(
      price_type = price_type,
      sector_class = sector_class,
      sector_class_choices = c("basic", "small", "medium", "large", "template"),
      competitive_import = competitive_import,
      language = language
    )
  } else if (region_needed) {
    check_nation_only_args(competitive_import, language)
    pipeline <- switch(
      region_class,
      pref = io_table_pipeline_regional_pref(year),
      block = io_table_pipeline_regional_block(year)
    )
    check_archive_pipeline("econiodatajp", pipeline)
    name <- resolve_pref_name_archive(
      "econiodatajp",
      pipeline,
      price_type = price_type,
      sector_class = sector_class,
      pref = region
    )
  } else if (region_type == "multiregional") {
    check_nation_only_args(competitive_import, language)
    pipeline <- switch(
      region_class,
      pref = io_table_pipeline_multiregional_nation_pref(year),
      block = io_table_pipeline_multiregional_nation_block(year)
    )
    check_archive_pipeline("econiodatajp", pipeline)
    # The RIETI pref table only has one sector granularity ("large"). The
    # METI block table has three (12/29/53 sectors from its source
    # workbook), but unlike the nation table's basic/small/medium/large/
    # template -- each a direct translation of a real official Japanese
    # classification tier name (基本分類/統合小分類/統合中分類/統合大分類)
    # -- METI's own documentation for the block table never names these
    # tiers at all, only their sector counts (see
    # inst/tarchives/iotable-multiregional-nation-block-2005/R/iotable_producer_price.R).
    # Reusing "small"/"medium"/"large" here would therefore be an
    # unfounded borrowing, and an actively misleading one: the nation
    # table's "small" (統合小分類) has *more* sectors than its "large"
    # (統合大分類), the opposite direction from what "small"/"large" would
    # suggest for this table. "coarse"/"medium"/"fine" avoids the
    # collision entirely.
    sector_class_choices <- switch(
      region_class,
      pref = "large",
      block = c("coarse", "medium", "fine")
    )
    name <- io_table_name_archive(
      price_type = price_type,
      sector_class = sector_class,
      sector_class_choices = sector_class_choices,
      competitive_import = TRUE,
      language = "ja"
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

# `price_type` currently only supports "producer_price" (no purchaser-price
# pipelines exist yet), kept as an argument so a future purchaser-price
# pipeline doesn't require a signature change. `sector_class_choices` is
# passed in by the caller because the set of available granularities differs
# between nation (basic/small/medium/large/template) and multiregional pref
# (large only) archives. `language` has no default -- callers must pass it
# explicitly (pref/multiregional callers always pass `"ja"`, since those
# archives have no `_en` variant); each nation tarchive precomputes an
# `_en`-suffixed companion archive for every
# `iotable_{price_type}[_noncompetitive_import]_{sector_class}` target (see
# `translate_iotable_sector()` in inst/tarchives/R/translate.R), so English
# is just a different archive name, not a runtime transformation.
io_table_name_archive <- function(
  price_type,
  sector_class,
  sector_class_choices,
  competitive_import,
  language
) {
  price_type <- rlang::arg_match(price_type, "producer_price")
  sector_class <- rlang::arg_match(sector_class, sector_class_choices)
  language <- rlang::arg_match(language, c("ja", "en"))
  if (!competitive_import && sector_class %in% c("basic", "small")) {
    rlang::abort(stringr::str_glue(
      "sector_class = \"{sector_class}\" is only available when ",
      "competitive_import = TRUE."
    ))
  }

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

# `pref` accepts either a numeric prefecture code (e.g. `1`, `13`) or the
# code_name fragment used in archive target names (e.g. `"01_hokkaido"`).
# Resolved dynamically against the pipeline's manifest instead of a
# hardcoded code/name lookup table, so this can later be swapped for a
# `jpcity`-based resolver without changing the public API. `sector_class` is
# folded into the match prefix so this can't accidentally resolve to a
# different granularity's target once more than one becomes available.
resolve_pref_name_archive <- function(
  package,
  pipeline,
  price_type,
  sector_class,
  pref
) {
  price_type <- rlang::arg_match(price_type, "producer_price")
  sector_class <- rlang::arg_match(sector_class, "medium")
  prefix <- stringr::str_glue("iotable_{price_type}_{sector_class}")

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
