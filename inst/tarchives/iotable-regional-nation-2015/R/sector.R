# sector ------------------------------------------------------------------

target_sector <- tar_plan(
  tar_change(
    # https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200603&tstat=000001130583&cycle=0&year=20150&month=0
    file_sector,
    download_file(
      url = "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031839439&fileKind=0",
      destfile = "_targets/user/sector.xlsx"
    ),
    change = "0.1.0",
    format = "file"
  ),
  sector_raw = read_file_sector(
    file = file_sector
  ),
  conversion_sector_input = get_conversion_sector(
    sector_raw = sector_raw,
    axis = "input"
  ),
  conversion_sector_output = get_conversion_sector(
    sector_raw = sector_raw,
    axis = "output"
  ),
  sector_input = get_sector(
    conversion_sector = conversion_sector_input
  ),
  sector_output = get_sector(
    conversion_sector = conversion_sector_output
  )
)

read_file_sector <- function(file) {
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
  sector_industry <- readxl::read_excel(
    file,
    sheet = "内生部門",
    skip = 7,
    col_names = col_names,
    col_types = "text",
    .name_repair = "minimal"
  ) |>
    tibble::add_column(
      sector_type = "industry",
      .before = 1
    )
  sector_final_demand <- readxl::read_excel(
    file,
    sheet = "最終需要部門・粗付加価値部門",
    skip = 4,
    n_max = 42,
    col_names = col_names,
    col_types = "text",
    .name_repair = "minimal"
  ) |>
    mutate(
      sector_type = case_when(
        str_starts(sector_name_basic, "輸出") ~ "export",
        str_starts(sector_name_basic, "（控除）") ~ "import",
        sector_name_basic == "国内生産額" ~ "total",
        .default = "final_demand"
      ),
      .before = 1
    )
  sector_value_added <- readxl::read_excel(
    file,
    sheet = "最終需要部門・粗付加価値部門",
    skip = 52,
    n_max = 13,
    col_names = col_names[-(1:2)],
    col_types = "text",
    .name_repair = "minimal"
  ) |>
    mutate(
      sector_type = case_when(
        sector_name_basic == "国内生産額" ~ "total",
        .default = "value_added"
      ),
      .before = 1
    )
  sector <- bind_rows(
    sector_industry,
    sector_value_added,
    sector_final_demand,
  ) |>
    mutate(
      across(
        c(
          sector_name_basic,
          sector_name_small,
          sector_name_medium,
          sector_name_large
        ),
        \(x)
          case_match(
            sector_type,
            c("value_added", "final_demand", "export", "import", "total") ~
              str_replace(x, "国内", "域内"),
            .default = x
          )
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
    ) |>
    mutate(
      output_sector_name_basic = str_c(
        output_sector_code_basic,
        sector_name_basic,
        sep = "_"
      ),
      .before = output_sector_code_basic
    ) |>
    mutate(
      input_sector_name_basic = str_c(
        input_sector_code_basic,
        sector_name_basic,
        sep = "_"
      ),
      .before = input_sector_code_basic
    ) |>
    select(
      !c(output_sector_code_basic, input_sector_code_basic, sector_name_basic)
    ) |>
    unite(
      "sector_name_small",
      c(sector_code_small, sector_name_small)
    ) |>
    unite(
      "sector_name_medium",
      c(sector_code_medium, sector_name_medium)
    ) |>
    unite(
      "sector_name_large",
      c(sector_code_large, sector_name_large)
    )

  sector_template <- readxl::read_excel(
    file,
    sheet = "13部門分類",
    skip = 4,
    n_max = 38,
    col_names = c(
      "sector_code_large",
      "sector_name_large",
      "sector_template_code",
      "sector_name_template"
    ),
    col_types = "text",
    .name_repair = "minimal"
  ) |>
    fill(
      sector_template_code,
      sector_name_template
    ) |>
    unite(
      "sector_name_large",
      c(sector_code_large, sector_name_large)
    ) |>
    unite(
      "sector_name_template",
      c(sector_template_code, sector_name_template)
    ) |>
    mutate(
      across(
        c(sector_name_large, sector_name_template),
        \(x) str_remove_all(x, "\\s")
      )
    )

  sector <- sector |>
    left_join(
      sector_template,
      by = join_by(sector_name_large)
    ) |>
    mutate(
      across(
        sector_name_template,
        \(x)
          case_match(
            sector_type,
            c("value_added", "final_demand", "export", "import", "total") ~
              sector_name_large,
            .default = x
          )
      )
    )

  sector_input <- sector |>
    drop_na(input_sector_name_basic) |>
    select(!output_sector_name_basic) |>
    rename(
      sector_name_basic = input_sector_name_basic
    ) |>
    mutate(
      across(
        sector_type,
        \(x) factor(x, c("industry", "value_added", "total"))
      )
    )
  sector_output <- sector |>
    drop_na(output_sector_name_basic) |>
    select(!input_sector_name_basic) |>
    rename(
      sector_name_basic = output_sector_name_basic
    ) |>
    mutate(
      across(
        sector_type,
        \(x)
          factor(x, c("industry", "final_demand", "export", "import", "total"))
      )
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
      col_name_sector_class_from = str_c("sector_name_", sector_class_from),
      col_name_sector_class_to = str_c("sector_name_", sector_class_to)
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

get_sector <- function(conversion_sector) {
  conversion_sector |>
    select(
      sector_type,
      sector_class_from,
      sector_name_from
    ) |>
    rename(
      sector_class = sector_class_from,
      sector_name = sector_name_from
    ) |>
    mutate(
      across(sector_type, fct_drop)
    ) |>
    distinct()
}
