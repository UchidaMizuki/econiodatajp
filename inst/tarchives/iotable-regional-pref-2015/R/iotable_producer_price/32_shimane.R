# https://pref.shimane-toukei.jp/index.php?view=21470
target_iotable_producer_price_32_shimane <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_32_shimane,
    download_file(
      url = "https://pref.shimane-toukei.jp/upload/user/00021475-AnYR6c.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/32_shimane.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_32_shimane = read_file_iotable_producer_price_medium_32_shimane(
    file = file_iotable_producer_price_medium_32_shimane
  ),
)

read_file_iotable_producer_price_medium_32_shimane <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "基本表",
      rows_exclude = 1:3
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
    ) |>
    as_step(mutate)(
      across(
        c(input_sector_code, output_sector_code),
        \(x) str_pad(x, 3, pad = "0")
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
      value_scale = 1e6,
      # FIXME?: Shimane IO table has large rounding errors
      total_tolerance = 1e7
    )
}
