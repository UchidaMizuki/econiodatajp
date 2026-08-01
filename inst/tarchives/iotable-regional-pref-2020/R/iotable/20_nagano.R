# https://tokei.pref.nagano.lg.jp/statistics/27800.html
target_iotable_producer_price_20_nagano <- tar_plan(
  tar_change(
    file_iotable_20_nagano_188_producer_price_competitive_import_ja,
    download_file(
      url = "https://tokei.pref.nagano.lg.jp/statistics-info/statistics_download?pid=27800&type=excel",
      destfile = "_targets/user/iotable_20_nagano_188_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_20_nagano_188_producer_price_competitive_import_ja = read_file_iotable_producer_price_188_20_nagano(
    file = file_iotable_20_nagano_188_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_188_20_nagano <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "取引基本表",
      rows_exclude = c(1, 2)
    ) |>
    # Unlike every other prefecture, headers here carry a leading serial
    # number ("1", "2", ...) ahead of the actual sector code -- read it but
    # drop it, keeping only code/name for the glued sector name.
    io_table_read_headers(
      input_names = c(
        "input_sector_index",
        "input_sector_code",
        "input_sector_name"
      ),
      output_names = c(
        "output_sector_index",
        "output_sector_code",
        "output_sector_name"
      )
    ) |>
    as_step(select)(
      -"input_sector_index",
      -"output_sector_index"
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
