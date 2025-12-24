# https://www.pref.mie.lg.jp/DATABOX/00006816699_00001.htm
# https://www.pref.mie.lg.jp/common/content/000910433.xlsx

target_iotable_producer_price_24_mie <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_24_mie,
    download_file(
      url = "https://www.pref.mie.lg.jp/common/content/000910433.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/24_mie.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_24_mie = read_file_iotable_producer_price_small_24_mie(
    file = file_iotable_producer_price_small_24_mie
  ),
)

read_file_iotable_producer_price_small_24_mie <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "4-1",
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
