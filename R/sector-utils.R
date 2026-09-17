# Sector master/conversion data lives inside the same tarchive pipeline as
# the corresponding IO table (see e.g.
# `inst/tarchives/iotable-regional-nation-{year}/R/sector.R`) -- there's no
# separate "sector" pipeline directory, so this reuses io_table_pipeline()
# directly rather than duplicating its naming glue. Only `region_type =
# "regional"`, `region_class = "nation"` pipelines carry sector data today,
# but that's not assumed here (`region_type`/`region_class` are required
# arguments, not hardcoded) -- io_sector_available_impl() already discovers
# valid combinations generically, and tar_check_archive_pipeline()/
# tar_check_archive_name() give the same "can't find it" error for a
# combination that doesn't exist as for one that does, so this doesn't need
# to know the current set in advance either. Shared by io_sector_get()/
# io_sector_conversion_get()/io_sector_jsic_get()/
# io_jsic_conversion_get()/io_sector_target()/
# io_sector_conversion_target()/io_sector_jsic_target()/
# io_jsic_conversion_target() so the
# region_type/region_class/region/axis/type -> pipeline/name dispatch logic
# lives in exactly one place, mirroring io_table_resolve().
io_sector_resolve <- function(
  region_type,
  region_class,
  year,
  region = NULL,
  axis = NULL,
  language = NULL,
  type
) {
  package <- "econiodatajp"
  pipeline <- io_table_pipeline(
    region_type = region_type,
    region_class = region_class,
    year = year
  )
  tarchives::tar_check_archive_pipeline(pipeline, package = package)

  name <- io_sector_name_archive(
    region = region,
    axis = axis,
    language = language,
    type = type
  )
  tarchives::tar_check_archive_name(
    name,
    package = package,
    pipeline = pipeline
  )

  list(pipeline = pipeline, name = name)
}

# Every `type` value is exactly the `io_<type>_get()` function it backs
# (`"sector"` -> io_sector_get(), `"sector_conversion"` ->
# io_sector_conversion_get(), `"sector_jsic"` -> io_sector_jsic_get(),
# `"jsic_conversion"` -> io_jsic_conversion_get()), not an arbitrary
# shorter label -- so a row of `io_sector_available` (region/type/axis)
# tells you both which function to call *and*, via this function, exactly
# which archive name it resolves to, with no separate lookup table to keep
# in sync.
#
# `"sector"`/`"sector_conversion"`/`"sector_jsic"` all come in `input`/
# `output` and `ja`/`en` versions, so their archive name is always
# `sector_<prefix><region>_<axis>_<language>`, `axis` and `language` both
# taken as given. As in io_table_name_archive(), `language` selects a
# prebuilt single-language archive (see `sector_pick_language()` in
# inst/tarchives/R/sector_language.R for the split) rather than being a
# runtime column pick, so io_sector_get() and io_sector_target() hand back
# the same thing. This function has no type-specific knowledge of *which*
# axis a caller should pass, including for `"sector_jsic"`: even though
# every one of its callers always passes `axis = "output"` (see
# io_sector_jsic_get()/io_sector_jsic_target_raw(), and their comments for
# why -- JSIC classifies establishments by industry, which the output
# axis's basic classification already represents, while the input axis's is
# a finer, commodity/transaction-level breakdown JSIC has no counterpart
# for), that's a fact about JSIC's callers, not about archive-name
# construction, so it's not special-cased here. Folding `sector_jsic` into
# the same shape as `sector`/`sector_conversion` means
# `io_sector_parse_name_archive()` doesn't need a separate branch for it.
#
# `type = "jsic_conversion"` is the exception on both counts: JSIC's own
# hierarchy (see `inst/tarchives/R/sector_jsic.R`'s get_jsic_conversion())
# has no IO input/output axis, and no machine-readable English source has
# been found for it yet (#31), so its name carries neither an axis nor a
# language segment -- it's just `jsic_conversion_{region}`, and doesn't
# start with `sector_` either since it isn't about IO sectors.
#
# `region` defaults to `"nation"` (never omitted, never a placeholder) --
# see io_table_name_archive() for why every table/sector archive always
# carries an explicit region rather than leaving the whole-country case
# unmarked. Only `region = "nation"` (`region_class = "nation"`) pipelines
# actually carry sector data as of writing, but the naming scheme doesn't
# assume that won't change.
io_sector_name_archive <- function(region = NULL, axis, language, type) {
  region <- region %||% "nation"
  if (type == "jsic_conversion") {
    return(stringr::str_glue("jsic_conversion_{region}") |> as.character())
  }
  prefix <- switch(
    type,
    sector = "",
    sector_conversion = "conversion_",
    sector_jsic = "jsic_"
  )
  stringr::str_glue("sector_{prefix}{region}_{axis}_{language}") |>
    as.character()
}

# Reverses io_sector_name_archive()'s naming scheme back into
# type/region/axis/language, so io_sector_available() can list what a
# pipeline actually defines instead of a hardcoded vocabulary. Vectorized:
# `name` can be a whole manifest's `$name` column. A pipeline's manifest
# also lists non-sector targets (the whole `iotable_*` family, plus
# `sector_raw`/`sector_jsic_raw`/the bilingual `sector_<prefix><region>_<axis>`
# intermediates each `_ja`/`_en` pair is split from/other intermediates);
# those don't match either regex and are silently dropped rather than
# returned as NA rows, mirroring io_table_parse_name_archive(). In
# particular, requiring the fixed `_<axis>_<language>` suffix (rather than
# treating it as optional) is what keeps the bilingual `sector_nation_input`
# intermediate -- and `sector_jsic_raw` -- from being swallowed by this
# regex. The `region` group is `(.+)`, not a hardcoded shape, for the same
# reason io_table_parse_name_archive()'s is: greedy backtracking finds the
# unique split point right before the fixed suffix regardless of what
# `region` itself looks like.
# Shared by both regexes in io_sector_parse_name_archive() below: `str_match()`
# returns a plain matrix with no column names, so each regex's capture groups
# are immediately named (rather than indexed positionally downstream, e.g.
# `matched[, 3]`) -- purely cosmetic/readability, doesn't change what's
# matched.
match_archive_name <- function(name, pattern, cols) {
  stringr::str_match(name, pattern) |>
    tibble::as_tibble(.name_repair = "minimal") |>
    rlang::set_names(cols)
}

io_sector_parse_name_archive <- function(name) {
  matched <- match_archive_name(
    name,
    "^sector_(conversion_|jsic_)?(.+)_(input|output)_(ja|en)$",
    c("name", "prefix", "region", "axis", "language")
  )
  # Column order (`region` before `type`) matches io_table_parse_name_archive()'s
  # (`region` before `sector_class`), so io_sector_available_impl()'s
  # `region_type`/`region_class`/`year`/`region`/... prefix lines up the
  # same way io_table_available's does.
  # `.data$region`/`.data$prefix`/`.data$axis`/`.data$language`/`.data$name`
  # (not bare `region`/`prefix`/`axis`/`language`/`name`) below: none of
  # these are formal arguments of this function, only data-masked column
  # names, so a bare reference reads to R's own static analysis as an
  # undefined global variable (confirmed via `devtools::check()`) --
  # `.data$` makes the data-masking explicit.
  sector_family <- matched |>
    dplyr::transmute(
      region = .data$region,
      type = dplyr::recode_values(
        .data$prefix,
        "conversion_" ~ "sector_conversion",
        "jsic_" ~ "sector_jsic",
        default = "sector"
      ),
      axis = .data$axis,
      language = .data$language,
      name = .data$name
    ) |>
    dplyr::filter(!is.na(name))

  # `jsic_conversion` doesn't fit the `sector_<prefix><region>_<axis>_<language>`
  # shape above at all (see io_sector_name_archive()), so it's matched
  # separately, as `jsic_conversion_<region>`. `axis` and `language` are
  # both genuinely `NA` here (not known-but-unexposed values the way
  # `sector_jsic`'s `axis` is): JSIC's own hierarchy has no connection to an
  # IO table's input/output axis, and no English source has been found for
  # it yet (#31).
  jsic_conversion <- match_archive_name(
    name,
    "^jsic_conversion_(.+)$",
    c("name", "region")
  ) |>
    dplyr::transmute(
      region = .data$region,
      type = "jsic_conversion",
      axis = NA_character_,
      language = NA_character_,
      name = .data$name
    ) |>
    dplyr::filter(!is.na(name))

  dplyr::bind_rows(sector_family, jsic_conversion)
}
