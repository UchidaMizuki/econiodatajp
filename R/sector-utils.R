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
# io_sector_conversion_get()/io_sector_jsic_get()/io_sector_target()/
# io_sector_conversion_target()/io_sector_jsic_target() so the
# region_type/region_class/region/axis/type -> pipeline/name dispatch logic
# lives in exactly one place, mirroring io_table_resolve().
io_sector_resolve <- function(
  region_type,
  region_class,
  year,
  region = NULL,
  axis = NULL,
  type
) {
  package <- "econiodatajp"
  pipeline <- io_table_pipeline(
    region_type = region_type,
    region_class = region_class,
    year = year
  )
  tarchives::tar_check_archive_pipeline(pipeline, package = package)

  name <- io_sector_name_archive(region = region, axis = axis, type = type)
  tarchives::tar_check_archive_name(
    name,
    package = package,
    pipeline = pipeline
  )

  list(pipeline = pipeline, name = name)
}

# `type = "sector"` is the sector_class classification/name master
# (`sector_{region}_input`/`sector_{region}_output`); `type = "conversion"`
# is the basic -> small/medium/large/template crosswalk
# (`sector_conversion_{region}_input`/`sector_conversion_{region}_output`).
# Both come in an `input` and an `output` version, so their archive name is
# `<prefix>_<region>_<axis>` -- the tarchive-side target is named
# `sector_conversion_*` (not `conversion_sector_*`) so its token order
# matches this function family's own name (io_sector_conversion_get()), and
# `region` sits between the prefix and `axis` so its own position matches
# io_table_name_archive()'s (`region` right after the base prefix, before
# the arguments that follow it), the same way io_table_name_archive() leads
# with `region` to match io_table_get()'s argument order. `region` defaults
# to `"nation"` (never omitted, never a placeholder) -- see
# io_table_name_archive() for why every table/sector archive always carries
# an explicit region rather than leaving the whole-country case unmarked.
# Only `region = "nation"` (`region_class = "nation"`) pipelines actually
# carry sector data as of writing, but the naming scheme doesn't assume
# that won't change.
#
# `type = "jsic"` has no `axis`: the basic-classification -> JSIC (Japan
# Standard Industrial Classification) crosswalk (see
# `inst/tarchives/R/sector_jsic.R`'s get_sector_jsic()) is only ever
# published keyed to the output/industry axis's basic codes, so there's
# nothing for `axis` to distinguish and its archive name is
# `sector_jsic_{region}` -- `axis` is ignored for this `type`.
io_sector_name_archive <- function(region = NULL, axis, type) {
  region <- region %||% "nation"
  if (type == "jsic") {
    return(stringr::str_glue("sector_jsic_{region}") |> as.character())
  }
  prefix <- switch(type, sector = "sector", conversion = "sector_conversion")
  stringr::str_glue("{prefix}_{region}_{axis}") |>
    as.character()
}

# Reverses io_sector_name_archive()'s naming scheme back into
# type/region/axis, so io_sector_available() can list what a pipeline
# actually defines instead of a hardcoded vocabulary. Vectorized: `name` can
# be a whole manifest's `$name` column. A pipeline's manifest also lists its
# non-sector targets (the whole `iotable_*` table family, plus
# `sector_raw`/`file_sector_*`); those don't match either naming scheme at
# all and are silently dropped rather than returned as NA rows, mirroring
# io_table_parse_name_archive(). The `region` group is `(.+)`, not a
# hardcoded shape, for the same reason io_table_parse_name_archive()'s is:
# greedy backtracking finds the unique split point right before the fixed
# `_input`/`_output` suffix regardless of what `region` itself looks like.
io_sector_parse_name_archive <- function(name) {
  matched <- stringr::str_match(
    name,
    "^sector_(conversion_)?(.+)_(input|output)$"
  )
  # Column order (`region` before `type`) matches io_table_parse_name_archive()'s
  # (`region` before `sector_class`), so io_sector_available_impl()'s
  # `region_type`/`region_class`/`year`/`region`/... prefix lines up the
  # same way io_table_available's does.
  sector_or_conversion <- tibble::tibble(
    region = matched[, 3],
    type = dplyr::recode_values(
      matched[, 2],
      "conversion_" ~ "conversion",
      default = "sector"
    ),
    axis = matched[, 4],
    name = matched[, 1]
  ) |>
    dplyr::filter(!is.na(name))

  # `jsic` has no `axis` (see io_sector_name_archive()), so it can't share
  # the "<prefix>_<region>_<axis>" regex above -- matched separately as
  # `sector_jsic_<region>`.
  jsic_matched <- stringr::str_match(name, "^sector_jsic_(.+)$")
  jsic <- tibble::tibble(
    region = jsic_matched[, 2],
    type = "jsic",
    axis = NA_character_,
    name = jsic_matched[, 1]
  ) |>
    dplyr::filter(!is.na(name))

  dplyr::bind_rows(sector_or_conversion, jsic)
}
