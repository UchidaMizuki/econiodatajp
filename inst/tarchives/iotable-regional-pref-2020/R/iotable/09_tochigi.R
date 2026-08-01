# https://www.pref.tochigi.lg.jp/c04/pref/toukei/toukei/io.html
target_iotable_producer_price_09_tochigi <- tar_plan(
  tar_change(
    file_iotable_09_tochigi_185_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.tochigi.lg.jp/c04/pref/toukei/toukei/documents/r2_185bumonhyou.xlsx",
      destfile = "_targets/user/iotable_09_tochigi_185_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_09_tochigi_185_producer_price_competitive_import_ja = read_file_iotable_producer_price_185_09_tochigi(
    file = file_iotable_09_tochigi_185_producer_price_competitive_import_ja
  ),
)

# TODO: The workbook doesn't state a unit anywhere on the sheet;
# `value_scale = 1e6` matches the 2015 table and every neighboring
# prefecture but hasn't been independently confirmed for this table.
read_file_iotable_producer_price_185_09_tochigi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "185(1)取引基本表",
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      # The workbook's export/import totals lack a trailing 計 (8120_移輸出,
      # 8820_（控除）移輸入), so the shared patterns in global.R don't match
      # them.
      export_total_pattern = "移輸出$",
      import_pattern = import_pattern,
      import_total_pattern = "[（\\(]控除[）\\)]移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
