# https://www.pref.okinawa.jp/toukeika/io/2015/io(2015)top.html
target_iotable_producer_price_47_okinawa <- tar_plan(
  tar_change(
    file_iotable_producer_price_basic_47_okinawa,
    download_file(
      url = "https://www.pref.okinawa.jp/toukeika/io/2015/H27okinawa-458dep.xlsx",
      destfile = "_targets/user/iotable/producer_price/basic/47_okinawa.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_basic_raw_47_okinawa = read_file_iotable_producer_price_basic_47_okinawa(
    file = file_iotable_producer_price_basic_47_okinawa
  ),
)

read_file_iotable_producer_price_basic_47_okinawa <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "公表用基本分類",
      rows_exclude = 1:4
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
      check_axes = FALSE
    ) |>
    end_step()
}
