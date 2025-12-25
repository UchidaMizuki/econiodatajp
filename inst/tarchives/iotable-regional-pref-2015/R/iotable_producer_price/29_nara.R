# https://www.pref.nara.jp/16376.htm
target_iotable_producer_price_29_nara <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_29_nara,
    download_file(
      url = "https://www.pref.nara.jp/secure/36885/2015-171.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/29_nara.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_29_nara = read_file_iotable_producer_price_small_29_nara(
    file = file_iotable_producer_price_small_29_nara
  ),
)

read_file_iotable_producer_price_small_29_nara <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "171-1生産者価格評価表",
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
      export_pattern = export_pattern,
      export_total_pattern = export_total_pattern,
      import_pattern = import_pattern,
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    )
}
