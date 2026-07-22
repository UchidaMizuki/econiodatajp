devtools::load_all()

io_sector_available <- io_sector_available_impl()

usethis::use_data(io_sector_available, overwrite = TRUE)
