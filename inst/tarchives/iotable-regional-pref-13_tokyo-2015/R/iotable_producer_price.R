# iotable_producer_price --------------------------------------------------

# https://www.toukei.metro.tokyo.lg.jp/sanren/2015/sr15t1.htm
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_small,
    download_file(
      url = "https://www.toukei.metro.tokyo.lg.jp/sanren/2015/sr15tv_nai11.csv",
      destfile = "_targets/user/iotable/producer_price/small.csv"
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
    io_table_read_cells() |>
    io_table_read_headers(
      input_names = "input_sector_name",
      output_names = "output_sector_name"
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_name}",
      output_sector_name_glue = "{output_sector_name}"
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_pattern = "^中間(投入|需要)／[ABKL]\\d+",
      value_added_pattern = "家計外消費支出|賃金・俸給|社会保険料|その他の給与及び手当|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "(?<!（控除）)都事業所家計外消費支出|都民家計消費支出|対家計民間非営利団体消費支出|一般政府消費支出|都内総固定資本形成|在庫純増",
      export_pattern = "(移出|他地域事業所家計外消費支出|他地域民支出|輸出|輸出（直接購入）)（百万円）$",
      import_pattern = "（控除）(移入|都事業所家計外消費支出|都民支出|輸入|輸入（直接購入）|関税|輸入品商品税)（百万円）$",
      total_pattern = "生産額"
    ) |>
    as_step(separate_wider_delim)(
      c(input_sector_name, output_sector_name),
      delim = "／",
      names = c(NA, "code", "name"),
      names_sep = "_",
      too_few = "align_end"
    ) |>
    as_step(mutate)(
      across(
        c(input_sector_name_code, output_sector_name_code),
        \(x) str_remove(x, "^[:upper:]")
      ),
      across(
        c(input_sector_name_name, output_sector_name_name),
        \(x) str_remove(x, "（百万円）$")
      )
    ) |>
    as_step(unite)(
      "input_sector_name",
      c(input_sector_name_code, input_sector_name_name),
      sep = "_"
    ) |>
    as_step(unite)(
      "output_sector_name",
      c(output_sector_name_code, output_sector_name_name),
      sep = "_"
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
