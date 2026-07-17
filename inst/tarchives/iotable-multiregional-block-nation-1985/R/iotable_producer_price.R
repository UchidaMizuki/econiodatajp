# https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_3.html
# METI's official 9-region (block) interregional table, FY1985 (S60); see
# the FY1970 tarchive's comment for the shared background (one of the
# FY1970-1990 batch METI put online on 2014-02-04, 9 regions 北海道/東北/
# 関東/中部/近畿/中国/四国/九州/沖縄). This vintage's transaction sheet has
# 45 sectors, so `sector_class = "45"` (its 46th, a scrap/byproduct sector,
# only appears in the derived coefficient/multiplier sheets, not the
# transaction sheet used here). Its
# total row/column labels (verified against this workbook's own header
# cells) match FY1980 through FY2005: "地域内最終需要計"/"粗付加価値部門計".
# One cell quirk unique to this workbook: its industry-total row/column
# label has a trailing tab character ("内生部門計\t", not "内生部門計"), so
# industry_total_pattern tolerates trailing whitespace.
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_45,
    download_file_meti(
      url = "https://www.meti.go.jp/statistics/tyo/tiikiio/result/result_3/xlsx/h2rio85a.xlsx",
      destfile = "_targets/user/iotable/producer_price/45.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_45 = read_file_iotable_producer_price(
    file = file_iotable_producer_price_45,
    sheet = "取引額（45部門MTX）"
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
      industry_total_pattern = "内生部門計\\s*$",
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
