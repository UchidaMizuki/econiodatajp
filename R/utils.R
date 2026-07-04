io_table_pipeline_nation <- function(year) {
  stringr::str_glue("iotable-regional-nation-{year}")
}

io_table_pipeline_pref <- function(year) {
  stringr::str_glue("iotable-regional-pref-{year}")
}

io_table_pipeline_multiregional_pref <- function(year) {
  stringr::str_glue("iotable-multiregional-pref-{year}")
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
