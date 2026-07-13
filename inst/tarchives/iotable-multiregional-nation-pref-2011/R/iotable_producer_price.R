# https://www.rieti.go.jp/jp/database/r-io2011/index.html
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_large,
    download_file(
      url = "https://www.rieti.go.jp/jp/database/r-io2011/data/i-preio2011.xlsx",
      destfile = "_targets/user/iotable/producer_price/large.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_producer_price_large = read_file_iotable_producer_price_large(
    file = file_iotable_producer_price_large
  )
)

read_file_iotable_producer_price_large <- function(file) {
  io_table_reader(file, region_type = "multiregional") |>
    io_table_read_cells(
      sheets = "2011都道府県間表",
      rows_exclude = 1:4
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
    io_table_read_regions(
      input_region_glue = "{input_region_code}_{input_region_name}",
      output_region_glue = "{output_region_code}_{output_region_name}"
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
      industry_total_pattern = "内生部門計$",
      value_added_total_pattern = "粗付加価値部門計$",
      final_demand_total_pattern = "県内最終需要計$",
      export_pattern = "輸出$",
      import_pattern = "（控除）輸入$",
      total_pattern = "県内生産額$"
    ) |>
    as_step(filter)(
      !if_any(
        c(input_region, output_region),
        \(x) str_detect(x, "都道府県合計$")
      )
    ) |>
    as_step(mutate)(
      across(
        input_region,
        \(x)
          case_when(
            input_sector_type == "value_added" & str_detect(x, "列の当該県") ~
              output_region,
            input_sector_type == "total" ~ NA,
            .default = input_region
          )
      )
    ) |>
    io_table_read_data(
      value_scale = 1e6
    ) |>
    end_step()
}
