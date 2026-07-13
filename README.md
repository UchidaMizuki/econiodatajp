

<!-- README.md is generated from README.qmd. Please edit that file -->

# econiodatajp

<!-- badges: start -->

<!-- badges: end -->

econiodatajp provides ready-to-use Japanese input-output (IO) tables,
built from data published by the Ministry of Internal Affairs and
Communications ([e-Stat](https://www.e-stat.go.jp/)) and other sources.
Each table is returned as an
[econio](https://github.com/UchidaMizuki/econio) input-output table
object, so it works directly with econio’s analysis functions
(`io_reclass()`, `io_leontief_inverse()`, and so on).

Tables are archived and rebuilt on demand via
[tarchives](https://github.com/UchidaMizuki/tarchives)/
[targets](https://books.ropensci.org/targets/), so `io_table_get()` (or
`io_table_target()`, for use inside your own `_targets.R` pipeline)
downloads and processes each source file only once per version.

## Installation

You can install the development version of econiodatajp from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("UchidaMizuki/econiodatajp")
```

## Usage

`io_table_get()` covers three shapes of table, selected via
`region_type` and `area`.

The national IO table (`region_type = "regional"` is the default; `area`
defaults to `"nation"`). `language` defaults to `"en"` with a one-time
note; pass `language = "ja"` for the original Japanese sector names:

``` r
library(econiodatajp)

io_table_get(year = 2020, sector_class = "medium")
#> ℹ Defaulting to `language = "en"`.
#> ℹ Pass `language = "ja"` for the original Japanese sector names (the
#>   authoritative source).
#> # Input-output table: regional
#> # Dimensions:         input [115], output [119]
#> # Input:              115 sectors
#> # Output:             119 sectors
#> # Import type:        competitive
#>    input$sector                   
#>    <sector>                       
#>  1 <industry> 011_Crop cultivation
#>  2 <industry> 011_Crop cultivation
#>  3 <industry> 011_Crop cultivation
#>  4 <industry> 011_Crop cultivation
#>  5 <industry> 011_Crop cultivation
#>  6 <industry> 011_Crop cultivation
#>  7 <industry> 011_Crop cultivation
#>  8 <industry> 011_Crop cultivation
#>  9 <industry> 011_Crop cultivation
#> 10 <industry> 011_Crop cultivation
#> # ℹ 13,675 more rows
#> # ℹ 2 more variables: output <tibble[,1]>, . <dbl>
```

One prefecture (`area` accepts a numeric code or a `"NN_name"`
fragment):

``` r
io_table_get(year = 2015, area = 1)
#> # Input-output table: regional
#> # Dimensions:         input [112], output [117]
#> # Input:              112 sectors
#> # Output:             117 sectors
#> # Import type:        competitive
#>    input$sector               output$sector                                .
#>    <sector>                   <sector>                                 <dbl>
#>  1 <industry> 01_食用耕種農業 <industry> 01_食用耕種農業         20647000000
#>  2 <industry> 01_食用耕種農業 <industry> 02_非食用耕種農業        1217000000
#>  3 <industry> 01_食用耕種農業 <industry> 03_畜産                  6907000000
#>  4 <industry> 01_食用耕種農業 <industry> 04_農業サービス           732000000
#>  5 <industry> 01_食用耕種農業 <industry> 05_林業                    99000000
#>  6 <industry> 01_食用耕種農業 <industry> 06_漁業                           0
#>  7 <industry> 01_食用耕種農業 <industry> 07_石炭・原油・天然ガス           0
#>  8 <industry> 01_食用耕種農業 <industry> 08_その他の鉱業                   0
#>  9 <industry> 01_食用耕種農業 <industry> 09_畜産食料品             195000000
#> 10 <industry> 01_食用耕種農業 <industry> 10_水産食料品             563000000
#> # ℹ 13,094 more rows
```

Every prefecture at once, as a single table with a region dimension
(`region_class` has no default and must be specified for a
`"multiregional"` table):

``` r
io_table_get(year = 2011, region_type = "multiregional", region_class = "pref")
#> # Input-output table: multi-regional
#> # Dimensions:         input [1,739], output [1,833]
#> # Input:              47 regions, 31 industries
#> # Output:             47 regions, 31 industries
#> # Import type:        competitive
#>    input$region $sector                    output$region            .
#>    <glue>       <sector>                   <glue>               <dbl>
#>  1 01_北海道    <industry> 0100_農林水産業 01_北海道     242716000000
#>  2 01_北海道    <industry> 0100_農林水産業 01_北海道         14000000
#>  3 01_北海道    <industry> 0100_農林水産業 01_北海道     631181000000
#>  4 01_北海道    <industry> 0100_農林水産業 01_北海道        165000000
#>  5 01_北海道    <industry> 0100_農林水産業 01_北海道        804000000
#>  6 01_北海道    <industry> 0100_農林水産業 01_北海道        279000000
#>  7 01_北海道    <industry> 0100_農林水産業 01_北海道         11000000
#>  8 01_北海道    <industry> 0100_農林水産業 01_北海道                0
#>  9 01_北海道    <industry> 0100_農林水産業 01_北海道                0
#> 10 01_北海道    <industry> 0100_農林水産業 01_北海道                0
#> # ℹ 3,187,577 more rows
#> # ℹ 1 more variable: output$sector <sector>
```

Or the official 9-region block breakdown instead
(`region_class = "block"`; only FY2005 is published):

``` r
io_table_get(year = 2005, region_type = "multiregional", region_class = "block")
#> # Input-output table: multi-regional
#> # Dimensions:         input [180], output [171]
#> # Input:              9 regions, 12 industries
#> # Output:             9 regions, 12 industries
#> # Import type:        competitive
#>    input$region $sector                 output$region            .
#>    <glue>       <sector>                <glue>               <dbl>
#>  1 1_北海道     <industry> 1_農林水産業 1_北海道      274730000000
#>  2 1_北海道     <industry> 1_農林水産業 1_北海道         180000000
#>  3 1_北海道     <industry> 1_農林水産業 1_北海道      659752000000
#>  4 1_北海道     <industry> 1_農林水産業 1_北海道                 0
#>  5 1_北海道     <industry> 1_農林水産業 1_北海道           1000000
#>  6 1_北海道     <industry> 1_農林水産業 1_北海道       41690000000
#>  7 1_北海道     <industry> 1_農林水産業 1_北海道        2807000000
#>  8 1_北海道     <industry> 1_農林水産業 1_北海道                 0
#>  9 1_北海道     <industry> 1_農林水産業 1_北海道         252000000
#> 10 1_北海道     <industry> 1_農林水産業 1_北海道           4000000
#> # ℹ 30,770 more rows
#> # ℹ 1 more variable: output$sector <sector>
```

`sector_class` controls the sector classification granularity
(`"basic"`, `"small"`, `"medium"`, `"large"`, or `"template"` for the
national table; a fixed single value for a prefecture (`"medium"`) or a
`region_class = "pref"` multiregional table (`"large"`); `"coarse"`,
`"medium"`, or `"fine"` for a `region_class = "block"` multiregional
table). `competitive_import` and `language` are only meaningful for the
national table; `region_class` has no default and must be specified for
a `"multiregional"` table (and is otherwise unsupported).

To declare one of these tables as a target in your own `{targets}`
pipeline instead of fetching it eagerly, use `io_table_target()` with
the same arguments:

``` r
# _targets.R
library(targets)
library(econiodatajp)

list(
  io_table_target(iotable_nation_2020, year = 2020, sector_class = "medium")
)
```
