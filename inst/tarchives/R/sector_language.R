# Split a bilingual sector target -- `get_sector()` / `get_sector_conversion()`
# (per-pipeline, in each `sector.R`) and `get_sector_jsic()` (shared, in
# `sector_jsic.R`) each carry `_ja` and `_en` name columns side by side --
# into the single-language tibble `io_sector_get()` /
# `io_sector_conversion_get()` / `io_sector_jsic_get()` return, one target
# per language (`sector_nation_input_ja`, `sector_nation_input_en`, ...).
#
# This is where the language pick happens: `language` selects a prebuilt
# archive, the same way it does for `io_table_get()` (see
# `translate_iotable_sector()` and econiodatajp's `io_table_name_archive()`),
# not a runtime column selection inside the accessor -- so `io_sector_get()`
# and `io_sector_target()` hand back exactly the same object. The bilingual
# targets themselves stay in the manifest as intermediates; econiodatajp's
# `io_sector_parse_name_archive()` drops them (no `_ja`/`_en` suffix) so they
# never surface in `io_sector_available`.
#
# The published column is always `sector_name` (or `sector_name_from` /
# `sector_name_to`), never a language-qualified name.
sector_pick_language <- function(sector, language) {
  dplyr::select(
    sector,
    "sector_type",
    "sector_class",
    sector_name = tidyselect::all_of(paste0("sector_name_", language))
  )
}

sector_conversion_pick_language <- function(sector_conversion, language) {
  dplyr::select(
    sector_conversion,
    "sector_type",
    "sector_class_from",
    sector_name_from = tidyselect::all_of(paste0(
      "sector_name_from_",
      language
    )),
    "sector_class_to",
    sector_name_to = tidyselect::all_of(paste0("sector_name_to_", language))
  )
}

sector_jsic_pick_language <- function(sector_jsic, language) {
  dplyr::select(
    sector_jsic,
    sector_name = tidyselect::all_of(paste0("sector_name_", language)),
    "jsic_code",
    "jsic_name",
    "note",
    "jsic_revision_year"
  )
}
