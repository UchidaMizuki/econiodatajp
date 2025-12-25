# https://www.pref.yamaguchi.lg.jp/soshiki/22/15720.html
# https://www.pref.yamaguchi.lg.jp/uploaded/attachment/38354.xlsx

target_iotable_producer_price_35_yamaguchi <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_35_yamaguchi,
    download_file(
      url = "https://www.pref.yamaguchi.lg.jp/uploaded/attachment/38354.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/35_yamaguchi.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_35_yamaguchi = read_file_iotable_producer_price_medium_35_yamaguchi(
    file = file_iotable_producer_price_medium_35_yamaguchi
  ),
)

read_file_iotable_producer_price_medium_35_yamaguchi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
      rows_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
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
      export_pattern = "[移輸]出計$",
      export_total_pattern = export_total_pattern,
      import_pattern = "（控除）[移輸]入計$",
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    )
}
