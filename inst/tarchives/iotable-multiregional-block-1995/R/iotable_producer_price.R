# https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_1.html
# METI's official 9-region (block) interregional table, FY1995 (H7).
# Unlike the FY1970-1990 batch (see the FY1970 tarchive's comment), METI
# published this vintage separately, on 2013-12-06, as a set of reference
# tables alongside a 3-region-by-3-sector summary; we use its "9地域46部門
# 表" reference workbook, the only one at full region/sector detail. Same
# 9 regions (北海道/東北/関東/中部/近畿/中国/四国/九州/沖縄) and total
# row/column labels as FY1980-1990 ("地域内最終需要計"/"粗付加価値部門計"),
# verified against this workbook's own header cells; this vintage's single
# granularity has 46 sectors, so `sector_class = "46"`.
#
# One quirk unique to this workbook: every other vintage's "地域内生産額"
# (total_pattern) appears as a column header only once, for the "地域計"
# aggregate region dropped below -- so on the output/column side it never
# actually matches any real region, and io_check_totals() (called from
# io_table_read_data()) skips the output-total check entirely (it only
# runs when a match exists). This workbook has one extra, stray copy under
# 沖縄, the last real region; left in, that one copy gets treated as
# *the* output total, and every other region's industry cells get checked
# against Okinawa's alone, which is wrong regardless of value_scale. Since
# 沖縄 has its own correct "地域内最終需要計" already, and no other vintage
# needs an output-side "地域内生産額" at all, this stray copy is dropped
# outright rather than kept as if it meant something.
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_nation_46_producer_price,
    download_file_meti(
      url = "https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_1/xls/h2rio95c.xlsx",
      destfile = "_targets/user/iotable/producer_price/46.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_nation_46_producer_price_competitive_import_ja = read_file_iotable_producer_price(
    file = file_iotable_nation_46_producer_price,
    sheet = "取引額(46部門MTX)"
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
    # Drops a stray output-side "地域内生産額" column under 沖縄 that no
    # other vintage has -- see the comment above.
    as_step(filter)(
      output_sector_name != "地域内生産額"
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
      import_type = "competitive_import",
      industry_total_pattern = "内生部門計$",
      value_added_total_pattern = "粗付加価値部門計$",
      final_demand_total_pattern = "地域内最終需要計$",
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
