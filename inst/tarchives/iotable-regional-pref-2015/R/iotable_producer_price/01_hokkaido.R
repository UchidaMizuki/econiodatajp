target_iotable_producer_price_01_hokkaido <- tar_plan(
  tar_change(
    # https://www.hkd.mlit.go.jp/ky/ki/keikaku/splaat000001yqxt.html
    file_iotable_producer_price_medium_01_hokkaido,
    download_file(
      url = "https://www.hkd.mlit.go.jp/ky/ki/keikaku/splaat000001yqxt-att/splaat000001yr7c.xlsx",
      destfile = "_targets/user/iotable/producer_price/medium/01_hokkaido.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_medium_raw_01_hokkaido = read_file_iotable_producer_price_medium_01_hokkaido(
    file = file_iotable_producer_price_medium_01_hokkaido
  ),
)

read_file_iotable_producer_price_medium_01_hokkaido <- function(file) {
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
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      export_total_pattern = export_total_pattern,
      import_pattern = import_pattern,
      import_total_pattern = import_total_pattern,
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
