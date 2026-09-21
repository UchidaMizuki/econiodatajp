target_iotable_purchaser_price <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&lid=000001234914
    file_iotable_nation_medium_purchaser_price_competitive_import_ja,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839450&fileKind=0",
      destfile = "_targets/user/iotable_nation_medium_purchaser_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_nation_medium_purchaser_price_competitive_import_ja = read_file_iotable_purchaser_price_medium(
    file = file_iotable_nation_medium_purchaser_price_competitive_import_ja
  ),
  iotable_nation_large_purchaser_price_competitive_import_ja = convert_sector_iotable_purchaser_price_medium(
    iotable_purchaser_price_medium = iotable_nation_medium_purchaser_price_competitive_import_ja,
    sector_conversion_input = sector_conversion_nation_input,
    sector_conversion_output = sector_conversion_nation_output,
    sector_class = "large"
  ),
  iotable_nation_template_purchaser_price_competitive_import_ja = convert_sector_iotable_purchaser_price_medium(
    iotable_purchaser_price_medium = iotable_nation_medium_purchaser_price_competitive_import_ja,
    sector_conversion_input = sector_conversion_nation_input,
    sector_conversion_output = sector_conversion_nation_output,
    sector_class = "template"
  ),
  iotable_nation_medium_purchaser_price_competitive_import_en = translate_iotable_sector(
    table = iotable_nation_medium_purchaser_price_competitive_import_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "medium"
  ),
  iotable_nation_large_purchaser_price_competitive_import_en = translate_iotable_sector(
    table = iotable_nation_large_purchaser_price_competitive_import_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "large"
  ),
  iotable_nation_template_purchaser_price_competitive_import_en = translate_iotable_sector(
    table = iotable_nation_template_purchaser_price_competitive_import_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "template"
  ),
)

# Only published from "統合中分類" up (no basic/small), so this is read at
# medium and reclassified to large/template like `import_producer_price_*`.
#
# `total_pattern` is deliberately not passed. This workbook's trailing
# "891_商業マージン"/"901_貨物運賃" output columns reconcile each row's
# purchaser-price sum back to its "970_国内生産額" (crediting the economy-wide
# trade/transport margins to the commerce/transport rows), and have no
# sector_type of their own, so they are dropped along with "880_最終需要部門計".
# Without them the row sums no longer equal the 国内生産額 column, and
# `econio::io_check_totals()` errors. Leaving `total` empty makes it skip that
# check instead; the transaction cells themselves are e-stat's own values.
read_file_iotable_purchaser_price_medium <- function(file) {
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
      import_type = "competitive_import",
      industry_total_pattern = "内生部門計$",
      value_added_total_pattern = "粗付加価値部門計$",
      final_demand_total_pattern = "国内最終需要計$",
      export_pattern = "輸出",
      export_total_pattern = "輸出計$",
      import_pattern = "（控除）(輸入|関税|輸入品商品税)",
      import_total_pattern = "（控除）輸入計$"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      check_axes = TRUE
    ) |>
    end_step()
}

convert_sector_iotable_purchaser_price_medium <- function(
  iotable_purchaser_price_medium,
  sector_conversion_input,
  sector_conversion_output,
  sector_class
) {
  input_sector_data <- sector_conversion_input |>
    filter(
      sector_type %in% c("industry", "value_added"),
      sector_class_from == "medium",
      sector_class_to == .env$sector_class
    ) |>
    select(from = sector_name_from_ja, to = sector_name_to_ja) |>
    add_column(weight = 1)

  output_sector_data <- sector_conversion_output |>
    filter(
      sector_type %in% c("industry", "final_demand", "export", "import"),
      sector_class_from == "medium",
      sector_class_to == .env$sector_class
    ) |>
    select(from = sector_name_from_ja, to = sector_name_to_ja) |>
    add_column(weight = 1)

  iotable_purchaser_price_medium |>
    io_reclass(
      input_sector_data = input_sector_data,
      output_sector_data = output_sector_data
    )
}
