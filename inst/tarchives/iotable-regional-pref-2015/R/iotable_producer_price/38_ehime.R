# https://www.pref.ehime.jp/opendata-catalog/dataset/2372.html
target_iotable_producer_price_38_ehime <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_38_ehime,
    download_file(
      url = "https://www.pref.ehime.jp/opendata-catalog/dataset/2372/resource/11659/h27-187bumon.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/38_ehime.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  # iotable_producer_price_small_raw_38_ehime = read_file_iotable_producer_price_small_38_ehime(
  #   file = file_iotable_producer_price_small_38_ehime
  # ),
)

read_file_iotable_producer_price_small_38_ehime <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "187部門",
      rows_exclude = 1
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
      competitive_import = TRUE,
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      export_total_pattern = export_total_pattern,
      import_pattern = str_c(import_pattern, "（控除）輸入計$", sep = "|"),
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    )
}
