# Shared by the national-table pipelines that publish an official basic-
# classification <-> JSIC (Japan Standard Industrial Classification)
# correspondence alongside their sector classification workbook
# (2011/2015/2020 as of writing; see each pipeline's sector.R). The
# correspondence is only ever published for basic-classification *industry*
# sectors, so unlike sector.R's sector_input/sector_output there's no
# sector_class/sector_type axis to carry here.

# 2020 onward: a single self-contained Excel sheet, column layout matching
# the PDF table read_file_sector_jsic_pdf() parses for 2011/2015 (see below) --
# both funnel into clean_sector_jsic() so the two source formats produce an
# identical shape.
read_file_sector_jsic_xlsx <- function(file, sheet = 1, skip = 5) {
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
read_file_sector_jsic_pdf <- function(file, pages) {
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
# 25) -- named so read_file_sector_jsic_pdf()'s cutoffs read as "the boundary
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
# `jsic_revision_year` is a plain pass-through, not derived from
# `sector_jsic_raw`: JSIC has been revised multiple times and the source
# correspondence document states which revision it uses only in its own
# title text (e.g. "日本標準産業分類（平成25年（2013年）改定）"), not as a
# parseable column, so each pipeline's sector.R hardcodes the year it
# confirmed from that title (mirroring how it already hardcodes the source
# URL/page range as pipeline-specific facts rather than deriving them).
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
get_sector_jsic <- function(sector_raw, sector_jsic_raw, jsic_revision_year) {
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

  # `axis = "output"` is stamped as a column here (not just baked into the
  # archive name via econiodatajp's io_sector_name_archive(), which
  # hardcodes the same fact independently) so io_sector_jsic_get()'s
  # returned tibble is self-documenting too -- a permanent, structural fact
  # about JSIC (see io_sector_name_archive()'s comment), not a current-data
  # quirk that might need an input-axis equivalent later.
  sector_jsic_raw |>
    dplyr::left_join(
      sector |> dplyr::select(code, sector_name_ja, sector_name_en),
      by = "code"
    ) |>
    dplyr::mutate(axis = "output", jsic_revision_year = jsic_revision_year) |>
    dplyr::select(
      sector_name_ja,
      sector_name_en,
      axis,
      jsic_code,
      jsic_name,
      note,
      jsic_revision_year
    )
}

# Reads the flat 大分類/中分類/小分類/細分類 (division/major group/group/
# detail) hierarchy CSV that 総務省 publishes per JSIC revision (e.g.
# https://www.soumu.go.jp/main_content/000420038.csv for the 2013
# revision) -- unlike the IO-sector<->JSIC correspondence above, this is
# JSIC's *own* internal hierarchy, sourced from a completely separate
# document, with no reference to any IO table sector at all.
#
# One row per classification item, at whatever level it's defined at, with
# every ancestor level's code already filled in with its real value and
# every level *below* its own left at that level's all-zero placeholder
# ("00" for 中分類/major_group, "000" for 小分類/group, "0000" for
# 細分類/industry) -- e.g. a 中分類-level row has a real
# `major_group_code` but `group_code == "000"` and `industry_code ==
# "0000"`. A row's own level is therefore identified by which
# placeholder-vs-real boundary it sits at (see get_jsic_conversion()),
# not by a separate "level" column, which the source doesn't provide.
#
# `header = FALSE` (not the `read.csv()` default `TRUE`) is required
# alongside `skip = 1`: with the default, `read.csv()` treats the first
# row *after* skipping as a header row too and silently discards it before
# `col.names` is even applied, dropping the file's first real data row
# (confirmed empirically: without `header = FALSE`, the "A" division's own
# summary row went missing and every one of its detail rows failed to
# join to a division name).
read_file_jsic_class_csv <- function(file) {
  utils::read.csv(
    file,
    header = FALSE,
    skip = 1,
    fileEncoding = "CP932",
    colClasses = "character",
    col.names = c(
      "division_code",
      "major_group_code",
      "group_code",
      "industry_code",
      "name"
    )
  ) |>
    tibble::as_tibble()
}

# Builds the JSIC-own-hierarchy crosswalk (industry/"detail" -> group ->
# major_group -> division) from `read_file_jsic_class_csv()`'s flat file, always
# anchored at the finest ("detail") level going up -- mirroring how
# get_sector_conversion() always anchors IO's own tier crosswalk at
# "basic". One name-lookup tibble is extracted per coarser level (keyed by
# that level's own code path), then joined onto every detail-level row;
# joining on the full ancestor code path (not just e.g. `major_group_code`
# alone) matches how the source itself nests codes, even though
# `major_group_code`/`group_code` happen to be globally unique in practice
# (confirmed empirically against the 2013-revision file: 99 distinct
# `major_group_code` values with or without `division_code` in the key).
#
# `jsic_revision_year` is a plain pass-through for the same reason as
# get_sector_jsic()'s: which revision a given file is only stated in
# soumu's page text, not a parseable column.
get_jsic_conversion <- function(jsic_class_raw, jsic_revision_year) {
  is_division <- jsic_class_raw$major_group_code == "00"
  is_major_group <- !is_division & jsic_class_raw$group_code == "000"
  is_group <- !is_division &
    !is_major_group &
    jsic_class_raw$industry_code == "0000"
  is_detail <- !is_division & !is_major_group & !is_group

  division <- jsic_class_raw |>
    dplyr::filter(is_division) |>
    dplyr::select(division_code, name) |>
    dplyr::rename(division_name = name)
  major_group <- jsic_class_raw |>
    dplyr::filter(is_major_group) |>
    dplyr::select(division_code, major_group_code, name) |>
    dplyr::rename(major_group_name = name)
  group <- jsic_class_raw |>
    dplyr::filter(is_group) |>
    dplyr::select(division_code, major_group_code, group_code, name) |>
    dplyr::rename(group_name = name)
  detail <- jsic_class_raw |>
    dplyr::filter(is_detail) |>
    dplyr::rename(industry_name = name)

  detail_full <- detail |>
    dplyr::left_join(division, by = "division_code") |>
    dplyr::left_join(
      major_group,
      by = c("division_code", "major_group_code")
    ) |>
    dplyr::left_join(
      group,
      by = c("division_code", "major_group_code", "group_code")
    )

  # One row per (`detail`, coarser tier) pair -- looping over the three
  # coarser tiers' own (code, name) column pairs, rather than writing out
  # one `transmute()` per tier, keeps the three blocks from drifting out of
  # sync with each other as they're edited.
  tier_columns <- list(
    group = c("group_code", "group_name"),
    major_group = c("major_group_code", "major_group_name"),
    division = c("division_code", "division_name")
  )
  purrr::imap(tier_columns, \(cols, tier) {
    detail_full |>
      dplyr::transmute(
        jsic_class_from = "detail",
        jsic_code_from = industry_code,
        jsic_name_from = industry_name,
        jsic_class_to = tier,
        jsic_code_to = .data[[cols[1]]],
        jsic_name_to = .data[[cols[2]]]
      )
  }) |>
    dplyr::bind_rows() |>
    dplyr::mutate(jsic_revision_year = jsic_revision_year)
}
