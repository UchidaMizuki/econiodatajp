# https://toukei.pref.gunma.jp/gio/gio2015.htm
target_iotable_producer_price_10_gunma <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium_10_gunma,
    download_file(
      url = "https://toukei.pref.gunma.jp/gio/data/2015.107bumon.xls",
      destfile = "_targets/user/iotable/producer_price/medium/10_gunma.xls"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_10_gunma = read_file_iotable_producer_price_medium_10_gunma(
    file = file_iotable_producer_price_medium_10_gunma
  ),
)

read_file_iotable_producer_price_medium_10_gunma <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "①生産者価格",
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
      competitive_import = TRUE,
      industry_pattern = "^[0-6]\\d+_",
      value_added_pattern = "家計外消費支出|雇用者所得|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|民間消費支出|一般政府消費支出|県内総固定資本形成|在庫純増",
      export_pattern = "_[移輸]出$",
      import_pattern = "_（控除）[移輸]入$",
      total_pattern = "県内生産額"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
