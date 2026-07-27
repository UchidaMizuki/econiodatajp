# Shared by the national-table pipelines that publish an official basic-
# classification <-> JSIC (Japan Standard Industrial Classification)
# correspondence alongside their sector classification workbook
# (2011/2015/2020 as of writing; see each pipeline's sector.R). The
# correspondence is only ever published for basic-classification *industry*
# sectors, so unlike sector.R's sector_input/sector_output there's no
# sector_class/sector_type axis to carry here.

# 2020 onward: a single self-contained Excel sheet, column layout matching
# the PDF table read_sector_jsic_pdf() parses for 2011/2015 (see below) --
# both funnel into clean_sector_jsic() so the two source formats produce an
# identical shape.
read_sector_jsic_xlsx <- function(file, sheet = 1, skip = 5) {
  readxl::read_excel(
    file,
    sheet = sheet,
    skip = skip,
    col_names = c(
      "code",
      "name",
      "jsic_code",
      "jsic_name",
      "paren_open",
      "frac",
      "paren_close",
      "unused",
      "unused2",
      "note"
    ),
    col_types = "text"
  ) |>
    dplyr::select(!tidyselect::starts_with(c("paren_", "unused"))) |>
    clean_sector_jsic()
}

# 2011/2015: the same table exists only as a page range inside that
# benchmark year's PDF report (no structured spreadsheet was ever
# published). `pdftools::pdf_data()` gives per-word bounding boxes rather
# than plain text, which this relies on rather than a text/regex approach:
# the source wraps long cells (a JSIC name or the descriptive note) onto
# extra physical lines with no other markup, so reconstructing logical rows
# needs to know which *column* a wrapped line's words belong to, and
# comparing word x-positions is the only reliable way to tell (whitespace
# alone is ambiguous -- confirmed by testing both against these files).
#
# Column x-boundaries are derived from the words themselves (a 6-digit code,
# a 4-digit JSIC code, and the "(" that opens a split fraction are all
# unambiguous by pattern), not from the header row's own label positions --
# the header labels sit at a different x than where each column's data
# actually starts, so anchoring to them misclassifies real data.
read_sector_jsic_pdf <- function(file, pages) {
  words <- purrr::map(
    pages,
    \(page) pdftools::pdf_data(file)[[page]] |> dplyr::mutate(page = page)
  ) |>
    purrr::list_rbind() |>
    dplyr::filter(
      !stringr::str_detect(text, "産業連関表基本分類|日本標準産業分類|〔参考"),
      !text %in% c("列コード", "部門名", "分類番号", "分類項目名", "対応関係"),
      # Drop the page-number footer: bare 1-3 digits (2011's format, e.g.
      # "26") or digits wrapped in full-width dashes (2015/2020's, e.g.
      # "ー341ー"). Neither a 4-digit JSIC code nor a fraction's numerator/
      # denominator ever appears on its own outside those contexts, so this
      # is safe unconditionally -- no position check, since the footer sits
      # near the *bottom* of the page (high y in pdf_data()'s coordinates),
      # not the top; a coordinate-based check first written against the
      # wrong end of that range let the footer through and corrupted the
      # last content row on a page (confirmed against real output: e.g.
      # "1635" jsic_code showing up with jsic_name "...プラスチック製造業
      # ー333ー" instead of "...プラスチック製造業").
      !stringr::str_detect(stringr::str_trim(text), "^\\d{1,3}$"),
      !stringr::str_detect(text, "^[ー－―]\\d+[ー－―]$")
    )

  is_structural <- function(x) {
    stringr::str_detect(x, "^\\d{4,6}$|^\\d+/\\d+$") | x %in% c("(", ")")
  }
  anchor_x <- function(pattern) {
    words |>
      dplyr::filter(stringr::str_detect(text, pattern)) |>
      dplyr::pull(x) |>
      min()
  }
  bounds <- c(
    code = anchor_x("^\\d{6}$"),
    name = words |>
      dplyr::filter(x > anchor_x("^\\d{6}$"), x < anchor_x("^\\d{4}$")) |>
      dplyr::pull(x) |>
      min(),
    jsic_code = anchor_x("^\\d{4}$"),
    jsic_name = words |>
      dplyr::filter(x > anchor_x("^\\d{4}$"), !is_structural(text)) |>
      dplyr::pull(x) |>
      min(),
    note = words |> dplyr::filter(text == ")") |> dplyr::pull(x) |> max()
  )
  cutoffs <- c(-Inf, zoo_free_rollmean(bounds), Inf)

  words <- words |>
    dplyr::filter(
      text != "(",
      text != ")",
      !stringr::str_detect(text, "^\\d+/\\d+$")
    ) |>
    dplyr::mutate(col = names(bounds)[findInterval(x, cutoffs)])

  lines <- words |>
    dplyr::summarise(
      text = stringr::str_c(text, collapse = ""),
      .by = c(page, y, col)
    ) |>
    dplyr::arrange(page, y)

  # One logical row = one IO-sector/JSIC-code pair, so a physical line
  # starts a new logical row iff it carries a `jsic_code` cell -- not
  # whether it carries an IO `code` cell, since an IO sector that splits
  # across several JSIC codes repeats blank `code`/`name` cells on its
  # later rows while still starting a fresh `jsic_code` each time. A
  # physical line with no `jsic_code` cell at all is a wrapped continuation
  # of the previous logical row's `jsic_name`/`note` text.
  row_starts <- lines |>
    dplyr::filter(col == "jsic_code") |>
    dplyr::distinct(page, y) |>
    dplyr::mutate(logical_row = dplyr::row_number())
  logical_rows <- lines |>
    dplyr::distinct(page, y) |>
    dplyr::arrange(page, y) |>
    dplyr::left_join(row_starts, by = c("page", "y")) |>
    tidyr::fill(logical_row)

  lines |>
    dplyr::left_join(logical_rows, by = c("page", "y")) |>
    dplyr::summarise(
      text = stringr::str_c(text, collapse = ""),
      .by = c(logical_row, col)
    ) |>
    tidyr::pivot_wider(names_from = col, values_from = text) |>
    dplyr::arrange(logical_row) |>
    dplyr::select(!logical_row) |>
    clean_sector_jsic()
}

# Midpoints between consecutive sorted values, e.g. c(10, 20, 30) -> c(15,
# 25) -- named so read_sector_jsic_pdf()'s cutoffs read as "the boundary
# between column i and column i+1", without pulling in a package (zoo::
# rollmean()) for one two-line calculation.
zoo_free_rollmean <- function(x) {
  (x[-1] + x[-length(x)]) / 2
}

# Shared finish for both source formats: fills blank `code`/`name` down from
# the IO sector each split row belongs to, drops rows that turned out to be
# page furniture rather than data, and normalizes the "no JSIC equivalent"
# marker. Warns (rather than silently dropping) on any row whose `jsic_code`
# is neither a real 4-digit code nor that marker, since that means a row
# didn't parse the way every other one did and is worth a human look before
# it ships as data -- confirmed empirically against 2011/2015/2020 that this
# is at most a handful of rows, not a systematic problem.
clean_sector_jsic <- function(raw) {
  raw <- raw |>
    dplyr::filter(stringr::str_detect(code, "^\\d{6}$") | !is.na(jsic_code)) |>
    tidyr::fill(code, name) |>
    dplyr::mutate(
      dplyr::across(c(name, jsic_name, note), \(x) stringr::str_squish(x)),
      jsic_code = dplyr::na_if(stringr::str_squish(jsic_code), "対象外")
    )

  invalid <- raw |>
    dplyr::filter(
      !is.na(jsic_code),
      !stringr::str_detect(jsic_code, "^\\d{4}$")
    )
  if (nrow(invalid) > 0) {
    cli::cli_warn(c(
      "Dropping {nrow(invalid)} row{?s} whose jsic_code didn't parse as a 4-digit code or \"対象外\".",
      "i" = "IO sector code{?s}: {.str {invalid$code}}"
    ))
    raw <- raw |> dplyr::anti_join(invalid, by = c("code", "jsic_code"))
  }

  raw |>
    dplyr::mutate(
      jsic_name = dplyr::if_else(is.na(jsic_code), NA_character_, jsic_name)
    ) |>
    dplyr::select(code, name, jsic_code, jsic_name, note)
}

# Joins the raw code-keyed correspondence onto that pipeline's own sector
# classification (see sector.R's get_sector()/get_sector_long()) to attach
# the real bilingual sector names `io_sector_jsic_get()` returns, the same
# way get_sector_conversion() attaches them for the tier crosswalk.
#
# Always uses the *output* axis, and there is no `axis` argument to choose
# otherwise: the source table's own header labels its IO-sector key "列
# コード" ("column code"), i.e. the output/industry axis's basic-
# classification code, and that's the only axis it was ever published
# against. The input axis uses a visibly different, finer-grained code
# format for basic industry sectors (e.g. "0111011" vs the output axis's
# "011101" for the same sector) that this correspondence has no published
# equivalent for -- inventing one by truncating the input code would be
# guessing at a correspondence e-stat never actually published, not reading
# one that exists (confirmed empirically: every one of this table's ~1,350+
# rows joins cleanly against the output axis and none against the input
# axis).
#
# Errors (rather than silently dropping) on any correspondence row whose IO
# code isn't in the output axis's basic-classification industry sectors,
# since that would mean the two sources have drifted apart in a way worth
# knowing about immediately, not shipping as missing data.
get_sector_jsic <- function(sector_raw, sector_jsic_raw) {
  sector <- get_sector(sector_raw, axis = "output") |>
    dplyr::filter(sector_type == "industry") |>
    dplyr::mutate(code = stringr::str_extract(sector_name_ja, "^[0-9]+"))

  unmatched <- sector_jsic_raw |>
    dplyr::anti_join(sector, by = "code")
  if (nrow(unmatched) > 0) {
    cli::cli_abort(c(
      "{nrow(unmatched)} JSIC correspondence row{?s} reference an IO sector code not found among the output axis's basic-classification industry sectors.",
      "i" = "Code{?s}: {.str {unique(unmatched$code)}}"
    ))
  }

  sector_jsic_raw |>
    dplyr::left_join(
      sector |> dplyr::select(code, sector_name_ja, sector_name_en),
      by = "code"
    ) |>
    dplyr::select(sector_name_ja, sector_name_en, jsic_code, jsic_name, note)
}
