#' Get a trade margin or transport margin table
#'
#' The trade margin ("商業マージン表") and transport margin ("国内貨物運賃
#' 表", i.e. domestic freight) tables published alongside an [io_table_get()]
#' benchmark year. Both record, for each commodity, how much of its
#' buyer-price markup over the producer price is trade margin
#' (wholesale/retail) versus transport margin -- the two components that,
#' combined with a producer-price table, yield a buyer-price one. Only
#' published as standalone tables for benchmark years
#' up to 2015; from 2020 on, e-stat folds this information into the
#' "input-output table" ("投入産出表") instead and no longer publishes these
#' as separate tables (see [io_margin_available] for which `year`s have
#' data).
#'
#' @inheritParams io_table_get
#' @param margin_type Which table to get, `"trade_margin"` or
#' `"transport_margin"`.
#' @param sector_class Sector classification granularity. No default --
#' must be specified. As of writing, every available table uses `"medium"`
#' (a direct translation of the official "統合中分類" tier name) -- e-stat
#' only ever published these two tables at that one granularity -- but see
#' [io_margin_available] to confirm what's actually available rather than
#' assuming `"medium"` is the only value that will ever exist.
#'
#' @return An input-output table object for the specified year.
#'
#' @export
io_margin_get <- function(
  region_type = c("regional", "multiregional"),
  region_class = c("nation", "pref", "block"),
  year,
  region = NULL,
  margin_type = c("trade_margin", "transport_margin"),
  sector_class,
  language = c("ja", "en")
) {
  region_type <- rlang::arg_match(region_type)
  region_class <- rlang::arg_match(region_class)
  margin_type <- rlang::arg_match(margin_type)
  language <- rlang::arg_match(language)
  resolved <- io_margin_resolve(
    region_type = region_type,
    region_class = region_class,
    year = year,
    region = region,
    margin_type = margin_type,
    sector_class = sector_class,
    language = language
  )
  tarchives::tar_get_archive_raw(
    name = resolved$name,
    package = "econiodatajp",
    pipeline = resolved$pipeline
  )
}
