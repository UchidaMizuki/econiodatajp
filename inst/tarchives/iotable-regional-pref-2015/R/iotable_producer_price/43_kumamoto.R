# https://www.pref.kumamoto.jp/soshiki/20/50333.html
target_iotable_producer_price_43_kumamoto <- tar_plan(
  tar_change(
    file_iotable_43_kumamoto_medium_producer_price,
    download_file(
      url = "https://www.pref.kumamoto.jp/uploaded/attachment/122447.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/43_kumamoto.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_43_kumamoto_105_producer_price_competitive_import_ja = read_file_iotable_producer_price_medium_43_kumamoto(
    file = file_iotable_43_kumamoto_medium_producer_price
  ),
)

read_file_iotable_producer_price_medium_43_kumamoto <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表（統合中分類）",
      rows_exclude = 1:2,
      cols_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
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
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
