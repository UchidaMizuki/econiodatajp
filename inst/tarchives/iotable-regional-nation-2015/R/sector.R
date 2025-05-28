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
  sector = read_file_sector(
    file = file_sector
  )
)

read_file_sector <- function(file) {
  col_names <- c(
    "output_sector_basic_code_1",
    "output_sector_basic_code_2",
    "input_sector_basic_code_1",
    "input_sector_basic_code_2",
    "sector_basic_name",
    "sector_small_code",
    "sector_small_name",
    "sector_medium_code",
    "sector_medium_name",
    "sector_large_code",
    "sector_large_name"
  )
  sector_industry <- readxl::read_excel(
    file,
    sheet = "内生部門",
    skip = 7,
    col_names = col_names,
    col_types = "text",
    .name_repair = "minimal"
  )
  sector_final_demand <- readxl::read_excel(
    file,
    sheet = "最終需要部門・粗付加価値部門",
    skip = 4,
    n_max = 42,
    col_names = col_names,
    col_types = "text",
    .name_repair = "minimal"
  )
  sector_value_added <- readxl::read_excel(
    file,
    sheet = "最終需要部門・粗付加価値部門",
    skip = 52,
    n_max = 13,
    col_names = col_names[-(1:2)],
    col_types = "text",
    .name_repair = "minimal"
  )
  sector <- bind_rows(
    industry = sector_industry,
    value_added = sector_value_added,
    final_demand = sector_final_demand,
    .id = "sector_type"
  ) |>
    mutate(
      across(
        sector_type,
        \(x)
          case_match(
            sector_basic_name,
            "国内生産額" ~ "total",
            .default = x
          ) |>
            factor(c("industry", "value_added", "final_demand", "total"))
      )
    ) |>
    mutate(
      output_sector_basic_code = str_c(
        output_sector_basic_code_1,
        output_sector_basic_code_2
      ),
      .keep = "unused",
      .before = output_sector_basic_code_1
    ) |>
    mutate(
      input_sector_basic_code = str_c(
        input_sector_basic_code_1,
        input_sector_basic_code_2
      ),
      .keep = "unused",
      .before = input_sector_basic_code_1
    ) |>
    mutate(
      across(
        c(sector_small_name, sector_medium_name, sector_large_name),
        \(x) str_remove_all(x, "^（続き）|（\\d／\\d）$")
      )
    ) |>
    fill(
      sector_small_code,
      sector_small_name,
      sector_medium_code,
      sector_medium_name,
      sector_large_code,
      sector_large_name
    ) |>
    mutate(
      output_sector_basic = str_c(
        output_sector_basic_code,
        sector_basic_name,
        sep = "_"
      ),
      .before = output_sector_basic_code
    ) |>
    mutate(
      input_sector_basic = str_c(
        input_sector_basic_code,
        sector_basic_name,
        sep = "_"
      ),
      .before = input_sector_basic_code
    ) |>
    select(
      !c(output_sector_basic_code, input_sector_basic_code, sector_basic_name)
    ) |>
    unite(
      "sector_small",
      c(sector_small_code, sector_small_name)
    ) |>
    unite(
      "sector_medium",
      c(sector_medium_code, sector_medium_name)
    ) |>
    unite(
      "sector_large",
      c(sector_large_code, sector_large_name)
    )

  sector_template <- readxl::read_excel(
    file,
    sheet = "13部門分類",
    skip = 4,
    n_max = 38,
    col_names = c(
      "sector_large_code",
      "sector_large_name",
      "sector_template_code",
      "sector_template_name"
    ),
    col_types = "text",
    .name_repair = "minimal"
  ) |>
    fill(
      sector_template_code,
      sector_template_name
    ) |>
    unite(
      "sector_large",
      c(sector_large_code, sector_large_name)
    ) |>
    unite(
      "sector_template",
      c(sector_template_code, sector_template_name)
    )

  sector <- sector |>
    left_join(
      sector_template,
      by = join_by(sector_large)
    ) |>
    mutate(
      across(
        sector_template,
        \(x)
          case_match(
            sector_type,
            c("value_added", "final_demand", "total") ~ sector_large,
            .default = x
          )
      )
    )

  sector_input <- sector |>
    drop_na(input_sector_basic) |>
    select(!output_sector_basic) |>
    rename(
      sector_basic = input_sector_basic
    )
  sector_output <- sector |>
    drop_na(output_sector_basic) |>
    select(!input_sector_basic) |>
    rename(
      sector_basic = output_sector_basic
    )

  list(
    input = sector_input,
    output = sector_output
  )
}
