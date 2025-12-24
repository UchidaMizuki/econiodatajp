# https://www.pref.gifu.lg.jp/page/25991.html
target_iotable_producer_price_21_gifu <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_21_gifu,
    download_file(
      url = "https://www.pref.gifu.lg.jp/uploaded/attachment/211274.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/21_gifu.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_21_gifu = read_file_iotable_producer_price_small_21_gifu(
    file = file_iotable_producer_price_small_21_gifu
  ),
)

read_file_iotable_producer_price_small_21_gifu <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "4-1",
      rows_exclude = 1:2
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
      export_total_pattern = export_total_pattern,
      import_pattern = import_pattern,
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
