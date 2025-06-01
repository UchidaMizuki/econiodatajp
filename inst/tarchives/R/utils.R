download_file <- function(url, destfile, mode = "wb", ...) {
  fs::dir_create(fs::path_dir(destfile))

  download.file(
    url = url,
    destfile = destfile,
    mode = mode,
    ...
  )
  invisible(destfile)
}

get_sector_name <- function(
  year,
  axis,
  sector_type,
  sector_class = c("basic", "small", "medium", "large", "template"),
  remove_sector_code = TRUE,
  remove_parentheses = TRUE
) {
  sector_type <- switch(
    axis,
    input = rlang::arg_match(
      sector_type,
      c("industry", "value_added", "total")
    ),
    output = rlang::arg_match(
      sector_type,
      c("industry", "final_demand", "export", "import", "total")
    )
  )
  sector_class <- rlang::arg_match(
    sector_class,
    c("basic", "small", "medium", "large", "template"),
    multiple = TRUE
  )

  sector_name <- econiodatajp::io_sector_regional_nation(year, axis) |>
    dplyr::filter(
      .data$sector_type == .env$sector_type,
      .data$sector_class %in% .env$sector_class
    ) |>
    dplyr::pull("sector_name")

  if (remove_sector_code) {
    sector_name <- sector_name |>
      stringr::str_remove_all("^\\d+_") |>
      unique()
  }
  if (remove_parentheses) {
    sector_name <- sector_name |>
      stringr::str_remove_all("[\\(（].*?[\\)）]") |>
      unique()
  }
  sector_name
}
