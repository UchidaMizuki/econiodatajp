# https://toukei.pref.gunma.jp/gio/gio2020.html
target_iotable_producer_price_10_gunma <- tar_plan(
  tar_change(
    file_iotable_10_gunma_108_producer_price_competitive_import_ja,
    download_file(
      url = "https://toukei.pref.gunma.jp/gio/data/2020iot03.xlsx",
      destfile = "_targets/user/iotable_10_gunma_108_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_10_gunma_108_producer_price_competitive_import_ja = read_file_iotable_producer_price_108_10_gunma(
    file = file_iotable_10_gunma_108_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_108_10_gunma <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "3-（1）",
      rows_exclude = 2,
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
      export_total_pattern = export_total_pattern,
      import_pattern = import_pattern,
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
