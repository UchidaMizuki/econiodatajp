# https://www.pref.tochigi.lg.jp/c04/pref/toukei/toukei/ioh2-.html
target_iotable_producer_price_09_tochigi <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_09_tochigi,
    download_file(
      url = "https://www.pref.tochigi.lg.jp/c04/pref/toukei/toukei/documents/h27_102bumonhyou2.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/09_tochigi.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_102_ja_09_tochigi = read_file_iotable_producer_price_small_09_tochigi(
    file = file_iotable_producer_price_small_09_tochigi
  ),
)

read_file_iotable_producer_price_small_09_tochigi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "102(1)取引基本表",
      rows_exclude = 1,
      cols_exclude = 1
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
      export_pattern = export_pattern,
      # The workbook's export/import totals lack a trailing 計 (812_移輸出,
      # 882_（控除）移輸入), so the shared patterns in global.R don't match
      # them.
      export_total_pattern = "移輸出$",
      import_pattern = import_pattern,
      import_total_pattern = "[（\\(]控除[）\\)]移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
