# https://opendata.pref.aomori.lg.jp/dataset/2441.html
target_iotable_producer_price_02_aomori <- tar_plan(
  tar_change(
    file_iotable_02_aomori_108_producer_price_competitive_import_ja,
    download_file(
      url = "https://opendata.pref.aomori.lg.jp/dataset/2441/resource/28555/05_%E7%94%A3%E6%A5%AD%E9%80%A3%E9%96%A2%E8%A1%A8108%E9%83%A8%E9%96%80%E8%A1%A8_2020.xlsx",
      destfile = "_targets/user/iotable_02_aomori_108_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_02_aomori_108_producer_price_competitive_import_ja = read_file_iotable_producer_price_108_02_aomori(
    file = file_iotable_02_aomori_108_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_108_02_aomori <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "第27表",
      rows_exclude = c(1, 2)
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
      # This table names its raw export/import items "輸出計"/"移出計"/
      # "（控除）輸入計"/"（控除）移入計" (each individually carrying a
      # trailing 計, unlike every other prefecture), reserving the shared
      # "(移輸|輸移)出/入合?計" pattern in global.R for the true combined
      # "移輸出計"/"（控除）移輸入計" totals.
      export_pattern = "(輸出計|移出計)$",
      export_total_pattern = export_total_pattern,
      import_pattern = "[（\\(]控除[）\\)](輸入計|移入計)$",
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
