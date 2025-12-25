# https://www.pref.okayama.jp/page/detail-16600.html
target_iotable_producer_price_33_okayama <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_33_okayama,
    download_file(
      url = "https://www.pref.okayama.jp/uploaded/life/951294_9131056_misc.xls",
      destfile = "_targets/user/iotable/producer_price/small/33_okayama.xls"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_33_okayama = read_file_iotable_producer_price_small_33_okayama(
    file = file_iotable_producer_price_small_33_okayama
  ),
)

read_file_iotable_producer_price_small_33_okayama <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
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
      export_pattern = "輸移出$",
      import_pattern = "（控除）移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e5,
      total_tolerance = 1e-3
    )
}
