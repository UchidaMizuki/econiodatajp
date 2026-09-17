devtools::load_all()

io_margin_available <- io_margin_available_impl()

usethis::use_data(io_margin_available, overwrite = TRUE)
