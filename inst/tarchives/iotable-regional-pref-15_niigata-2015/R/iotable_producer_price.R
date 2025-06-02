# iotable_producer_price --------------------------------------------------

# https://www.pref.niigata.lg.jp/site/tokei/0359813.html
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_small,
    download_file(
      url = "https://www.pref.niigata.lg.jp/uploaded/attachment/385228.xlsx",
      destfile = "_targets/user/iotable/producer_price/small.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw = read_file_iotable_producer_price_small(
    file = file_iotable_producer_price_small
  ),
)

read_file_iotable_producer_price_small <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "基本（175部門）",
      rows_exclude = 1:4
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
    # as_step(mutate)(
    #   across(
    #     output_sector_code,
    #     \(x) x |> str_extract("^\\d+$") |> replace_na("")
    #   )
    # ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name}"
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_pattern = "^[0-6]\\d+_",
      value_added_pattern = "家計外消費支出|雇用者所得|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|家計消費支出|対家計民間非営利団体消費支出|一般政府消費支出|県内総固定資本形成|在庫純増",
      export_pattern = "_(輸出|輸出（直接購入）|移出)$",
      import_pattern = "_（控除）(輸入|輸入（直接購入）|関税|輸入品商品税|移入)$",
      total_pattern = "県内生産額"
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
