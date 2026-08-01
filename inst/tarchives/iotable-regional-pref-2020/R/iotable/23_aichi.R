# https://www.pref.aichi.jp/soshiki/toukei/io2020.html
target_iotable_producer_price_23_aichi <- tar_plan(
  tar_change(
    file_iotable_23_aichi_108_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.aichi.jp/uploaded/attachment/607058.xlsx",
      destfile = "_targets/user/iotable_23_aichi_108_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_23_aichi_108_producer_price_competitive_import_ja = read_file_iotable_producer_price_108_23_aichi(
    file = file_iotable_23_aichi_108_producer_price_competitive_import_ja
  ),
)

# TODO: as of the 2026-07 survey behind issue #26, the more detailed
# 186-sector table this prefecture published for 2015 wasn't found among the
# 2020 downloads (only 13/37/108-sector tables are linked from the source
# page) -- re-check periodically in case a detailed table is added later.
# The workbook doesn't state a unit either; `value_scale = 1e6` matches the
# 2015 table and was cross-checked against a sibling file in the same 2020
# release (第2部　統計表編) that does print "百万円".
read_file_iotable_producer_price_108_23_aichi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "108部門",
      rows_exclude = c(1, 2, 3)
    ) |>
    # Unlike every other prefecture, headers here carry a leading serial
    # number ("1", "2", ...) ahead of the actual sector code -- read it but
    # drop it, keeping only code/name for the glued sector name.
    io_table_read_headers(
      input_names = c(
        "input_sector_index",
        "input_sector_code",
        "input_sector_name"
      ),
      output_names = c(
        "output_sector_index",
        "output_sector_code",
        "output_sector_name"
      )
    ) |>
    as_step(select)(
      -"input_sector_index",
      -"output_sector_index"
    ) |>
    as_step(mutate)(
      across(
        c(input_sector_name, output_sector_name),
        \(x) str_remove_all(x, "\\s")
      )
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name}"
    ) |>
    io_table_read_sector_types(
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      export_total_pattern = export_total_pattern,
      # This table has a spurious intermediate subtotal ("（控除）輸入計")
      # between the overseas-import items ("（控除）輸入"/"（控除）関税"/
      # "（控除）輸入品商品税") and the interregional "移入" item, and
      # neither "移入" nor the true grand total "移輸入計" carry the
      # "（控除）" prefix every other prefecture uses -- make the prefix
      # optional (wrapped in its own group, unlike global.R's pattern where
      # the prefix is mandatory) and match the grand total by name alone.
      import_pattern = "(?:[（\\(]控除[）\\)])?([移輸]入|輸入品商品税|関税)$",
      import_total_pattern = "移輸入計$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
