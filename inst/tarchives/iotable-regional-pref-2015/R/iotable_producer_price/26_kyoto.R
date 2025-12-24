# https://www.pref.kyoto.jp/tokei/cycle/sanren/sanrentop.html
target_iotable_producer_price_26_kyoto <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_26_kyoto,
    download_file(
      url = "https://www.pref.kyoto.jp/tokei/cycle/sanren/documents/sanren2015_105bumon.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/26_kyoto.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_26_kyoto = read_file_iotable_producer_price_medium_26_kyoto(
    file = file_iotable_producer_price_medium_26_kyoto
  ),
)

read_file_iotable_producer_price_medium_26_kyoto <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "1.取引基本表",
      rows_exclude = 1,
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
      value_scale = 1e4
    ) |>
    end_step()
}
