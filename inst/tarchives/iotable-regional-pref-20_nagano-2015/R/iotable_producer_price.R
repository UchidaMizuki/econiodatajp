# iotable_producer_price --------------------------------------------------

# https://www.pref.nagano.lg.jp/tokei/tyousa/sangyorenkan.html
# https://tokei.pref.nagano.lg.jp/statist_list/1876.html
target_iotable_producer_price <- tar_plan(
  tar_change(
    file_iotable_producer_price_small,
    download_file(
      url = "https://tokei.pref.nagano.lg.jp/statistics-info/statistics_download?pid=18716&type=excel",
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
      sheets = "取引基本表",
      rows_exclude = 1:3
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
    mutate(
      input_sector_name = case_match(
        input_sector_name,
        "0621_砂利・採石" ~ "0621_砂利・砕石",
        "1511_紡績" ~ "1511_紡績糸",
        .default = input_sector_name
      )
    ) |>
    io_table_read_sector_types(
      competitive_import = TRUE,
      industry_pattern = "^[0-6]\\d+_",
      value_added_pattern = "家計外消費支出|賃金・俸給|社会保険料|その他の給与及び手当|営業余剰|資本減耗引当|資本減耗引当|間接税|経常補助金",
      final_demand_pattern = "家計外消費支出|家計消費支出|対家計民間非営利団体消費支出|一般政府消費支出|県内総固定資本形成|在庫純増",
      export_pattern = "(輸出|輸出（直接購入）|移出)$",
      import_pattern = "(（控除）(輸入|輸入（直接購入）|関税|輸入品商品税)|移入)$",
      total_pattern = "県内生産額"
    ) |>
    io_table_read_data(
      value_scale = 1e4
    ) |>
    end_step()
}
