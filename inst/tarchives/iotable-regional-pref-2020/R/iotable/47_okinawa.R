# https://www.pref.okinawa.jp/toukeika/io/2020/io(2020)top.html
target_iotable_producer_price_47_okinawa <- tar_plan(
  tar_change(
    file_iotable_47_okinawa_397_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.okinawa.jp/toukeika/io/2020/R2okinawa-397dep_r.xlsx",
      destfile = "_targets/user/iotable_47_okinawa_397_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_47_okinawa_397_producer_price_competitive_import_ja = read_file_iotable_producer_price_397_47_okinawa(
    file = file_iotable_47_okinawa_397_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_397_47_okinawa <- function(file) {
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = "(輸出|移出)計$",
      import_pattern = "[（\\(]控除[）\\)](輸入|移入)計$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      check_axes = FALSE
    ) |>
    end_step()
}
