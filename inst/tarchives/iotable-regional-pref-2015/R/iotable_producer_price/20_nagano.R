# https://www.pref.nagano.lg.jp/tokei/tyousa/sangyorenkan.html
# https://tokei.pref.nagano.lg.jp/statist_list/1876.html
target_iotable_producer_price_20_nagano <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_20_nagano,
    download_file(
      url = "https://tokei.pref.nagano.lg.jp/statistics-info/statistics_download?pid=18716&type=excel",
      destfile = "_targets/user/iotable/producer_price/small/20_nagano.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_20_nagano = read_file_iotable_producer_price_small_20_nagano(
    file = file_iotable_producer_price_small_20_nagano
  ),
)

read_file_iotable_producer_price_small_20_nagano <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
      rows_exclude = 1:3
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
    mutate(
      input_sector_name = case_match(
        input_sector_name,
        "0621_砂利・採石" ~ "0621_砂利・砕石",
        "1511_紡績" ~ "1511_紡績糸",
        .default = input_sector_name
      )
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
      value_scale = 1e4
    ) |>
    end_step()
}
