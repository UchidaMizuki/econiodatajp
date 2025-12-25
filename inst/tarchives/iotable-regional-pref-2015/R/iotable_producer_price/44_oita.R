# https://www.pref.oita.jp/site/toukei/sangyo.html
target_iotable_producer_price_44_oita <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_44_oita,
    download_file(
      url = "https://www.pref.oita.jp/uploaded/attachment/2072846.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/44_oita.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_44_oita = read_file_iotable_producer_price_medium_44_oita(
    file = file_iotable_producer_price_medium_44_oita
  ),
)

read_file_iotable_producer_price_medium_44_oita <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "H27取引基本表（生産者価格評価表）（統合中分類104部門）",
      rows_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
    ) |>
    as_step(mutate)(
      across(
        c(input_sector_name, output_sector_name),
        \(x) str_remove_all(x, "\\s")
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
      value_scale = 1e6
    )
}
