# https://www.toukei.metro.tokyo.lg.jp/sanren/2015/sr15t1.htm
target_iotable_producer_price_13_tokyo <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_13_tokyo,
    download_file(
      url = "https://www.toukei.metro.tokyo.lg.jp/sanren/2015/sr15ta_nai11.xls",
      destfile = "_targets/user/iotable/producer_price/small/13_tokyo.xls"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_13_tokyo = read_file_iotable_producer_price_small_13_tokyo(
    file = file_iotable_producer_price_small_13_tokyo
  ),
)

read_file_iotable_producer_price_small_13_tokyo <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "(地域内表）取引基本表　統合小分類",
      rows_exclude = 1:3,
      cols_exclude = 1
    ) |>
    io_table_read_headers(
      input_names = c("input_sector_code", "input_sector_name"),
      output_names = c("output_sector_code", "output_sector_name")
    ) |>
    as_step(mutate)(
      across(
        c(input_sector_code, output_sector_code),
        \(x) str_remove(x, "^[:upper:]")
      )
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name}"
    ) |>
    as_step(filter)(
      !str_detect(input_sector_name, "財・サービス内生部門計$"),
      !str_detect(output_sector_name, "財・サービス内生部門計$")
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
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
