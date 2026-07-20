devtools::load_all()

io_table_available <- io_table_available_impl()

usethis::use_data(io_table_available, overwrite = TRUE)
