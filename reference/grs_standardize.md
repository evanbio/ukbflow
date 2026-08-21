# Standardise GRS columns by Z-score transformation

Adds a `_z` column for every selected GRS column:
`z = (x - mean(x)) / sd(x)`. The original columns are kept unchanged.
`grs_zscore` is an alias for this function.

## Usage

``` r
grs_standardize(data, grs_cols = NULL)

grs_zscore(data, grs_cols = NULL)
```

## Arguments

- data:

  A `data.frame` or `data.table` containing at least one GRS column.

- grs_cols:

  Character vector of column names to standardise. If `NULL` (default),
  all columns whose names contain `"grs"` (case-insensitive) are
  selected automatically.

## Value

The input `data` as a `data.table` with one additional `_z` column per
GRS column appended after its source column.

## Examples

``` r
dt <- data.frame(
  IID   = 1:5,
  GRS_a = c(0.12, 0.34, 0.56, 0.23, 0.45),
  GRS_b = c(1.1,  0.9,  1.3,  0.8,  1.0)
)
grs_standardize(dt)
#> Auto-detected 2 GRS column(s): "GRS_a" and "GRS_b"
#> ✔ GRS_a -> GRS_a_z  [mean=0.34, sd=0.1739]
#> ✔ GRS_b -> GRS_b_z  [mean=1.02, sd=0.1924]
#>      IID GRS_a    GRS_a_z GRS_b    GRS_b_z
#>    <int> <num>      <num> <num>      <num>
#> 1:     1  0.12 -1.2649111   1.1  0.4159002
#> 2:     2  0.34  0.0000000   0.9 -0.6238503
#> 3:     3  0.56  1.2649111   1.3  1.4556507
#> 4:     4  0.23 -0.6324555   0.8 -1.1437255
#> 5:     5  0.45  0.6324555   1.0 -0.1039750
grs_zscore(dt)   # identical
#> Auto-detected 2 GRS column(s): "GRS_a" and "GRS_b"
#> ✔ GRS_a -> GRS_a_z  [mean=0.34, sd=0.1739]
#> ✔ GRS_b -> GRS_b_z  [mean=1.02, sd=0.1924]
#>      IID GRS_a    GRS_a_z GRS_b    GRS_b_z
#>    <int> <num>      <num> <num>      <num>
#> 1:     1  0.12 -1.2649111   1.1  0.4159002
#> 2:     2  0.34  0.0000000   0.9 -0.6238503
#> 3:     3  0.56  1.2649111   1.3  1.4556507
#> 4:     4  0.23 -0.6324555   0.8 -1.1437255
#> 5:     5  0.45  0.6324555   1.0 -0.1039750
```
