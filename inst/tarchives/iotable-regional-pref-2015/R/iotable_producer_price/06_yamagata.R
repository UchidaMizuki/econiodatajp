target_iotable_producer_price_06_yamagata <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_06_yamagata,
    download_file(
      url = "https://www.pref.yamagata.jp/documents/1637/h27renkan107.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/06_yamagata.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_06_yamagata = read_file_iotable_producer_price_medium_06_yamagata(
    file = file_iotable_producer_price_medium_06_yamagata
  ),
)

read_file_iotable_producer_price_medium_06_yamagata <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "107-1",
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
    mutate(
      output_sector_name = case_match(
        output_sector_name,
        "203_石油化学基礎製品" ~ "203_石油化学系基礎製品",
        "231_なめし革・毛皮・同製品" ~ "231_なめし革・革製品・毛皮",
        .default = output_sector_name
      )
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = "移輸出",
      import_pattern = "（控除）移輸入",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
