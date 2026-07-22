target_sector <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200603&tstat=000001218140&stat_infid=000040186856
    file_sector_ja,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000040186856&fileKind=0",
      destfile = "_targets/user/sector_ja.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  tar_change(
    # https://www.e-stat.go.jp/en/stat-search/files?page=1&toukei=00200603&metadata=1&data=1
    file_sector_en,
    download_file(
      url = "https://www.e-stat.go.jp/en/stat-search/file-download?statInfId=000040186856&fileKind=0",
      destfile = "_targets/user/sector_en.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  sector_raw = read_file_sector(
    file_ja = file_sector_ja,
    file_en = file_sector_en
  ),
  sector_conversion_input = get_conversion_sector(
    sector_raw = sector_raw,
    axis = "input"
  ),
  sector_conversion_output = get_conversion_sector(
    sector_raw = sector_raw,
    axis = "output"
  ),
  sector_input = get_sector(
    sector_raw = sector_raw,
    axis = "input"
  ),
  sector_output = get_sector(
    sector_raw = sector_raw,
    axis = "output"
  ),
)

read_file_sector <- function(file_ja, file_en) {
  col_names <- c(
    "output_sector_code_basic_1",
    "output_sector_code_basic_2",
    "input_sector_code_basic_1",
    "input_sector_code_basic_2",
    "sector_name_basic",
    "sector_code_small",
    "sector_name_small",
    "sector_code_medium",
    "sector_name_medium",
    "sector_code_large",
    "sector_name_large"
  )

  sector_industry_ja <- readxl::read_excel(
    file_ja,
    sheet = "内生部門",
    col_names = col_names,
    col_types = "text"
  ) |>
    filter(
      str_detect(output_sector_code_basic_1, "^\\d{4}$") |
        str_detect(input_sector_code_basic_1, "^\\d{4}$")
    ) |>
    mutate(
      sector_type = case_when(
        sector_name_basic == "内生部門計" ~ "industry_total",
        .default = "industry"
      ),
      .before = 1
    )

  sector_final_demand_value_added_ja <- readxl::read_excel(
    file_ja,
    sheet = "最終需要部門・粗付加価値部門",
    col_names = col_names,
    col_types = "text"
  ) |>
    filter(
      str_detect(output_sector_code_basic_1, "^\\d{4}") |
        str_detect(input_sector_code_basic_1, "^\\d{4}")
    ) |>
    mutate(
      sector_type = case_when(
        !is.na(output_sector_code_basic_1) ~ case_when(
          sector_name_basic == "国内最終需要計" ~ "regional_final_demand_total",
          sector_name_basic == "国内需要合計" ~ "regional_demand_total",
          sector_name_basic == "輸出計" ~ "export_total",
          str_starts(sector_name_basic, "輸出") ~ "export",
          sector_name_basic == "最終需要計" ~ "final_demand_total",
          sector_name_basic == "需要合計" ~ "demand_total",
          sector_name_basic == "（控除）輸入計" ~ "import_total",
          str_starts(sector_name_basic, "（控除）") ~ "import",
          sector_name_basic == "最終需要部門計" ~ "final_demand_sector_total",
          str_starts(sector_name_basic, "商業マージン") ~ "trade_margin",
          str_starts(sector_name_basic, "貨物運賃") ~ "transport_margin",
          sector_name_basic == "国内生産額" ~ "total",
          .default = "final_demand"
        ),
        !is.na(input_sector_code_basic_1) ~ case_when(
          sector_name_basic == "粗付加価値部門計" ~ "value_added_total",
          sector_name_basic == "国内生産額" ~ "total",
          .default = "value_added"
        ),
      ),
      .before = 1
    )

  sector_ja <- bind_rows(
    sector_industry_ja,
    sector_final_demand_value_added_ja
  ) |>
    mutate(
      output_sector_code_basic = str_c(
        output_sector_code_basic_1,
        output_sector_code_basic_2
      ),
      .keep = "unused",
      .before = output_sector_code_basic_1
    ) |>
    mutate(
      input_sector_code_basic = str_c(
        input_sector_code_basic_1,
        input_sector_code_basic_2
      ),
      .keep = "unused",
      .before = input_sector_code_basic_1
    ) |>
    mutate(
      across(
        c(input_sector_code_basic, output_sector_code_basic),
        \(x) str_remove(x, "P$")
      ),
      # e-stat's classification workbook has at least one row using
      # half-width parentheses ("と畜場(公営)★★") where the actual IO table
      # data uses full-width ("と畜場（公営）★★") for the same code; without
      # normalizing, this basic-level name never matches the real table's
      # dimnames, so it silently fails to reclassify to any coarser
      # sector_class (see `io_reclass()` in iotable_producer_price.R).
      across(
        sector_name_basic,
        \(x) str_replace_all(x, c("\\(" = "（", "\\)" = "）"))
      ),
      across(
        c(sector_name_small, sector_name_medium, sector_name_large),
        \(x) str_remove_all(x, "\\s|^（続き）|（\\d／\\d）$")
      )
    ) |>
    fill(
      sector_code_small,
      sector_name_small,
      sector_code_medium,
      sector_name_medium,
      sector_code_large,
      sector_name_large
    )

  # The English workbook mirrors the Japanese one's code columns exactly
  # (only the name columns are translated), so sheet-reading uses the same
  # `col_names`/regex-filter/fill() pipeline; the English names are joined
  # onto the Japanese rows by numeric sector code below. Unlike the Japanese
  # cell text (no inter-word spaces, so all whitespace is line-wrap noise),
  # English names use real spaces between words, so `str_squish()` collapses
  # incidental whitespace instead of deleting it.
  sector_en <- bind_rows(
    readxl::read_excel(
      file_en,
      sheet = "Endogeneous Sectors",
      col_names = col_names,
      col_types = "text"
    ) |>
      filter(
        str_detect(output_sector_code_basic_1, "^\\d{4}$") |
          str_detect(input_sector_code_basic_1, "^\\d{4}$")
      ),
    readxl::read_excel(
      file_en,
      sheet = "Final Demand_Gross Valued Added",
      col_names = col_names,
      col_types = "text"
    ) |>
      filter(
        str_detect(output_sector_code_basic_1, "^\\d{4}") |
          str_detect(input_sector_code_basic_1, "^\\d{4}")
      )
  ) |>
    mutate(
      output_sector_code_basic = str_c(
        output_sector_code_basic_1,
        output_sector_code_basic_2
      ),
      .keep = "unused",
      .before = output_sector_code_basic_1
    ) |>
    mutate(
      input_sector_code_basic = str_c(
        input_sector_code_basic_1,
        input_sector_code_basic_2
      ),
      .keep = "unused",
      .before = input_sector_code_basic_1
    ) |>
    mutate(
      across(
        c(input_sector_code_basic, output_sector_code_basic),
        \(x) str_remove(x, "P$")
      ),
      across(
        c(sector_name_small, sector_name_medium, sector_name_large),
        str_squish
      )
    ) |>
    fill(
      sector_code_small,
      sector_name_small,
      sector_code_medium,
      sector_name_medium,
      sector_code_large,
      sector_name_large
    ) |>
    rename(
      sector_name_basic_en = sector_name_basic,
      sector_name_small_en = sector_name_small,
      sector_name_medium_en = sector_name_medium,
      sector_name_large_en = sector_name_large
    )

  sector <- sector_ja |>
    left_join(
      sector_en,
      by = c(
        "output_sector_code_basic",
        "input_sector_code_basic",
        "sector_code_small",
        "sector_code_medium",
        "sector_code_large"
      )
    ) |>
    mutate(
      output_sector_name_basic_ja = str_c(
        output_sector_code_basic,
        sector_name_basic,
        sep = "_"
      ),
      output_sector_name_basic_en = str_c(
        output_sector_code_basic,
        sector_name_basic_en,
        sep = "_"
      ),
      .before = output_sector_code_basic
    ) |>
    mutate(
      input_sector_name_basic_ja = str_c(
        input_sector_code_basic,
        sector_name_basic,
        sep = "_"
      ),
      input_sector_name_basic_en = str_c(
        input_sector_code_basic,
        sector_name_basic_en,
        sep = "_"
      ),
      .before = input_sector_code_basic
    ) |>
    mutate(
      sector_name_small_ja = str_c(
        sector_code_small,
        sector_name_small,
        sep = "_"
      ),
      sector_name_small_en = str_c(
        sector_code_small,
        sector_name_small_en,
        sep = "_"
      ),
      sector_name_medium_ja = str_c(
        sector_code_medium,
        sector_name_medium,
        sep = "_"
      ),
      sector_name_medium_en = str_c(
        sector_code_medium,
        sector_name_medium_en,
        sep = "_"
      ),
      sector_name_large_ja = str_c(
        sector_code_large,
        sector_name_large,
        sep = "_"
      ),
      sector_name_large_en = str_c(
        sector_code_large,
        sector_name_large_en,
        sep = "_"
      ),
      .keep = "unused"
    ) |>
    select(
      !c(
        output_sector_code_basic,
        input_sector_code_basic,
        sector_name_basic,
        sector_name_basic_en
      )
    )

  # 13-sector "template" classification: Japanese-only source data (e-stat
  # publishes no English equivalent of the "13部門分類" sheet). Industry
  # rows therefore have no English template *name*, but the numeric
  # template code itself is language-independent, so industry rows show
  # just the code (e.g. "01") rather than losing the label entirely.
  # Non-industry rows fall back to sector_name_large_en, mirroring the
  # Japanese fallback below.
  sector_template <- readxl::read_excel(
    file_ja,
    sheet = "13部門分類",
    col_names = c(
      "sector_code_large",
      "sector_name_large",
      "sector_template_code",
      "sector_name_template"
    ),
    col_types = "text",
    .name_repair = "minimal"
  ) |>
    filter(str_detect(sector_code_large, "^\\d{2}$")) |>
    fill(
      sector_template_code,
      sector_name_template
    ) |>
    unite(
      "sector_name_large_ja",
      c(sector_code_large, sector_name_large)
    ) |>
    unite(
      "sector_name_template_ja",
      c(sector_template_code, sector_name_template),
      remove = FALSE
    ) |>
    mutate(
      across(
        c(sector_name_large_ja, sector_name_template_ja, sector_template_code),
        \(x) str_remove_all(x, "\\s")
      )
    )

  sector <- sector |>
    left_join(
      sector_template,
      by = join_by(sector_name_large_ja)
    ) |>
    mutate(
      sector_name_template_ja = recode_values(
        sector_type,
        "industry" ~ sector_name_template_ja,
        default = sector_name_large_ja
      ),
      sector_name_template_en = recode_values(
        sector_type,
        "industry" ~ sector_template_code,
        default = sector_name_large_en
      )
    ) |>
    select(!sector_template_code)

  sector_input <- sector |>
    drop_na(input_sector_name_basic_ja) |>
    select(!starts_with("output_sector_name_basic")) |>
    rename(
      sector_name_basic_ja = input_sector_name_basic_ja,
      sector_name_basic_en = input_sector_name_basic_en
    ) |>
    mutate(
      across(sector_type, as_factor),
      across(ends_with("_ja"), \(x) str_remove_all(x, "\\s")),
      across(ends_with("_en"), str_squish)
    )
  sector_output <- sector |>
    drop_na(output_sector_name_basic_ja) |>
    select(!starts_with("input_sector_name_basic")) |>
    rename(
      sector_name_basic_ja = output_sector_name_basic_ja,
      sector_name_basic_en = output_sector_name_basic_en
    ) |>
    mutate(
      across(sector_type, as_factor),
      across(ends_with("_ja"), \(x) str_remove_all(x, "\\s")),
      across(ends_with("_en"), str_squish)
    )

  list(
    input = sector_input,
    output = sector_output
  )
}

get_conversion_sector <- function(sector_raw, axis) {
  sector <- sector_raw[[axis]]

  sector_class <- as_factor(c("basic", "small", "medium", "large", "template"))

  expand_grid(
    sector_class_from = sector_class,
    sector_class_to = sector_class
  ) |>
    mutate(
      col_name_sector_class_from = str_c(
        "sector_name_",
        sector_class_from,
        "_ja"
      ),
      col_name_sector_class_to = str_c("sector_name_", sector_class_to, "_ja")
    ) |>
    mutate(
      data = list(col_name_sector_class_from, col_name_sector_class_to) |>
        pmap(\(col_name_sector_class_from, col_name_sector_class_to) {
          tibble(
            sector_type = sector$sector_type,
            sector_name_from = sector[[col_name_sector_class_from]],
            sector_name_to = sector[[col_name_sector_class_to]]
          )
        }),
      .keep = "unused"
    ) |>
    unnest(data) |>
    relocate(sector_type) |>
    arrange(sector_type) |>
    distinct()
}

get_sector_long <- function(sector) {
  sector_class <- as_factor(c("basic", "small", "medium", "large", "template"))

  tibble(sector_class = sector_class) |>
    mutate(
      col_name_ja = str_c("sector_name_", sector_class, "_ja"),
      col_name_en = str_c("sector_name_", sector_class, "_en")
    ) |>
    mutate(
      data = list(col_name_ja, col_name_en) |>
        pmap(\(col_name_ja, col_name_en) {
          tibble(
            sector_type = sector$sector_type,
            sector_name_ja = sector[[col_name_ja]],
            sector_name_en = sector[[col_name_en]]
          )
        }),
      .keep = "unused"
    ) |>
    unnest(data) |>
    relocate(sector_type) |>
    arrange(sector_type) |>
    mutate(across(sector_type, fct_drop)) |>
    distinct()
}

get_sector <- function(sector_raw, axis) {
  sector <- get_sector_long(sector_raw[[axis]])

  if (axis == "output") {
    # The real IO table's output axis always labels "industry" sectors using
    # the *input* axis's classification (see
    # `convert_sector_iotable_producer_price_basic()`'s `bind_rows(input |>
    # filter(io_sector_type(sector) == "industry"), ...)` in
    # iotable_producer_price.R), because e-stat's classification workbook
    # lists a handful of industry codes (e.g. the scrap-material memo items
    # "2612_鉄屑"/"2712_非鉄金属屑") only on the input side, leaving no
    # output-side small/medium/large/template grouping for them. Backfill
    # those from the input axis so `sector_output` doesn't miss sectors that
    # the real table's output dimension does have. Verified (2020 data) that
    # every other industry code already classifies identically on both axes
    # at every sector_class, so this only adds rows, never replaces one.
    industry_input <- get_sector_long(sector_raw$input) |>
      filter(sector_type %in% c("industry", "industry_total"))
    missing <- industry_input |>
      anti_join(
        sector,
        by = c("sector_type", "sector_class", "sector_name_ja")
      )
    sector <- bind_rows(sector, missing) |>
      arrange(sector_type) |>
      distinct()
  }

  sector
}
