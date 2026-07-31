# https://www.pref.wakayama.lg.jp/prefg/020300/sangyo/R2/d00220299.html
# TODO: as of the 2026-07 survey behind issue #26, this was still labeled a
# preliminary release (速報版), with a finalized version (確定版) expected
# later in FY2025 -- re-check the source page periodically and update the
# URL/values once the finalized version replaces it.
target_iotable_producer_price_30_wakayama <- tar_plan(
  tar_change(
    file_iotable_30_wakayama_108_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.wakayama.lg.jp/prefg/020300/sangyo/R2/d00220299_d/fil/108Sector_2020.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/30_wakayama.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_30_wakayama_108_producer_price_competitive_import_ja = read_file_iotable_producer_price_108_30_wakayama(
    file = file_iotable_30_wakayama_108_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_108_30_wakayama <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "108部門表",
      rows_exclude = c(2, 3, 6)
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = "移輸出計$",
      import_pattern = "[（\\(]控除[）\\)]移輸入計$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
