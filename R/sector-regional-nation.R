io_sector_regional_nation_pipeline <- function(year) {
  stringr::str_glue("iotable-regional-nation-{year}")
}

#' Get sector information for the national input-output tables
#'
#' @param year Year of the data.
#' @param axis Axis of the data, either `"input"` or `"output"`.
#'
#' @return A data frame containing the sector information for the specified year and axis.
#'
#' @export
io_sector_regional_nation <- function(year, axis) {
  axis <- rlang::arg_match(axis, c("input", "output"))

  pipeline <- io_sector_regional_nation_pipeline(year)
  name <- stringr::str_glue("sector_{axis}")
  tarchives::tar_make_archive(
    package = "econiodatajp",
    pipeline = pipeline,
    names = !!name
  )
  tarchives::tar_read_archive_raw(
    name,
    package = "econiodatajp",
    pipeline = pipeline
  )
}
