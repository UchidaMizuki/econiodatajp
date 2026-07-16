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

# Unlike e-stat.go.jp (used by the FY2005 block archive), meti.go.jp's own
# site -- where METI hosts the FY1970-1995 block archives directly, since
# those predate e-stat -- 403s a plain download.file() request; sending a
# browser-like User-Agent via libcurl is enough to get through.
download_file_meti <- function(url, destfile) {
  download_file(
    url = url,
    destfile = destfile,
    method = "libcurl",
    headers = c(
      `User-Agent` = paste0(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ",
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      )
    )
  )
}
