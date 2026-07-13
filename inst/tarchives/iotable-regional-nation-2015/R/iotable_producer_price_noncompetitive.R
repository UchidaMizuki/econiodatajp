target_iotable_producer_price_noncompetitive_import <- tar_plan(
  iotable_producer_price_noncompetitive_import_medium = io_table_to_noncompetitive_import(
    data = iotable_producer_price_medium,
    data_import = import_producer_price_medium
  ),
  iotable_producer_price_noncompetitive_import_large = io_table_to_noncompetitive_import(
    data = iotable_producer_price_large,
    data_import = import_producer_price_large
  ),
  iotable_producer_price_noncompetitive_import_template = io_table_to_noncompetitive_import(
    data = iotable_producer_price_template,
    data_import = import_producer_price_template
  ),
  iotable_producer_price_noncompetitive_import_medium_en = translate_iotable_sector(
    table = iotable_producer_price_noncompetitive_import_medium,
    sector_input = sector_input,
    sector_output = sector_output,
    sector_class = "medium"
  ),
  iotable_producer_price_noncompetitive_import_large_en = translate_iotable_sector(
    table = iotable_producer_price_noncompetitive_import_large,
    sector_input = sector_input,
    sector_output = sector_output,
    sector_class = "large"
  ),
  iotable_producer_price_noncompetitive_import_template_en = translate_iotable_sector(
    table = iotable_producer_price_noncompetitive_import_template,
    sector_input = sector_input,
    sector_output = sector_output,
    sector_class = "template"
  ),
)
