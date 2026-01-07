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
  ),
  import_producer_price_large = convert_sector_import_producer_price_medium(
    import_producer_price_medium = import_producer_price_medium,
    conversion_sector_input = conversion_sector_input,
    conversion_sector_output = conversion_sector_output,
    sector_class = "large"
  ),
  import_producer_price_template = convert_sector_import_producer_price_medium(
    import_producer_price_medium = import_producer_price_medium,
    conversion_sector_input = conversion_sector_input,
    conversion_sector_output = conversion_sector_output,
    sector_class = "template"
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
    ) |>
    end_step()
}

convert_sector_import_producer_price_medium <- function(
  import_producer_price_medium,
  conversion_sector_input,
  conversion_sector_output,
  sector_class
) {
  input_sector_data <- conversion_sector_input |>
    filter(
      sector_type == "industry",
      sector_class_from == "medium",
      sector_class_to == .env$sector_class
    ) |>
    select(sector_name_from, sector_name_to) |>
    rename(from = sector_name_from, to = sector_name_to) |>
    add_column(weight = 1)

  output_sector_data <- conversion_sector_output |>
    filter(
      sector_type %in% c("industry", "final_demand", "export"),
      sector_class_from == "medium",
      sector_class_to == .env$sector_class
    ) |>
    select(sector_name_from, sector_name_to) |>
    rename(from = sector_name_from, to = sector_name_to) |>
    add_column(weight = 1)

  import_producer_price_medium |>
    io_reclass(
      input_sector_data = input_sector_data,
      output_sector_data = output_sector_data
    )
}
