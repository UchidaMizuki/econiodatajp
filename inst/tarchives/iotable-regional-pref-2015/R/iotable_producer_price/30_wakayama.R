# https://www.pref.wakayama.lg.jp/prefg/020300/sangyo/h27/d00203979.html
target_iotable_producer_price_30_wakayama <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_30_wakayama,
    download_file(
      url = "https://www.pref.wakayama.lg.jp/prefg/020300/sangyo/h27/d00203979_d/fil/t_187.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/30_wakayama.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_30_wakayama = read_file_iotable_producer_price_small_30_wakayama(
    file = file_iotable_producer_price_small_30_wakayama
  ),
)
read_file_iotable_producer_price_small_30_wakayama <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "187部門表",
      rows_exclude = 1:4,
      cols_exclude = 1
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
      value_scale = 1e6
    ) |>
    end_step()
}
