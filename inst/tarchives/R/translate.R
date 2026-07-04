# Shared by every national-table tarchive's `iotable_producer_price*` targets
# to build an English-language companion of an already-reclassified IO
# table, by joining its `sector` dimension against that pipeline's own
# `sector_input`/`sector_output` targets (see sector.R), filtered to
# `sector_class`. `unmatched = "error"` surfaces any *named* sector missing
# from the classification workbook as a build failure, rather than silently
# leaving it untranslated. `NA` sector names (e.g. the aggregate "import" row
# `io_table_to_noncompetitive_import()` adds, which has no name in Japanese
# either) are passed through unchanged rather than treated as "unmatched",
# since there is nothing to translate.
translate_iotable_sector <- function(table, sector_input, sector_output, sector_class) {
  translate <- function(sector, lookup) {
    lookup <- lookup[lookup$sector_class == sector_class, ]
    name_ja <- econio::io_sector_name(sector)
    is_named <- !is.na(name_ja)
    name_en <- name_ja
    name_en[is_named] <- recode_values(
      name_ja[is_named],
      from = lookup$sector_name_ja,
      to = lookup$sector_name_en,
      unmatched = "error"
    )
    vctrs::field(sector, "name") <- name_en
    sector
  }

  dim_names <- dimnames(table)
  dim_names$input$sector <- translate(dim_names$input$sector, sector_input)
  dim_names$output$sector <- translate(dim_names$output$sector, sector_output)
  dimnames(table) <- dim_names

  table
}
