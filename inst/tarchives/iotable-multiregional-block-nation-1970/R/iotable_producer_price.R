# https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_3.html
# METI's official 9-region (block) interregional table, FY1970 (S45). METI
# (as 通商産業省, continuously since its first 1960 edition) has produced a
# benchmark-year block table every 5 years; FY2005 is the only vintage
# e-stat.go.jp hosts (see the sibling -2005 tarchive), but METI's own site
# separately hosts FY1970-1990 as a single-file-per-year batch it put
# online on 2014-02-04 (hence download_file_meti() -- meti.go.jp, unlike
# e-stat.go.jp, blocks a plain download.file() request). FY2005's workbook
# has three sector granularities (12/29/53 sectors); this vintage was only
# published at one. METI's documentation doesn't name any block-table
# sector granularity, only its sector count, so `sector_class` here is
# that count itself: "43".
#
# The 9 regions match FY1975 onward (see that tarchive) except 中部/沖縄:
# this vintage still splits 中部 into 東海/北陸 and predates Okinawa's 1972
# reversion, so it has no 沖縄 region -- both 9-region, just partitioned
# differently (see 経済産業研究所 (2016) "経済産業省の地域産業連関表の作成
# について", 産業連関 Vol.23 No.1-2, table 1).
#
# Two totals use different labels here than every later vintage (verified
# against this workbook's own header cells, not assumed from FY2005):
# final demand's total row/column reads "最終需要部門計" here, not
# "地域内最終需要計" (which only appears from FY1975 on).
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_43,
    download_file_meti(
      url = "https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_3/xlsx/h2rio70a.xlsx",
      destfile = "_targets/user/iotable/producer_price/43.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_43_ja = read_file_iotable_producer_price(
    file = file_iotable_producer_price_43,
    sheet = "取引額（43部門MTX）"
  )
)

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
      final_demand_total_pattern = "最終需要部門計$",
      export_pattern = "輸出$",
      import_pattern = "（控除）輸入$",
      total_pattern = "地域内生産額$"
    ) |>
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
