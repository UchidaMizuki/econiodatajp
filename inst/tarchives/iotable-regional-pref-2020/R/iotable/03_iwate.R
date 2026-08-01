# https://www3.pref.iwate.jp/webdb/view/outside/s14Tokei/busyoBtKekka.html/S03/S0103/I015
target_iotable_producer_price_03_iwate <- tar_plan(
  tar_change(
    file_iotable_03_iwate_103_producer_price_competitive_import_ja,
    download_file(
      url = "https://www3.pref.iwate.jp/webdb/view/outside/s14Tokei/tokei.download?fileId=s14TokeiInfo-63osf.18OYJ.qg8JA",
      destfile = "_targets/user/iotable_03_iwate_103_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_03_iwate_103_producer_price_competitive_import_ja = read_file_iotable_producer_price_103_03_iwate(
    file = file_iotable_03_iwate_103_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_103_03_iwate <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "①生産者価格評価表",
      rows_exclude = c(1, 2)
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
      import_type = "competitive_import",
      industry_total_pattern = industry_total_pattern,
      value_added_total_pattern = value_added_total_pattern,
      final_demand_total_pattern = final_demand_total_pattern,
      export_pattern = export_pattern,
      # This table reports a single combined "移輸出"/"（控除）移輸入" line
      # with no separate overseas/interregional breakdown and no trailing
      # 計, so there's no distinct total row to match -- leaving
      # export_total_pattern/import_total_pattern unset lets export_pattern/
      # import_pattern select that single line directly. The shared
      # import_pattern in global.R requires "（控除）" immediately followed
      # by a single 移/輸 character, so it doesn't match this combined
      # "（控除）移輸入" (two characters between them).
      import_pattern = "[（\\(]控除[）\\)]移輸入$",
      total_pattern = total_pattern
    ) |>
    io_table_read_data(
      value_scale = 1e3,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
