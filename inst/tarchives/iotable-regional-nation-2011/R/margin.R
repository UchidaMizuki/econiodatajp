target_margin <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?stat_infid=000030138089
    file_margin_nation_medium_trade_margin_ja,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000030138089&fileKind=0",
      destfile = "_targets/user/margin_nation_medium_trade_margin_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?stat_infid=000030138091
    file_margin_nation_medium_domestic_freight_ja,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000030138091&fileKind=0",
      destfile = "_targets/user/margin_nation_medium_domestic_freight_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  margin_nation_medium_trade_margin_ja = read_file_margin(
    file = file_margin_nation_medium_trade_margin_ja
  ),
  margin_nation_medium_domestic_freight_ja = read_file_margin(
    file = file_margin_nation_medium_domestic_freight_ja
  ),
  margin_nation_medium_trade_margin_en = translate_iotable_sector(
    table = margin_nation_medium_trade_margin_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "medium"
  ),
  margin_nation_medium_domestic_freight_en = translate_iotable_sector(
    table = margin_nation_medium_domestic_freight_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "medium"
  ),
)

# See iotable-regional-nation-2015/R/margin.R's read_file_margin() for why
# both tables share this one reader and why value_added/import/total
# patterns are left unset.
read_file_margin <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = 1,
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
    io_table_read_sector_types(
      import_type = "noncompetitive_import",
      industry_total_pattern = "内生部門計$",
      final_demand_total_pattern = "国内最終需要計$",
      export_pattern = "輸出",
      export_total_pattern = "輸出計$"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      check_axes = TRUE
    ) |>
    end_step()
}
