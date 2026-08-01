# https://www.pref.miyagi.jp/soshiki/toukei/rennkann.html
target_iotable_producer_price_04_miyagi <- tar_plan(
  tar_change(
    file_iotable_04_miyagi_101_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.pref.miyagi.jp/documents/27447/r2_101bumon1.xlsx",
      destfile = "_targets/user/iotable_04_miyagi_101_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_04_miyagi_101_producer_price_competitive_import_ja = read_file_iotable_producer_price_101_04_miyagi(
    file = file_iotable_04_miyagi_101_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_101_04_miyagi <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "生産者価格評価表",
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
    # The output (column) header cells carry a footnote annotating each
    # total's formula (e.g. "移輸出\n④", "需要合計\n⑥＝③＋④") on a second
    # line -- drop everything from the embedded line break onward before
    # matching sector names.
    as_step(mutate)(
      across(
        c(input_sector_name, output_sector_name),
        \(x) x |> str_remove("\n.*") |> str_remove_all("\\s")
      )
    ) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_code}_{output_sector_name}"
    ) |>
    io_table_read_sector_types(
      import_type = "competitive_import",
      # The input side's total is "内生部門（中間投入）計", the output
      # side's is "内生部門（中間需要）計" -- neither matches the shared
      # "内生部門合?計" pattern in global.R.
      industry_total_pattern = "内生部門（中間(投入|需要)）計$",
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
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
