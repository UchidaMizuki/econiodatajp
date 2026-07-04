

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
#> trying URL 'https://www.hkd.mlit.go.jp/ky/ki/keikaku/splaat000001yqxt-att/splaat000001yr7c.xlsx'
#> Content type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' length 1637807 bytes (1.6 MB)
#> ==================================================
#> downloaded 1.6 MB
#> 
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

Every prefecture at once, as a single table with a region dimension:

``` r
io_table_get(year = 2011, region_type = "multiregional")
#> trying URL 'https://www.rieti.go.jp/jp/database/r-io2011/data/i-preio2011.xlsx'
#> Content type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' length 14015943 bytes (13.4 MB)
#> ==================================================
#> downloaded 13.4 MB
#> 
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

`sector_class` controls the sector classification granularity
(`"basic"`, `"small"`, `"medium"`, `"large"`, or `"template"` for the
national table; a single fixed granularity for prefectural/multiregional
tables). `competitive_import` and `language` are only meaningful for the
national table.

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
