# https://web.pref.hyogo.lg.jp/kk11/hyogoio/hyogoio2015.html
target_iotable_producer_price_28_hyogo <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_28_hyogo,
    download_file(
      url = "https://web.pref.hyogo.lg.jp/kk11/hyogoio/documents/hyogoio2015-185bumon.xlsx",
      destfile = "_targets/user/iotable/producer_price/small/28_hyogo.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_28_hyogo = read_file_iotable_producer_price_small_28_hyogo(
    file = file_iotable_producer_price_small_28_hyogo
  ),
)

read_file_iotable_producer_price_small_28_hyogo <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
      rows_exclude = 1:3,
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
      competitive_import = TRUE,
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      import_pattern = import_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
