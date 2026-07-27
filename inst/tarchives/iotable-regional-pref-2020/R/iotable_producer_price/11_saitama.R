# https://www.pref.saitama.lg.jp/a0206/a152/2020io-main.html
target_iotable_producer_price_11_saitama <- tar_plan(
  tar_change(
    file_iotable_11_saitama_183_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.saitama.lg.jp/documents/275311/r2-18301-kihon-seisan.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/11_saitama.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_11_saitama_183_producer_price_competitive_import_ja = read_file_iotable_producer_price_183_11_saitama(
    file = file_iotable_11_saitama_183_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_183_11_saitama <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表（生産者価格183部門）",
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      export_total_pattern = "移輸出$",
      import_pattern = import_pattern,
      import_total_pattern = "移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
