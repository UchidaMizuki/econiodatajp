# https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_3.html
# METI's official 9-region (block) interregional table, FY1980 (S55); see
# the FY1970 tarchive's comment for the shared background (one of the
# FY1970-1990 batch METI put online on 2014-02-04, single 43-sector
# workbook, so `sector_class = "43"`, 9 regions 北海道/東北/関東/中部/近畿/
# 中国/四国/九州/沖縄). Its total row/column
# labels (verified against this workbook's own header cells) match FY1980
# through FY2005: "地域内最終需要計"/"粗付加価値部門計", not FY1970's
# "最終需要部門計" or FY1975's "付加価値部門計".
#
# One quirk unique to 北海道 in this workbook: every other region's output
# side codes its final-demand total column "500_地域内最終需要計" (and its
# own export column "510_輸出", etc.), but 北海道 alone uses "495"/"500" for
# those same two columns -- same text, different code, so before
# io_table_read_sector_names() glues code and name together, this would
# otherwise leave two distinct glued sector names ("495_..." and
# "500_...") for what's really one final-demand total, and
# final_demand_total_pattern requires exactly one match.
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_nation_43_producer_price,
    download_file_meti(
      url = "https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_3/xlsx/h2rio80a.xlsx",
      destfile = "_targets/user/iotable/producer_price/43.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_nation_43_producer_price_competitive_import_ja = read_file_iotable_producer_price(
    file = file_iotable_nation_43_producer_price,
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
    # Normalizes 北海道's stray "495" code to "500", matching every other
    # region -- see the comment above.
    as_step(mutate)(
      output_sector_code = if_else(
        output_region_name == "北海道" & output_sector_code == "495",
        "500",
        output_sector_code
      )
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
