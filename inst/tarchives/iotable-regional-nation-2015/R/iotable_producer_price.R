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
  iotable_producer_price_basic = read_file_iotable_producer_price_basic(
    file = file_iotable_producer_price_basic
  ),
  iotable_producer_price_small = convert_sector_iotable_producer_price_basic(
    iotable_producer_price_basic = iotable_producer_price_basic,
    conversion_sector_input = conversion_sector_input,
    conversion_sector_output = conversion_sector_output,
    sector_class = "small"
  ),
  iotable_producer_price_medium = convert_sector_iotable_producer_price_basic(
    iotable_producer_price_basic = iotable_producer_price_basic,
    conversion_sector_input = conversion_sector_input,
    conversion_sector_output = conversion_sector_output,
    sector_class = "medium"
  ),
  iotable_producer_price_large = convert_sector_iotable_producer_price_basic(
    iotable_producer_price_basic = iotable_producer_price_basic,
    conversion_sector_input = conversion_sector_input,
    conversion_sector_output = conversion_sector_output,
    sector_class = "large"
  ),
  iotable_producer_price_template = convert_sector_iotable_producer_price_basic(
    iotable_producer_price_basic = iotable_producer_price_basic,
    conversion_sector_input = conversion_sector_input,
    conversion_sector_output = conversion_sector_output,
    sector_class = "template"
  ),
)

read_file_iotable_producer_price_basic <- function(file) {
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
      industry_total_pattern = "内生部門計$",
      value_added_total_pattern = "粗付加価値部門計$",
      final_demand_total_pattern = "国内最終需要計$",
      export_pattern = "輸出",
      export_total_pattern = "輸出計$",
      import_pattern = "（控除）(輸入|関税|輸入品商品税)",
      import_total_pattern = "（控除）輸入計$",
      total_pattern = "国内生産額$"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      check_axes = FALSE
    ) |>
    end_step()
}

convert_sector_iotable_producer_price_basic <- function(
  iotable_producer_price_basic,
  conversion_sector_input,
  conversion_sector_output,
  sector_class
) {
  input_sector_data <- conversion_sector_input |>
    filter(
      sector_type %in% c("industry", "value_added"),
      sector_class_from == "basic",
      sector_class_to == .env$sector_class
    ) |>
    select(sector_name_from, sector_name_to) |>
    rename(from = sector_name_from, to = sector_name_to) |>
    add_column(weight = 1)

  output_sector_data <- conversion_sector_output |>
    filter(
      sector_type %in% c("industry", "final_demand", "export", "import"),
      sector_class_from == "basic",
      sector_class_to == .env$sector_class
    ) |>
    select(sector_name_from, sector_name_to) |>
    rename(from = sector_name_from, to = sector_name_to) |>
    add_column(weight = 1)

  iotable_producer_price <- iotable_producer_price_basic |>
    io_reclass(
      input_sector_data = input_sector_data,
      output_sector_data = output_sector_data,
      check_axes = FALSE
    )

  dim_names <- dimnames(iotable_producer_price)
  input <- dim_names$input
  output <- dim_names$output
  output <- bind_rows(
    input |>
      filter(io_sector_type(sector) == "industry"),
    output |>
      filter(io_sector_type(sector) != "industry")
  )

  iotable_producer_price |>
    dibble::broadcast(dim_names = list(input = input, output = output)) |>
    dibble::broadcast(dim_names = c("input", "output")) |>
    replace_na(0) |>
    io_check_axes()
}
