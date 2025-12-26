# https://opendata.pref.kagawa.lg.jp/dataset/360.html
target_iotable_producer_price_37_kagawa <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_37_kagawa,
    download_file(
      url = "https://opendata.pref.kagawa.lg.jp/dataset/360/resource/4445/27_107%E9%83%A8%E9%96%80%E8%A1%A8%EF%BC%88%E7%94%9F%E7%94%A3%E8%80%85%E4%BE%A1%E6%A0%BC%E8%A9%95%E4%BE%A1%E8%A1%A8%EF%BC%89.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/37_kagawa.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_37_kagawa = read_file_iotable_producer_price_medium_37_kagawa(
    file = file_iotable_producer_price_medium_37_kagawa
  ),
)

read_file_iotable_producer_price_medium_37_kagawa <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
      rows_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
    ) |>
    as_step(mutate)(
      across(input_sector_code, \(x) str_replace(x, "\\r\\n", "・")),
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
      export_total_pattern = export_total_pattern,
      import_pattern = str_c(import_pattern, "移輸入$", sep = "|"),
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
