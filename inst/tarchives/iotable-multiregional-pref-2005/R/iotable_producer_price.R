# https://www.rieti.go.jp/jp/database/R-JIP2005/index.html
# RIETI never names this table's sector granularity with a classification
# tier (the workbook and the database page only ever call it the "26部門"
# table -- R-JIP 23 sectors plus 事務用品/分類不明/本社), so `sector_class`
# is that count itself ("26"), the same convention as the block tarchives.
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_nation_26_producer_price,
    download_file(
      url = "https://www.rieti.go.jp/jp/database/R-JIP2005/data/I-preIO2005.xlsx",
      destfile = "_targets/user/iotable/producer_price/26.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_nation_26_producer_price_competitive_import_ja = read_file_iotable_producer_price_26(
    file = file_iotable_nation_26_producer_price
  )
)

read_file_iotable_producer_price_26 <- function(file) {
  io_table_reader(file, region_type = "multiregional") |>
    io_table_read_cells(
      sheets = "取引額表",
      rows_exclude = 1:2
    ) |>
    io_table_read_headers(
      input_names = c(
        "input_region_code",
        "input_region_name",
        "input_sector_code",
        "input_sector_name"
      ),
      output_names = c(
        "output_region_code",
        "output_region_name",
        "output_sector_code",
        "output_sector_name"
      )
    ) |>
    io_table_read_regions(
      input_region_glue = "{input_region_code}_{input_region_name}",
      output_region_glue = "{output_region_code}_{output_region_name}"
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
      industry_total_pattern = "内生部門計$",
      value_added_total_pattern = "粗付加価値部門計$",
      final_demand_total_pattern = "県内最終需要計$",
      export_pattern = "輸出$",
      import_pattern = "（控除）輸入$",
      total_pattern = "県内生産額$"
    ) |>
    as_step(filter)(
      !if_any(
        c(input_region, output_region),
        \(x) str_detect(x, "都道府県合計$")
      )
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e7
    ) |>
    end_step()
}
