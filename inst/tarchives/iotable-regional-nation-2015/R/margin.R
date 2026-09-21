target_margin <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?layout=dataset&toukei=00200603&stat_infid=000031839511
    file_margin_nation_medium_trade_margin_ja,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839511&fileKind=0",
      destfile = "_targets/user/margin_nation_medium_trade_margin_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?layout=dataset&toukei=00200603&stat_infid=000031839513
    file_margin_nation_medium_transport_margin_ja,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839513&fileKind=0",
      destfile = "_targets/user/margin_nation_medium_transport_margin_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  margin_nation_medium_trade_margin_ja = read_file_margin(
    file = file_margin_nation_medium_trade_margin_ja
  ),
  margin_nation_medium_transport_margin_ja = read_file_margin(
    file = file_margin_nation_medium_transport_margin_ja
  ),
  margin_nation_medium_trade_margin_en = translate_iotable_sector(
    table = margin_nation_medium_trade_margin_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "medium"
  ),
  margin_nation_medium_transport_margin_en = translate_iotable_sector(
    table = margin_nation_medium_transport_margin_ja,
    sector_input = sector_nation_input,
    sector_output = sector_nation_output,
    sector_class = "medium"
  ),
)

# Both the trade margin ("商業マージン表") and transport margin ("国内貨物運賃
# 表") tables share the exact same layout as each other -- same header
# shape, same sector set, same missing value_added/import/total rows and
# columns (only ever published at "統合中分類" granularity, unlike the basic-
# classification `iotable_producer_price*` tables) -- confirmed by
# downloading and diffing both. So one reader handles both; only the source
# `file` differs.
#
# Unlike `read_file_iotable_producer_price_basic()`, no
# `value_added_total_pattern`/`import_pattern`/`import_total_pattern`/
# `total_pattern` are passed: this table has no 粗付加価値部門計 (gross
# value-added total) row, no （控除）輸入 (import deduction) column, and no
# 国内生産額 (national output) row/column at all -- only the endogenous
# industries plus a 内生部門計 (industry total) row and the usual final-
# demand/export columns. Leaving those patterns unset means
# `io_table_read_sector_types()` simply classifies zero rows/columns into
# `value_added`/`import`/`total`, which `econio::io_check_totals()` already
# handles by skipping the corresponding total check rather than erroring
# (confirmed empirically) -- there is no total row/column here to check
# against anyway. `import_type = "noncompetitive_import"` is passed for the
# same reason: with no `import` sector on either axis,
# `econioread::io_table_read_data()`'s own auto-detection
# (`"import" %in% output_sector_type`) always resolves to
# `noncompetitive_import` regardless of what's passed here, so this just
# states that outcome explicitly rather than naming the (irrelevant, since
# there's no import column to begin with) alternative.
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
