# https://www.pref.chiba.lg.jp/toukei/toukeidata/sangyou/h27/27data.html
target_iotable_producer_price_12_chiba <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_12_chiba,
    download_file(
      url = "https://www.pref.chiba.lg.jp/toukei/toukeidata/sangyou/h27/documents/40-h27togo185.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/12_chiba.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_12_chiba = read_file_iotable_producer_price_small_12_chiba(
    file = file_iotable_producer_price_small_12_chiba
  ),
)

read_file_iotable_producer_price_small_12_chiba <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表",
      rows_exclude = 1
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
      import_pattern = import_pattern,
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
