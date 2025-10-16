target_iotable_producer_price <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200603&tstat=000001130583&cycle=0&year=20150&month=0
    file_iotable_producer_price_basic,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839445&fileKind=0",
      destfile = "_targets/user/iotable/producer_price/basic.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200603&tstat=000001130583&cycle=0&year=20150&month=0
    file_iotable_producer_price_small,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839446&fileKind=0",
      destfile = "_targets/user/iotable/producer_price/small.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_basic = read_file_iotable_producer_price_basic(
    file = file_iotable_producer_price_basic
  ),
  iotable_producer_price_small = read_file_iotable_producer_price_small(
    file = file_iotable_producer_price_small
  ),
)

read_file_iotable_producer_price <- function(file, check_axis) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = 1,
      rows_exclude = 1
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
      industry_pattern = "^[0-6]",
      value_added_pattern = "^(7[1-9]|8|9[1-5])",
      final_demand_pattern = "^7[1-6]",
      export_pattern = "^80",
      import_pattern = "^8[4-6]",
      total_pattern = "^97"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      check_axis = check_axis
    ) |>
    end_step()
}
read_file_iotable_producer_price_basic <- function(file) {
  read_file_iotable_producer_price(file, check_axis = FALSE)
}
read_file_iotable_producer_price_small <- function(file) {
  read_file_iotable_producer_price(file, check_axis = TRUE)
}
