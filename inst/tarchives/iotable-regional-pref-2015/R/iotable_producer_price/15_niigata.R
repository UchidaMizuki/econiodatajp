# https://www.pref.niigata.lg.jp/site/tokei/0359813.html
target_iotable_producer_price_15_niigata <- tar_plan(
  tar_change(
    file_iotable_15_niigata_175_producer_price,
    download_file(
      url = "https://www.pref.niigata.lg.jp/uploaded/attachment/385228.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/15_niigata.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_15_niigata_175_producer_price_competitive_import_ja = read_file_iotable_producer_price_175_15_niigata(
    file = file_iotable_15_niigata_175_producer_price
  ),
)

read_file_iotable_producer_price_175_15_niigata <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "基本（175部門）",
      rows_exclude = 1:4
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
      value_scale = 1e6
    ) |>
    end_step()
}
