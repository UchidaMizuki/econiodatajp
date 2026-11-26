# Source files move without notice, and a moved URL fails in one of two ways:
# the server refuses it (download.file() errors with a bare "cannot open URL",
# its HTTP status only in a separate warning), or it redirects to an HTML
# error page with status 200, so the download "succeeds" and the build only
# fails later, while reading the "xlsx". Both abort here instead, naming the
# URL, so a broken source is reported where it breaks.
download_file <- function(url, destfile, mode = "wb", ...) {
  fs::dir_create(fs::path_dir(destfile))

  warnings <- character()
  withCallingHandlers(
    tryCatch(
      download.file(
        url = url,
        destfile = destfile,
        mode = mode,
        ...
      ),
      error = function(cnd) {
        cli::cli_abort(
          c(
            "Can't download {.url {url}}.",
            rlang::set_names(gsub("([{}])", "\\1\\1", warnings), "x")
          ),
          class = "econiodatajp_error_download",
          parent = cnd
        )
      }
    ),
    warning = function(cnd) {
      warnings <<- c(warnings, conditionMessage(cnd))
      invokeRestart("muffleWarning")
    }
  )
  for (warning in warnings) {
    rlang::warn(warning)
  }

  check_downloaded_file(destfile, url = url)
  invisible(destfile)
}

# Leading bytes ("magic numbers") each source file format starts with, keyed
# by file extension. Files with any other extension aren't checked.
file_signatures <- list(
  xlsx = as.raw(c(0x50, 0x4b, 0x03, 0x04)),
  xls = as.raw(c(0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1)),
  pdf = charToRaw("%PDF-")
)

check_downloaded_file <- function(file, url) {
  extension <- tolower(fs::path_ext(file))
  signature <- file_signatures[[extension]]
  if (is.null(signature)) {
    return(invisible(file))
  }

  head <- readBin(file, "raw", n = 512)
  if (identical(head[seq_along(signature)], signature)) {
    return(invisible(file))
  }

  is_html <- grepl(
    "<(!doctype|html)",
    rawToChar(head[head != as.raw(0)]),
    ignore.case = TRUE,
    useBytes = TRUE
  )
  fs::file_delete(file)
  cli::cli_abort(
    c(
      "{.url {url}} didn't return a {.file .{extension}} file.",
      if (is_html) {
        c("x" = "It returned an HTML page; the file has probably moved.")
      }
    ),
    class = "econiodatajp_error_download"
  )
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
