# https://www.pref.kochi.lg.jp/doc/sanren27/
target_iotable_producer_price_39_kochi <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_39_kochi,
    download_file(
      url = "https://www.pref.kochi.lg.jp/doc/sanren27/file_contents/file_20213195154754_1.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/39_kochi.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_39_kochi = read_file_iotable_producer_price_medium_39_kochi(
    file = file_iotable_producer_price_medium_39_kochi
  ),
)

read_file_iotable_producer_price_medium_39_kochi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
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
      export_pattern = export_pattern,
      export_total_pattern = "移輸出$",
      import_pattern = import_pattern,
      import_total_pattern = "（控除）移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    )
}
