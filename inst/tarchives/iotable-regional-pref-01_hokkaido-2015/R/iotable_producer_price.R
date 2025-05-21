# iotable_producer_price --------------------------------------------------

target_iotable_producer_price <- tar_plan(
  tar_change(
    # https://www.hkd.mlit.go.jp/ky/ki/keikaku/splaat000001yqxt.html
    file_iotable_producer_price_medium,
    download_file(
      url = "https://www.hkd.mlit.go.jp/ky/ki/keikaku/splaat000001yqxt-att/splaat000001yr7c.xlsx",
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
      sheets = "第4-1表　取引基本表",
      rows_exclude = 1:3,
      cols_exclude = 3
    ) |>
    io_table_read_headers(
      input_names = c(
        "input_sector_code",
        "input_sector_name"
      ),
      output_names = c(
        "output_sector_code",
        "output_sector_name_1",
        "output_sector_name_2",
        "output_sector_name_3"
      )
    ) |>
    as_step(mutate)(
      across(
        starts_with(c("input", "output")),
        \(x)
          x |>
            str_remove_all("\\s") |>
            replace_na("")
      )
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name_1}{output_sector_name_2}{output_sector_name_3}"
    ) |>
    as_step(mutate)(
      across(
        input_sector_name,
        \(x)
          case_match(
            x,
            "54_電子計算機・同付属装置" ~ "54_電子計算機・同附属装置",
            "85_インターネット付随サービス" ~ "85_インターネット附随サービス",
            .default = x
          )
      ),
      across(
        output_sector_name,
        \(x)
          case_match(
            x,
            "16_衣服・その他の繊維製品" ~ "16_衣服・その他の繊維既製品",
            "26_化学最終製品(医薬品を除く。)" ~
              "26_化学最終製品（医薬品を除く。）",
            .default = x
          )
      )
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_pattern = "^\\d+_",
      value_added_pattern = "家計外消費支出|雇用者所得|営業余剰|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|民間消費支出|一般政府消費支出|道内総固定資本形成|在庫純増",
      export_pattern = "^_[移輸]出$",
      import_pattern = "^_（控除）([移輸]入|関税・輸入品商品税)",
      total_pattern = "道内生産額"
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
