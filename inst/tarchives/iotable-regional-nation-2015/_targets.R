library(conflicted)
conflicts_prefer(
  dplyr::filter(),
  .quiet = TRUE
)

library(targets)
library(tarchetypes)
library(tarchives)

tar_option_set(
  packages = c(
    "dibble",
    "econio",
    "econioread",
    "adverbial",
    "stringr",
    "tibble",
    "tidyr",
    "dplyr",
    "purrr",
    "forcats"
  ),
  imports = c("econio", "econioread")
)

tar_source_archive("econiodatajp")
tar_source()

tar_plan(
  target_sector,
  target_iotable_producer_price,
  target_import_producer_price,
)
