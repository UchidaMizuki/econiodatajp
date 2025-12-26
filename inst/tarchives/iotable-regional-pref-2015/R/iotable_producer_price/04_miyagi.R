# https://www.pref.miyagi.jp/soshiki/toukei/rennkann.html
target_iotable_producer_price_04_miyagi <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_04_miyagi,
    download_file(
      url = "https://www.pref.miyagi.jp/documents/27447/831396.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/04_miyagi.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_04_miyagi = read_file_iotable_producer_price_medium_04_miyagi(
    file = file_iotable_producer_price_medium_04_miyagi
  ),
)

read_file_iotable_producer_price_medium_04_miyagi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "H27生産者価格評価表（101部門）",
      rows_exclude = c(1:3, 5),
      cols_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c(
        "input_sector_name_1",
        "input_sector_name_2",
        "input_sector_code",
        "input_sector_name_3"
      ),
      output_names = c(
        "output_sector_name_1",
        "output_sector_name_2",
        "output_sector_code",
        "output_sector_name_3"
      )
    ) |>
    as_step(mutate)(
      across(
        starts_with(c("input_sector", "output_sector")),
        \(x) str_remove_all(x, "\\s")
      ),
      across(
        input_sector_name_1,
        \(x) if_else(x == "県内生産額", x, "", missing = "")
      ),
      across(
        c(input_sector_name_2, output_sector_name_2),
        \(x) if_else(str_detect(x, "第[一二三]次産業"), "", x, missing = "")
      ),
      across(
        c(
          input_sector_code,
          input_sector_name_3,
          output_sector_name_1,
          output_sector_code,
          output_sector_name_3
        ),
        \(x) replace_na(x, "")
      )
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name_1}{input_sector_name_2}{input_sector_name_3}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name_1}{output_sector_name_2}{output_sector_name_3}"
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = "移輸出$",
      import_pattern = "\\(控除\\)移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
