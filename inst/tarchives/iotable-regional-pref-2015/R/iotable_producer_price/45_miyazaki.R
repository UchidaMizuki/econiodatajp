# https://www.pref.miyazaki.lg.jp/tokeichosa/kense/toke/sangyorenkan/27toukeihyou.html
target_iotable_producer_price_45_miyazaki <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_45_miyazaki,
    download_file(
      url = "https://www.pref.miyazaki.lg.jp/documents/52621/52621_20200709154402-1.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/45_miyazaki.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_45_miyazaki = read_file_iotable_producer_price_medium_45_miyazaki(
    file = file_iotable_producer_price_medium_45_miyazaki
  ),
)

read_file_iotable_producer_price_medium_45_miyazaki <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "107部門",
      rows_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
    ) |>
    as_step(mutate)(
      across(
        output_sector_code,
        \(x) str_pad(x, 3, pad = "0")
      ),
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
      export_pattern = "移輸出計$",
      import_pattern = "（控除）輸移入計$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e4
    ) |>
    end_step()
}
