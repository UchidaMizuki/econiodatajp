# https://www.hkd.mlit.go.jp/ky/ki/keikaku/jtfkjs0000004nkx.html
target_iotable_producer_price_01_hokkaido <- tar_plan(
  tar_change(
    file_iotable_01_hokkaido_106_producer_price_competitive_import_ja,
    download_file(
      url = "https://www.hkd.mlit.go.jp/ky/ki/keikaku/jtfkjs0000004nkx-att/jtfkjs0000004npf.xlsx",
      destfile = "_targets/user/iotable_01_hokkaido_106_producer_price_competitive_import_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  iotable_01_hokkaido_106_producer_price_competitive_import_ja = read_file_iotable_producer_price_106_01_hokkaido(
    file = file_iotable_01_hokkaido_106_producer_price_competitive_import_ja
  ),
)

read_file_iotable_producer_price_106_01_hokkaido <- function(file) {
  io_table_reader(file) |>
    io_table_read_cells(
      sheets = "第4-1表　取引基本表",
      rows_exclude = c(1, 2, 3),
      cols_exclude = 3
    ) |>
    # Unlike every other prefecture's sheet, the column headers here aren't a
    # fixed two rows (code, name): each column's label is bottom-aligned to
    # the row just above the data and grows upward as needed (1 row for a
    # short label like "内生部門計", up to 4 rows for
    # "（控除）関税・輸入品商品税"), so all four header rows are read and
    # concatenated below instead of being split into a code/name pair.
    io_table_read_headers(
      input_names = c(
        "input_sector_code",
        "input_sector_name"
      ),
      output_names = c(
        "output_sector_h1",
        "output_sector_h2",
        "output_sector_h3",
        "output_sector_h4"
      )
    ) |>
    as_step(mutate)(
      across(starts_with("output_sector_h"), \(x) coalesce(x, "")),
      # Only the industry columns' h1 is a numeric code (needing a "_"
      # separator to match the "{code}_{name}" input side, for check_axes);
      # every other column's h1 (when non-empty) is itself the start of the
      # name's running text (e.g. "（控除）" in "（控除）関税・輸入品商品税"),
      # where inserting a separator would break the total/export/import
      # patterns in global.R.
      output_sector_name = dplyr::if_else(
        str_detect(output_sector_h1, "^[0-9]+$"),
        str_c(
          output_sector_h1,
          "_",
          output_sector_h2,
          output_sector_h3,
          output_sector_h4
        ),
        str_c(
          output_sector_h1,
          output_sector_h2,
          output_sector_h3,
          output_sector_h4
        )
      )
    ) |>
    as_step(select)(-starts_with("output_sector_h")) |>
    io_table_read_sector_names(
      input_sector_name_glue = "{input_sector_code}_{input_sector_name}",
      output_sector_name_glue = "{output_sector_name}"
    ) |>
    io_table_read_sector_types(
      import_type = "competitive_import",
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
      value_scale = 1e6,
      total_tolerance = 1e-3
    ) |>
    end_step()
}
