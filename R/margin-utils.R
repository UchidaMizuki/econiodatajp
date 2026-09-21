# Margin data lives inside the same tarchive pipeline as the
# corresponding IO table (see e.g.
# `inst/tarchives/iotable-regional-nation-{year}/R/margin.R`) -- there's no
# separate "margin" pipeline directory, so this reuses io_table_pipeline()
# directly rather than duplicating its naming glue. Only `region_type =
# "regional"`, `region_class = "nation"` pipelines carry margin data today,
# but that's not assumed here (`region_type`/`region_class` are required
# arguments, not hardcoded), mirroring io_sector_resolve() -- a future
# `region_class = "pref"`/`"block"` margin archive wouldn't need a signature
# change to support it. Shared by io_margin_get()/io_margin_target() so the
# region_type/region_class/region/margin_type/sector_class/language ->
# pipeline/name dispatch logic lives in exactly one place.
io_margin_resolve <- function(
  region_type,
  region_class,
  year,
  region = NULL,
  margin_type,
  sector_class,
  language
) {
  package <- "econiodatajp"
  pipeline <- io_table_pipeline(
    region_type = region_type,
    region_class = region_class,
    year = year
  )
  tarchives::tar_check_archive_pipeline(pipeline, package = package)

  name <- io_margin_name_archive(
    region = region,
    margin_type = margin_type,
    sector_class = sector_class,
    language = language
  )
  tarchives::tar_check_archive_name(
    name,
    package = package,
    pipeline = pipeline
  )

  list(pipeline = pipeline, name = name)
}

# `region` leads the name for the same reason as io_table_name_archive()
# (token order matches io_margin_get()'s own argument order), defaulting to
# `"nation"` (never omitted) for the same reason too -- see
# io_table_name_archive()'s comment. `sector_class` isn't validated against a
# hardcoded vocabulary here (only `"medium"` exists as of writing, but
# nothing here assumes that won't grow, e.g. a future aggregated/"large"
# variant) -- io_margin_resolve() validates the *result* instead, via
# tarchives::tar_check_archive_name(), same division of labor as
# io_table_name_archive().
io_margin_name_archive <- function(
  region = NULL,
  margin_type,
  sector_class,
  language
) {
  region <- region %||% "nation"
  stringr::str_glue(
    "margin_{region}_{sector_class}_{margin_type}_{language}"
  ) |>
    as.character()
}

# Reverses io_margin_name_archive()'s naming scheme back into
# region/sector_class/margin_type/language, so io_margin_available() can
# list what a pipeline actually defines instead of a hardcoded vocabulary.
# Vectorized: `name` can be a whole manifest's `$name` column. `margin_type`
# is matched against a fixed alternation (unlike `sector_class`, its
# vocabulary -- "trade_margin"/"transport_margin" -- is a stable, closed set
# the same way `price_type`/`import_type` are in
# io_table_parse_name_archive(), not something that varies by year/region),
# which is also what lets `sector_class` (`[^_]+`) stay a single
# underscore-free token immediately before it: greedy backtracking on
# `region` (`.+`) finds the unique split point right before that token,
# whatever `region` itself looks like.
io_margin_parse_name_archive <- function(name) {
  matched <- stringr::str_match(
    name,
    "^margin_(.+)_([^_]+)_(trade_margin|transport_margin)_(ja|en)$"
  )
  tibble::tibble(
    region = matched[, 2],
    sector_class = matched[, 3],
    margin_type = matched[, 4],
    language = matched[, 5],
    name = matched[, 1]
  ) |>
    dplyr::filter(!is.na(name))
}
