target_import_producer_price <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200603&tstat=000001130583&cycle=0&year=20150&month=0&tclass1val=0
    file_import_producer_price_medium,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839515&fileKind=0",
      destfile = "_targets/user/import/producer_price/medium.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  import_producer_price_medium = read_file_import_producer_price_medium(
    file = file_import_producer_price_medium
  )
)

read_file_import_producer_price_medium <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "輸入表　(統合中分類)",
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
      industry_total_pattern = "内生部門計$",
      final_demand_total_pattern = "国内最終需要計$",
      export_pattern = "輸出$",
      export_total_pattern = "輸出計$"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      check_axes = FALSE
    )
}
