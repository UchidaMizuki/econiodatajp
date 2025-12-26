# https://data.bodik.jp/dataset/400009_sangyourenkanhyou_h27
target_iotable_producer_price_40_fukuoka <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_40_fukuoka,
    download_file(
      url = "https://data.bodik.jp/dataset/e9a2d1be-8bb4-4cf7-a936-dc57823dda2a/resource/209e822d-41ff-49c1-99d9-62fd43c984bc/download",
      destfile = "_targets/user/iotable/producer_price/medium/40_fukuoka.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_40_fukuoka = read_file_iotable_producer_price_medium_40_fukuoka(
    file = file_iotable_producer_price_medium_40_fukuoka
  ),
)

read_file_iotable_producer_price_medium_40_fukuoka <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表",
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
      export_pattern = "移輸出$",
      import_pattern = "（控除）移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
