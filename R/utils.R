io_table_pipeline_regional_nation <- function(year) {
  stringr::str_glue("iotable-regional-nation-{year}")
}

io_table_pipeline_regional_pref <- function(year) {
  stringr::str_glue("iotable-regional-pref-{year}")
}

# Named `..._nation_pref()` rather than `..._pref()` because `area` is
# hardcoded to nation-level for `region_type == "multiregional"` today only
# for lack of subset data (see the `!nation` guard below) -- a future
# partial-region table would slot its own area value in between
# `multiregional` and `pref`/`block`, mirroring how `io_table_pipeline_regional_*()`
# already puts the area right after `regional`.
io_table_pipeline_multiregional_nation_pref <- function(year) {
  stringr::str_glue("iotable-multiregional-nation-pref-{year}")
}

# No backing tarchive exists yet (see GitHub issue #5); `check_archive_pipeline()`
# in the `region_class == "block"` branch of `io_table_resolve()` gives a clear
# error until one is added.
io_table_pipeline_multiregional_nation_block <- function(year) {
  stringr::str_glue("iotable-multiregional-nation-block-{year}")
}

# `language = NULL` defaults to `"en"` rather than `"ja"` even though
# Japanese is the authoritative source, since English is the more broadly
# useful default for callers who don't otherwise care; the `cli::cli_inform()`
# note (skipped when `language` is passed explicitly) makes sure that default
# doesn't happen silently.
resolve_language <- function(language) {
  if (is.null(language)) {
    cli::cli_inform(c(
      "i" = "Defaulting to {.code language = \"en\"}.",
      "i" = "Pass {.code language = \"ja\"} for the original Japanese sector \\
      names (the authoritative source)."
    ))
    language <- "en"
  }
  rlang::arg_match(language, c("ja", "en"))
}

# `area = "nation"` (default), `area = 0`, and `area = "00"` all mean
# nation-level (`0`/`"00"` mirror the JIS-style convention where prefecture
# code `00` denotes all of Japan, matching the numeric-code input style
# `area` already accepts for actual prefectures, e.g. `area = 13`).
is_area_nation <- function(area) {
  identical(area, "nation") ||
    (is.numeric(area) && isTRUE(area == 0)) ||
    (is.character(area) && area %in% c("0", "00"))
}

# Shared by `io_table_get()`/`io_table_target()` so the region_type/area
# dispatch logic lives in exactly one place. `competitive_import`/`language`
# are only meaningful for the nation branch today (the pref/multiregional
# tarchives don't have noncompetitive-import or `_en` archives yet), so a
# non-default value for either in any other branch errors instead of being
# silently ignored. `region_class` only applies when `region_type ==
# "multiregional"` (it selects which region breakdown backs that table --
# prefectures or the 9-region block table, see GitHub issue #5); unlike
# `competitive_import`/`language`, it has no default (`NULL` means
# "unset"), so callers must say which breakdown they want once
# `region_type = "multiregional"` has more than one -- any non-`NULL` value
# passed outside that branch still errors, same as the others.
io_table_resolve <- function(
  year,
  region_type,
  area,
  price_type,
  sector_class,
  region_class,
  competitive_import,
  language
) {
  nation <- is_area_nation(area)

  if (region_type == "multiregional") {
    if (!nation) {
      rlang::abort('`area` must be "nation" when `region_type = "multiregional"`.')
    }
    if (!isTRUE(competitive_import)) {
      rlang::abort(
        '`competitive_import = FALSE` isn\'t supported when `region_type = "multiregional"`.'
      )
    }
    if (!is.null(language)) {
      rlang::abort('`language` isn\'t supported when `region_type = "multiregional"`.')
    }
    if (is.null(region_class)) {
      rlang::abort(
        '`region_class` must be specified ("pref" or "block") when `region_type = "multiregional"`.'
      )
    }
    region_class <- rlang::arg_match(region_class, c("pref", "block"))
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
    sector_class <- sector_class %||% sector_class_choices
    name <- io_table_name_archive(
      price_type = price_type,
      sector_class = sector_class,
      sector_class_choices = sector_class_choices,
      competitive_import = TRUE
    )
  } else if (nation) {
    if (!is.null(region_class)) {
      rlang::abort('`region_class` isn\'t supported when `region_type = "regional"`.')
    }
    sector_class <- sector_class %||%
      c("basic", "small", "medium", "large", "template")
    sector_class <- rlang::arg_match(
      sector_class,
      c("basic", "small", "medium", "large", "template")
    )
    pipeline <- io_table_pipeline_regional_nation(year)
    check_archive_pipeline("econiodatajp", pipeline)
    language <- resolve_language(language)
    name <- io_table_name_archive(
      price_type = price_type,
      sector_class = sector_class,
      sector_class_choices = c("basic", "small", "medium", "large", "template"),
      competitive_import = competitive_import,
      language = language
    )
  } else {
    if (!is.null(region_class)) {
      rlang::abort('`region_class` isn\'t supported when `area` is a prefecture.')
    }
    if (!isTRUE(competitive_import)) {
      rlang::abort(
        '`competitive_import = FALSE` isn\'t supported when `area` is a prefecture.'
      )
    }
    if (!is.null(language)) {
      rlang::abort('`language` isn\'t supported when `area` is a prefecture.')
    }
    sector_class <- sector_class %||% "medium"
    pipeline <- io_table_pipeline_regional_pref(year)
    check_archive_pipeline("econiodatajp", pipeline)
    name <- resolve_pref_name_archive(
      "econiodatajp",
      pipeline,
      price_type = price_type,
      sector_class = sector_class,
      pref = area
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
# (large only) archives. `language` defaults to `"ja"` so existing callers
# that don't pass it (pref, multiregional) are unaffected; each nation
# tarchive precomputes an `_en`-suffixed companion archive for every
# `iotable_{price_type}[_noncompetitive_import]_{sector_class}` target (see
# `translate_iotable_sector()` in inst/tarchives/R/translate.R), so English
# is just a different archive name, not a runtime transformation.
io_table_name_archive <- function(
  price_type,
  sector_class,
  sector_class_choices,
  competitive_import = TRUE,
  language = "ja"
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
