# https://toukei.pref.ishikawa.lg.jp/search/detail.asp?d_id=4524
target_iotable_producer_price_17_ishikawa <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_17_ishikawa,
    download_file(
      url = "https://toukei.pref.ishikawa.lg.jp/dl/4524/h27io_187sec.xls",
      destfile = "_targets/user/iotable/producer_price/small/17_ishikawa.xls"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_17_ishikawa = read_file_iotable_producer_price_small_17_ishikawa(
    file = file_iotable_producer_price_small_17_ishikawa
  ),
)

read_file_iotable_producer_price_small_17_ishikawa <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "1_生産者価格評価表",
      rows_exclude = 1:3
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
      export_pattern = "移輸出$",
      import_pattern = "（控除）移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
