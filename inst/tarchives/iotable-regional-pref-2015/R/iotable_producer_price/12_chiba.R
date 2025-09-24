# https://www.pref.chiba.lg.jp/toukei/toukeidata/sangyou/h27/27data.html
target_iotable_producer_price_12_chiba <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_12_chiba,
    download_file(
      url = "https://www.pref.chiba.lg.jp/toukei/toukeidata/sangyou/h27/documents/40-h27togo185.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/12_chiba.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_12_chiba = read_file_iotable_producer_price_small_12_chiba(
    file = file_iotable_producer_price_small_12_chiba
  ),
)

read_file_iotable_producer_price_small_12_chiba <- function(file) {
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
      industry_pattern = "^[0-6]\\d+_",
      value_added_pattern = "家計外消費支出|賃金・俸給|社会保険料|その他の給与及び手当|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|家計消費支出|対家計民間非営利団体消費支出|一般政府消費支出|県内総固定資本形成|在庫純増",
      export_pattern = "_[移輸]出$",
      import_pattern = "_（控除）[移輸]入$",
      total_pattern = "県内生産額"
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
