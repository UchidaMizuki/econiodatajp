# https://www.pref.kumamoto.jp/soshiki/20/50333.html
target_iotable_producer_price_43_kumamoto <- tar_plan(
  tar_change(
    file_iotable_43_kumamoto_107_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.kumamoto.jp/uploaded/attachment/282593.xlsx",
      destfile = "_targets/user/iotable_43_kumamoto_107_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_43_kumamoto_107_producer_price_competitive_import_ja = read_file_iotable_producer_price_107_43_kumamoto(
    file = file_iotable_43_kumamoto_107_producer_price_competitive_import_ja
  ),
)

# TODO: The workbook doesn't state a unit anywhere on the sheet;
# `value_scale = 1e6` matches the 2015 table and every neighboring
# prefecture but hasn't been independently confirmed for this table.
read_file_iotable_producer_price_107_43_kumamoto <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表（統合中分類）",
      rows_exclude = 1:2,
      cols_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c(
        "input_sector_code",
        "input_sector_name"
      ),
      output_names = c(
        "output_sector_code",
        "output_sector_name"
      )
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
      import_pattern = import_pattern,
      # The workbook's import total lacks a trailing 計 (（控除）輸移入), so
      # the shared pattern in global.R doesn't match it.
      import_total_pattern = "[（\\(]控除[）\\)]輸移入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
