io_table_regional_pref_pipeline <- function(region, year) {
  data_region <- system.file("tarchives", package = "econiodatajp") |>
    fs::dir_ls(regexp = "iotable-regional-pref-\\d{2}_.*-\\d+$") |>
    fs::path_file() |>
    stringr::str_match("iotable-regional-pref-((\\d{2})_(.*))-\\d+$") |>
    tibble::as_tibble(
      .name_repair = ~ c("", "region", "region_code", "region_name")
    ) |>
    dplyr::distinct(.data$region, .data$region_code, .data$region_name) |>
    dplyr::mutate(
      dplyr::across("region_code", as.integer)
    )

  region <- if (rlang::is_integerish(region)) {
    data_region |>
      dplyr::filter(
        .data$region_code == .env$region
      ) |>
      dplyr::pull("region")
  } else if (is.character(region)) {
    data_region |>
      dplyr::filter(
        .data$region_name == .env$region
      ) |>
      dplyr::pull("region")
  }

  stringr::str_glue("iotable-regional-pref-{region}-{year}")
}

io_table_regional_pref <- function(
  region,
  year,
  data_type,
  sector_type
) {
  pipeline <- io_table_regional_pref_pipeline(
    region = region,
    year = year
  )
  data_type <- rlang::arg_match(data_type, c("iotable_producer_price"))
  sector_type <- rlang::arg_match(
    sector_type,
    c("small_raw", "medium_raw", "large_raw", "small", "medium", "large")
  )

  name <- stringr::str_glue("{data_type}_{sector_type}")
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
