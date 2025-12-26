# https://www.pref.saga.lg.jp/kiji00373733/index.html
target_iotable_producer_price_41_saga <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_41_saga,
    download_file(
      url = "https://www.pref.saga.lg.jp/kiji00373733/3_73733_164848_up_yudlbzav.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/41_saga.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_41_saga = read_file_iotable_producer_price_medium_41_saga(
    file = file_iotable_producer_price_medium_41_saga
  ),
)

read_file_iotable_producer_price_medium_41_saga <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "107部門",
      rows_exclude = 1:2
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
      export_pattern = "移輸出計$",
      import_pattern = "（控除）移輸入計$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e3
    ) |>
    end_step()
}
