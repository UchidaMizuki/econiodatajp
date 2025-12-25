# https://www.pref.kagoshima.jp/ac09/tokei/bunya/keizai/renkan/keisu_kako.html
target_iotable_producer_price_46_kagoshima <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_46_kagoshima,
    download_file(
      url = "https://www.pref.kagoshima.jp/ac09/tokei/bunya/keizai/renkan/documents/16211_20251003115640-1.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/46_kagoshima.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_46_kagoshima = read_file_iotable_producer_price_medium_46_kagoshima(
    file = file_iotable_producer_price_medium_46_kagoshima
  ),
)

read_file_iotable_producer_price_medium_46_kagoshima <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表",
      rows_exclude = 1:2
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
      competitive_import = TRUE,
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
      value_scale = 1e4
    )
}
