# https://www.pref.osaka.lg.jp/o040090/toukei/sanren/sanren_k-io20k000xls.html
target_iotable_producer_price_27_osaka <- tar_plan(
  tar_change(
    file_iotable_27_osaka_108_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.osaka.lg.jp/documents/121666/r02k_108.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/27_osaka.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_27_osaka_108_producer_price_competitive_import_ja = read_file_iotable_producer_price_108_27_osaka(
    file = file_iotable_27_osaka_108_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_108_27_osaka <- function(file) {
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      import_pattern = import_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
