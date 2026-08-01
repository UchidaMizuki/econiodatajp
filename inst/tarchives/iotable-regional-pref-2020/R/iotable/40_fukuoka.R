# https://data.bodik.jp/dataset/1507ebf2-79fc-4a4d-8028-4662d79f2b2e
target_iotable_producer_price_40_fukuoka <- tar_plan(
  tar_change(
    file_iotable_40_fukuoka_107_producer_price_competitive_import_ja,
    download_file(
      url = "https://data.bodik.jp/dataset/1507ebf2-79fc-4a4d-8028-4662d79f2b2e/resource/15f05dcb-71ba-4fc8-9f87-10aafaf903c8/download/r2io-107bumon.xlsx",
      destfile = "_targets/user/iotable_40_fukuoka_107_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_40_fukuoka_107_producer_price_competitive_import_ja = read_file_iotable_producer_price_107_40_fukuoka(
    file = file_iotable_40_fukuoka_107_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_107_40_fukuoka <- function(file) {
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      import_pattern = "[（\\(]控除[）\\)][移輸]+入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
