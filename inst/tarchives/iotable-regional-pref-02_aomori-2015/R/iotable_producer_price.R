# iotable_producer_price --------------------------------------------------

target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_medium,
    download_file(
      url = "https://opendata.pref.aomori.lg.jp/dataset/1597/resource/14204/%E7%94%A3%E6%A5%AD%E9%80%A3%E9%96%A2%E8%A1%A8107%E9%83%A8%E9%96%80%E8%A1%A8_2015.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw = read_file_iotable_producer_price_medium(
    file = file_iotable_producer_price_medium
  ),
)

read_file_iotable_producer_price_medium <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "第29表",
      rows_exclude = 1:2
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
        c(input_sector_code, output_sector_code),
        \(x)
          case_when(
            is.na(x) ~ "",
            str_detect(x, "^\\d+$") ~ str_pad(x, 2, pad = "0")
          )
      ),
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
      industry_pattern = "^\\d+_",
      value_added_pattern = "家計外消費支出|雇用者所得|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|民間消費支出|一般政府消費支出|県内総固定資本形成|在庫純増",
      export_pattern = "^_[輸移]出計$",
      import_pattern = "^_（控除）[輸移]入計$",
      total_pattern = "県内生産額"
    ) |>
    io_table_read_data(
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
