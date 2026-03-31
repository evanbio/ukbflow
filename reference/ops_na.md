# Summarise missing values by column

Scans each column of a data.frame or data.table and returns the count
and percentage of missing values. Results are sorted by missingness in
descending order. Columns above 10\\ and 10\\ `threshold`.

## Usage

``` r
ops_na(data, threshold = 0, verbose = TRUE)
```

## Arguments

- data:

  A data.frame or data.table to scan.

- threshold:

  (numeric) Columns with `pct_na <= threshold` are silenced from the
  per-column CLI output. The summary block is always shown. Default `0`:
  every column with any missing value is listed.

- verbose:

  (logical) Print the CLI report. Default `TRUE`.

## Value

An invisible data.table with columns `column`, `n_na`, and `pct_na`,
sorted by `pct_na` descending. `n_na` counts both `NA` and `""`. Always
contains all columns regardless of `threshold` (which only affects CLI
output).

## Details

**Missing value definition**: a value is counted as missing if it is
`NA` *or* an empty string (`""`). Empty strings are treated as missing
because UKB exports frequently use `""` as a placeholder for absent text
values. This means `n_na` and `pct_na` reflect *effective* missingness,
not just [`is.na()`](https://rdrr.io/r/base/NA.html). Numeric and
logical columns are not affected (they cannot hold `""`).

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42

# Show all columns with any missing value
ops_na(dt)
#> ── ops_na ──────────────────────────────────────────────────────────────────────
#> ℹ 100 rows | 75 columns | threshold = 0%
#> ✖ p20001_i0_a3  100 / 100  (100.00%)
#> ✖ p20001_i0_a4  100 / 100  (100.00%)
#> ✖ p20006_i0_a3  100 / 100  (100.00%)
#> ✖ p20006_i0_a4  100 / 100  (100.00%)
#> ✖ p41280_a4     100 / 100  (100.00%)
#> ✖ p41280_a5     100 / 100  (100.00%)
#> ✖ p41280_a6     100 / 100  (100.00%)
#> ✖ p41280_a7     100 / 100  (100.00%)
#> ✖ p41280_a8     100 / 100  (100.00%)
#> ✖ messy_allna   100 / 100  (100.00%)
#> ✖ messy_empty   100 / 100  (100.00%)
#> ✖ p20001_i0_a2   99 / 100  ( 99.00%)
#> ✖ p20006_i0_a2   99 / 100  ( 99.00%)
#> ✖ p40002_i0_a2   99 / 100  ( 99.00%)
#> ✖ p20001_i0_a0   98 / 100  ( 98.00%)
#> ✖ p20006_i0_a0   98 / 100  ( 98.00%)
#> ✖ p40006_i2      98 / 100  ( 98.00%)
#> ✖ p40011_i2      98 / 100  ( 98.00%)
#> ✖ p40012_i2      98 / 100  ( 98.00%)
#> ✖ p40005_i2      98 / 100  ( 98.00%)
#> ✖ p40002_i0_a0   97 / 100  ( 97.00%)
#> ✖ p20002_i0_a4   96 / 100  ( 96.00%)
#> ✖ p20008_i0_a4   96 / 100  ( 96.00%)
#> ✖ p40006_i1      96 / 100  ( 96.00%)
#> ✖ p40011_i1      96 / 100  ( 96.00%)
#> ✖ p40012_i1      96 / 100  ( 96.00%)
#> ✖ p40005_i1      96 / 100  ( 96.00%)
#> ✖ p40002_i0_a1   96 / 100  ( 96.00%)
#> ✖ p131742        95 / 100  ( 95.00%)
#> ✖ p20001_i0_a1   94 / 100  ( 94.00%)
#> ✖ p20006_i0_a1   94 / 100  ( 94.00%)
#> ✖ p40006_i0      94 / 100  ( 94.00%)
#> ✖ p40011_i0      94 / 100  ( 94.00%)
#> ✖ p40012_i0      94 / 100  ( 94.00%)
#> ✖ p40005_i0      94 / 100  ( 94.00%)
#> ✖ p20002_i0_a2   93 / 100  ( 93.00%)
#> ✖ p20008_i0_a2   93 / 100  ( 93.00%)
#> ✖ p20002_i0_a3   92 / 100  ( 92.00%)
#> ✖ p20008_i0_a3   92 / 100  ( 92.00%)
#> ✖ p41280_a3      92 / 100  ( 92.00%)
#> ✖ p40001_i0      85 / 100  ( 85.00%)
#> ✖ p40000_i0      85 / 100  ( 85.00%)
#> ✖ p41280_a2      83 / 100  ( 83.00%)
#> ✖ p20002_i0_a0   82 / 100  ( 82.00%)
#> ✖ p20008_i0_a0   82 / 100  ( 82.00%)
#> ✖ p20002_i0_a1   80 / 100  ( 80.00%)
#> ✖ p20008_i0_a1   80 / 100  ( 80.00%)
#> ✖ p41280_a1      77 / 100  ( 77.00%)
#> ✖ p41270         62 / 100  ( 62.00%)
#> ✖ p41280_a0      62 / 100  ( 62.00%)
#> ✖ messy_label    57 / 100  ( 57.00%)
#> ────────────────────────────────────────────────────────────────────────────────
#> ✖ 51 columns ≥ 10% missing
#> ✔ 24 columns complete (0% missing)

# Only list columns with > 10% missing in the CLI output
ops_na(dt, threshold = 10)
#> ── ops_na ──────────────────────────────────────────────────────────────────────
#> ℹ 100 rows | 75 columns | threshold = 10%
#> ✖ p20001_i0_a3  100 / 100  (100.00%)
#> ✖ p20001_i0_a4  100 / 100  (100.00%)
#> ✖ p20006_i0_a3  100 / 100  (100.00%)
#> ✖ p20006_i0_a4  100 / 100  (100.00%)
#> ✖ p41280_a4     100 / 100  (100.00%)
#> ✖ p41280_a5     100 / 100  (100.00%)
#> ✖ p41280_a6     100 / 100  (100.00%)
#> ✖ p41280_a7     100 / 100  (100.00%)
#> ✖ p41280_a8     100 / 100  (100.00%)
#> ✖ messy_allna   100 / 100  (100.00%)
#> ✖ messy_empty   100 / 100  (100.00%)
#> ✖ p20001_i0_a2   99 / 100  ( 99.00%)
#> ✖ p20006_i0_a2   99 / 100  ( 99.00%)
#> ✖ p40002_i0_a2   99 / 100  ( 99.00%)
#> ✖ p20001_i0_a0   98 / 100  ( 98.00%)
#> ✖ p20006_i0_a0   98 / 100  ( 98.00%)
#> ✖ p40006_i2      98 / 100  ( 98.00%)
#> ✖ p40011_i2      98 / 100  ( 98.00%)
#> ✖ p40012_i2      98 / 100  ( 98.00%)
#> ✖ p40005_i2      98 / 100  ( 98.00%)
#> ✖ p40002_i0_a0   97 / 100  ( 97.00%)
#> ✖ p20002_i0_a4   96 / 100  ( 96.00%)
#> ✖ p20008_i0_a4   96 / 100  ( 96.00%)
#> ✖ p40006_i1      96 / 100  ( 96.00%)
#> ✖ p40011_i1      96 / 100  ( 96.00%)
#> ✖ p40012_i1      96 / 100  ( 96.00%)
#> ✖ p40005_i1      96 / 100  ( 96.00%)
#> ✖ p40002_i0_a1   96 / 100  ( 96.00%)
#> ✖ p131742        95 / 100  ( 95.00%)
#> ✖ p20001_i0_a1   94 / 100  ( 94.00%)
#> ✖ p20006_i0_a1   94 / 100  ( 94.00%)
#> ✖ p40006_i0      94 / 100  ( 94.00%)
#> ✖ p40011_i0      94 / 100  ( 94.00%)
#> ✖ p40012_i0      94 / 100  ( 94.00%)
#> ✖ p40005_i0      94 / 100  ( 94.00%)
#> ✖ p20002_i0_a2   93 / 100  ( 93.00%)
#> ✖ p20008_i0_a2   93 / 100  ( 93.00%)
#> ✖ p20002_i0_a3   92 / 100  ( 92.00%)
#> ✖ p20008_i0_a3   92 / 100  ( 92.00%)
#> ✖ p41280_a3      92 / 100  ( 92.00%)
#> ✖ p40001_i0      85 / 100  ( 85.00%)
#> ✖ p40000_i0      85 / 100  ( 85.00%)
#> ✖ p41280_a2      83 / 100  ( 83.00%)
#> ✖ p20002_i0_a0   82 / 100  ( 82.00%)
#> ✖ p20008_i0_a0   82 / 100  ( 82.00%)
#> ✖ p20002_i0_a1   80 / 100  ( 80.00%)
#> ✖ p20008_i0_a1   80 / 100  ( 80.00%)
#> ✖ p41280_a1      77 / 100  ( 77.00%)
#> ✖ p41270         62 / 100  ( 62.00%)
#> ✖ p41280_a0      62 / 100  ( 62.00%)
#> ✖ messy_label    57 / 100  ( 57.00%)
#> ────────────────────────────────────────────────────────────────────────────────
#> ✖ 51 columns ≥ 10% missing
#> ✔ 24 columns complete (0% missing)

# Programmatic use — retrieve result silently
result <- ops_na(dt, verbose = FALSE)
result[pct_na > 50]
#>           column  n_na pct_na
#>           <char> <int>  <num>
#>  1: p20001_i0_a3   100    100
#>  2: p20001_i0_a4   100    100
#>  3: p20006_i0_a3   100    100
#>  4: p20006_i0_a4   100    100
#>  5:    p41280_a4   100    100
#>  6:    p41280_a5   100    100
#>  7:    p41280_a6   100    100
#>  8:    p41280_a7   100    100
#>  9:    p41280_a8   100    100
#> 10:  messy_allna   100    100
#> 11:  messy_empty   100    100
#> 12: p20001_i0_a2    99     99
#> 13: p20006_i0_a2    99     99
#> 14: p40002_i0_a2    99     99
#> 15: p20001_i0_a0    98     98
#> 16: p20006_i0_a0    98     98
#> 17:    p40006_i2    98     98
#> 18:    p40011_i2    98     98
#> 19:    p40012_i2    98     98
#> 20:    p40005_i2    98     98
#> 21: p40002_i0_a0    97     97
#> 22: p20002_i0_a4    96     96
#> 23: p20008_i0_a4    96     96
#> 24:    p40006_i1    96     96
#> 25:    p40011_i1    96     96
#> 26:    p40012_i1    96     96
#> 27:    p40005_i1    96     96
#> 28: p40002_i0_a1    96     96
#> 29:      p131742    95     95
#> 30: p20001_i0_a1    94     94
#> 31: p20006_i0_a1    94     94
#> 32:    p40006_i0    94     94
#> 33:    p40011_i0    94     94
#> 34:    p40012_i0    94     94
#> 35:    p40005_i0    94     94
#> 36: p20002_i0_a2    93     93
#> 37: p20008_i0_a2    93     93
#> 38: p20002_i0_a3    92     92
#> 39: p20008_i0_a3    92     92
#> 40:    p41280_a3    92     92
#> 41:    p40001_i0    85     85
#> 42:    p40000_i0    85     85
#> 43:    p41280_a2    83     83
#> 44: p20002_i0_a0    82     82
#> 45: p20008_i0_a0    82     82
#> 46: p20002_i0_a1    80     80
#> 47: p20008_i0_a1    80     80
#> 48:    p41280_a1    77     77
#> 49:       p41270    62     62
#> 50:    p41280_a0    62     62
#> 51:  messy_label    57     57
#>           column  n_na pct_na
#>           <char> <int>  <num>
```
