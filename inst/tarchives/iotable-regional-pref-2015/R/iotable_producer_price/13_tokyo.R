# https://www.toukei.metro.tokyo.lg.jp/sanren/2015/sr15t1.htm
target_iotable_producer_price_13_tokyo <- tar_plan(
  tar_change(
    file_iotable_producer_price_small_13_tokyo,
    download_file(
      url = "https://www.toukei.metro.tokyo.lg.jp/sanren/2015/sr15tv_nai11.csv",
      destfile = "_targets/user/iotable/producer_price/small/13_tokyo.csv"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_small_raw_13_tokyo = read_file_iotable_producer_price_small_13_tokyo(
    file = file_iotable_producer_price_small_13_tokyo
  ),
)

read_file_iotable_producer_price_small_13_tokyo <- function(file) {
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
    as_step(filter)(
      !str_detect(input_sector_name, "財・サービス内生部門計（百万円）$"),
      !str_detect(output_sector_name, "財・サービス内生部門計（百万円）$")
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_total_pattern = "／内生部門計（百万円）$",
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = "(移出|他地域事業所家計外消費支出|他地域民支出|輸出|輸出（直接購入）)（百万円）$",
      export_total_pattern = "移輸出計（百万円）$",
      import_pattern = "（控除）(移入|都事業所家計外消費支出|都民支出|輸入|輸入（直接購入）|関税|輸入品商品税)（百万円）$",
      import_total_pattern = "（控除）移輸入計（百万円）$",
      total_pattern = "生産額（百万円）$"
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
