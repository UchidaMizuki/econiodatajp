target_iotable_producer_price_05_akita <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_05_akita,
    download_file(
      url = "https://www.pref.akita.lg.jp/uploads/public/archive_0000053289_00/27-3%E5%85%AC%E8%A1%A8%E7%94%A8%E3%83%87%E3%83%BC%E3%82%BF%EF%BC%88107%E9%83%A8%E9%96%80%E5%88%86%E9%A1%9E%EF%BC%89ok.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/05_akita.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_05_akita = read_file_iotable_producer_price_medium_05_akita(
    file = file_iotable_producer_price_medium_05_akita
  ),
)

read_file_iotable_producer_price_medium_05_akita <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
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
      export_pattern = "輸移出",
      import_pattern = "（控除）輸移入",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
