# https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_02.html
# METI's official 9-region (block) interregional table, FY2005 (H17); the
# only benchmark year published (the FY2000 table was never officially
# released, and no later edition exists). Distributed as three sector
# granularities of the same MTX-format transaction sheet -- 12/29/53
# sectors -- mapped onto sector_class small/medium/large respectively, the
# same convention as the nation table's basic/small/medium/large/template.
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_small,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000020467390&fileKind=0",
      destfile = "_targets/user/iotable/producer_price/small.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small = read_file_iotable_producer_price(
    file = file_iotable_producer_price_small,
    sheet = "取引額(12部門MTX)"
  ),
  tar_change(
    file_iotable_producer_price_medium,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000020467391&fileKind=0",
      destfile = "_targets/user/iotable/producer_price/medium.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium = read_file_iotable_producer_price(
    file = file_iotable_producer_price_medium,
    sheet = "取引額(29部門MTX)"
  ),
  tar_change(
    file_iotable_producer_price_large,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000020467392&fileKind=0",
      destfile = "_targets/user/iotable/producer_price/large.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_large = read_file_iotable_producer_price(
    file = file_iotable_producer_price_large,
    sheet = "取引額(53部門MTX)"
  )
)

# Shared by all three sector granularities -- the MTX sheet layout (2 title
# rows, then 4 header rows/columns for region_code/region_name/sector_code/
# sector_name, then data) and sector-name suffixes ("内生部門計" etc.) are
# identical across the 12/29/53-sector workbooks, only the sheet name and
# actual sector codes/counts differ.
read_file_iotable_producer_price <- function(file, sheet) {
  io_table_reader(file, region_type = "multiregional") |>
    io_table_read_cells(
      sheets = sheet,
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
    # Drops trailing blank rows in the 53-sector sheet (a no-op for
    # 12/29-sector, which have none).
    as_step(filter)(
      !is.na(input_region_code) & !is.na(output_region_code)
    ) |>
    io_table_read_regions(
      input_region_glue = "{input_region_code}_{input_region_name}",
      output_region_glue = "{output_region_code}_{output_region_name}"
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name}"
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_total_pattern = "内生部門計$",
      value_added_total_pattern = "粗付加価値部門計$",
      final_demand_total_pattern = "地域内最終需要計$",
      export_pattern = "輸出$",
      import_pattern = "（控除）輸入$",
      total_pattern = "地域内生産額$"
    ) |>
    # "地域計" is METI's own aggregate-of-the-9-regions row/column (parallel
    # to RIETI's "都道府県合計" for the 47-prefecture table); drop it since
    # it's a derived total, not one of the 9 regions.
    as_step(filter)(
      !if_any(
        c(input_region, output_region),
        \(x) str_detect(x, "地域計$")
      )
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
