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
if (FALSE) { # \dontrun{
dt <- ops_toy()

# Show all columns with any missing value
ops_na(dt)

# Only list columns with > 10% missing in the CLI output
ops_na(dt, threshold = 10)

# Programmatic use — retrieve result silently
result <- ops_na(dt, verbose = FALSE)
result[pct_na > 50]
} # }
```
