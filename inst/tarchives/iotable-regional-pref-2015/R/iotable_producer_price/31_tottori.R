# https://www.pref.tottori.lg.jp/2015io_tables/
target_iotable_producer_price_31_tottori <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_31_tottori,
    download_file(
      url = "https://www.pref.tottori.lg.jp/secure/1269527/io_H27_107.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/31_tottori.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_31_tottori = read_file_iotable_producer_price_medium_31_tottori(
    file = file_iotable_producer_price_medium_31_tottori
  ),
)

read_file_iotable_producer_price_medium_31_tottori <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表",
      rows_exclude = 1:3
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
      export_pattern = "移輸出$",
      import_pattern = "（控除）移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      # FIXME?: Tottori IO table has large rounding errors
      total_tolerance = 1e7
    ) |>
    end_step()
}
