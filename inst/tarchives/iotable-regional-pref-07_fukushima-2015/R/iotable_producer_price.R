# iotable_producer_price --------------------------------------------------

target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium,
    download_file(
      url = "https://www.pref.fukushima.lg.jp/uploaded/attachment/392561.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw = read_file_iotable_producer_price_medium(
    file = file_iotable_producer_price_medium
  ),
)

read_file_iotable_producer_price_medium <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表",
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
      industry_pattern = "^(0\\d+|10[0-5])_",
      value_added_pattern = "家計外消費支出|賃金・俸給|社会保険料|その他の給与及び手当|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|民間消費支出|一般政府消費支出|県内総固定資本形成|在庫純増",
      export_pattern = "_[移輸]出$",
      import_pattern = "_（控除）(輸入|関税|輸入品商品税|移入)$",
      total_pattern = "県内生産額"
    ) |>
    io_table_read_data(
      scale = 1e6
    ) |>
    end_step()
}
