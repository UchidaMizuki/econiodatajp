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
# io_sector_conversion_get()/io_sector_target()/io_sector_conversion_target()
# so the region_type/region_class/axis/type -> pipeline/name dispatch logic
# lives in exactly one place, mirroring io_table_resolve().
io_sector_resolve <- function(region_type, region_class, year, axis, type) {
  package <- "econiodatajp"
  pipeline <- io_table_pipeline(
    region_type = region_type,
    region_class = region_class,
    year = year
  )
  tarchives::tar_check_archive_pipeline(pipeline, package = package)

  name <- io_sector_name_archive(axis = axis, type = type)
  tarchives::tar_check_archive_name(
    name,
    package = package,
    pipeline = pipeline
  )

  list(pipeline = pipeline, name = name)
}

# `type = "sector"` is the sector_class classification/name master
# (`sector_input`/`sector_output`); `type = "conversion"` is the
# basic -> small/medium/large/template crosswalk (`sector_conversion_input`/
# `sector_conversion_output`). The tarchive-side target is named
# `sector_conversion_*` (not `conversion_sector_*`) so its token order
# matches this function family's own name (io_sector_conversion_get()), the
# same way io_table_name_archive() leads with `region` to match
# io_table_get()'s argument order.
io_sector_name_archive <- function(axis, type) {
  prefix <- switch(type, sector = "sector", conversion = "sector_conversion")
  stringr::str_glue("{prefix}_{axis}") |>
    as.character()
}

# Reverses io_sector_name_archive()'s naming scheme back into type/axis, so
# io_sector_available() can list what a pipeline actually defines instead of
# a hardcoded vocabulary. Vectorized: `name` can be a whole manifest's `$name`
# column. A pipeline's manifest also lists its non-sector targets (the whole
# `iotable_*` table family, plus `sector_raw`/`file_sector_*`); those don't
# match this naming scheme at all and are silently dropped rather than
# returned as NA rows, mirroring io_table_parse_name_archive().
io_sector_parse_name_archive <- function(name) {
  matched <- stringr::str_match(
    name,
    "^sector_(conversion_)?(input|output)$"
  )
  tibble::tibble(
    # str_match() returns NA (not "") for an optional group that matched
    # zero-width, so a "sector_input"-style name (no "conversion_" group) is
    # told apart from a "sector_conversion_input"-style one by NA-ness here,
    # not by comparing against "".
    type = dplyr::if_else(is.na(matched[, 2]), "sector", "conversion"),
    axis = matched[, 3],
    name = matched[, 1]
  ) |>
    dplyr::filter(!is.na(name))
}
