# https://www.pref.okayama.jp/page/detail-16600.html
target_iotable_producer_price_33_okayama <- tar_plan(
  tar_change(
    file_iotable_33_okayama_188_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.okayama.jp/uploaded/attachment/410658.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/33_okayama.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_33_okayama_188_producer_price_competitive_import_ja = read_file_iotable_producer_price_188_33_okayama(
    file = file_iotable_33_okayama_188_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_188_33_okayama <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
      rows_exclude = 1:3
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
      # The sheet's combined deduction column is "（控除）移輸入" (3 chars:
      # 移+輸+入), which the shared `import_pattern`'s "[移輸]入" alternative
      # doesn't match (it expects a single 移/輸 character directly before
      # 入, not both). Same fix as 34_hiroshima.R/40_fukuoka.R.
      import_pattern = "[（\\(]控除[）\\)][移輸]+入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
