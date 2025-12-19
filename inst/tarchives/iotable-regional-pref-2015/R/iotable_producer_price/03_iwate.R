target_iotable_producer_price_03_iwate <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_03_iwate,
    download_file(
      url = "https://www3.pref.iwate.jp/webdb/view/outside/s14Tokei/tokei.download?fileId=s14TokeiInfo-1ueP1W.18OYJ.R8hi3",
      destfile = "_targets/user/iotable/producer_price/small/03_iwate.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_03_iwate = read_file_iotable_producer_price_small_03_iwate(
    file = file_iotable_producer_price_small_03_iwate
  ),
)

read_file_iotable_producer_price_small_03_iwate <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "①生産者価格評価表",
      rows_exclude = 1:2
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
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      export_total_pattern = "移輸出",
      import_pattern = import_pattern,
      import_total_pattern = "（控除）移輸入",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e3
    ) |>
    end_step()
}
