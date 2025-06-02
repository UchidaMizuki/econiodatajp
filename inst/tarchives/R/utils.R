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
