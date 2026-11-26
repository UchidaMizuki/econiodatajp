source_tarchives_utils <- function() {
  env <- new.env(parent = globalenv())
  sys.source(
    system.file("tarchives", "R", "utils.R", package = "econiodatajp"),
    envir = env
  )
  env
}

write_source_file <- function(bytes, ext) {
  file <- tempfile(fileext = paste0(".", ext))
  writeBin(bytes, file)
  file
}

file_url <- function(file) {
  path <- normalizePath(file, winslash = "/", mustWork = FALSE)
  paste0("file://", if (!startsWith(path, "/")) "/", path)
}
