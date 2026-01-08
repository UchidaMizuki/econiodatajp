library(conflicted)
conflicts_prefer(
  dplyr::filter(),
  .quiet = TRUE
)

library(targets)
library(tarchetypes)
library(tarchives)

tar_option_set(
  packages = c("econioread", "adverbial", "stringr", "tidyr", "dplyr", "purrr"),
  imports = c("econio", "econioread")
)

tar_source_archive("econiodatajp")
tar_source()

tar_plan(
  target_iotable_producer_price,
)
