# https://toukei.pref.shizuoka.jp/bunsekihan/data/h27_187.html
target_iotable_producer_price_22_shizuoka <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_22_shizuoka,
    download_file(
      url = "https://toukei.pref.shizuoka.jp/bunsekihan/data/documents/h27_187kihon.xls",
      destfile = "_targets/user/iotable/producer_price/small/22_shizuoka.xls"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_22_shizuoka = read_file_iotable_producer_price_small_22_shizuoka(
    file = file_iotable_producer_price_small_22_shizuoka
  ),
)

read_file_iotable_producer_price_small_22_shizuoka <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "187部門",
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
    as_step(mutate)(
      output_sector_name = str_remove_all(
        .data$output_sector_name,
        "\\s"
      )
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      import_pattern = import_pattern,
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
