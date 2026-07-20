target_iotable_producer_price_noncompetitive_import <- tar_plan(
  iotable_medium_producer_price_noncompetitive_import_ja = io_table_to_noncompetitive_import(
    data = iotable_medium_producer_price_competitive_import_ja,
    data_import = import_producer_price_medium
  ),
  iotable_large_producer_price_noncompetitive_import_ja = io_table_to_noncompetitive_import(
    data = iotable_large_producer_price_competitive_import_ja,
    data_import = import_producer_price_large
  ),
  iotable_template_producer_price_noncompetitive_import_ja = io_table_to_noncompetitive_import(
    data = iotable_template_producer_price_competitive_import_ja,
    data_import = import_producer_price_template
  ),
  iotable_medium_producer_price_noncompetitive_import_en = translate_iotable_sector(
    table = iotable_medium_producer_price_noncompetitive_import_ja,
    sector_input = sector_input,
    sector_output = sector_output,
    sector_class = "medium"
  ),
  iotable_large_producer_price_noncompetitive_import_en = translate_iotable_sector(
    table = iotable_large_producer_price_noncompetitive_import_ja,
    sector_input = sector_input,
    sector_output = sector_output,
    sector_class = "large"
  ),
  iotable_template_producer_price_noncompetitive_import_en = translate_iotable_sector(
    table = iotable_template_producer_price_noncompetitive_import_ja,
    sector_input = sector_input,
    sector_output = sector_output,
    sector_class = "template"
  ),
)
