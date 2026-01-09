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
)
