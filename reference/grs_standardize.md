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

## Details

**Unlike the `derive_*` functions, this one does not modify its input by
reference.** It always builds and returns a new `data.table`, so a bare
`grs_standardize(dt)` leaves `dt` without its `_z` columns however `dt`
was stored – assign the result back.

## Examples

``` r
dt <- data.frame(
  IID   = 1:5,
  GRS_a = c(0.12, 0.34, 0.56, 0.23, 0.45),
  GRS_b = c(1.1,  0.9,  1.3,  0.8,  1.0)
)
dt <- grs_standardize(dt)   # assign back: dt is not modified in place
#> Auto-detected 2 GRS column(s): "GRS_a" and "GRS_b"
#> ✔ GRS_a -> GRS_a_z  [mean=0.34, sd=0.1739]
#> ✔ GRS_b -> GRS_b_z  [mean=1.02, sd=0.1924]
names(dt)
#> [1] "IID"     "GRS_a"   "GRS_a_z" "GRS_b"   "GRS_b_z"

grs_zscore(dt[, c("IID", "GRS_a")])   # grs_zscore() is the same function
#> Auto-detected 1 GRS column(s): "GRS_a"
#> ✔ GRS_a -> GRS_a_z  [mean=0.34, sd=0.1739]
#>      IID GRS_a    GRS_a_z
#>    <int> <num>      <num>
#> 1:     1  0.12 -1.2649111
#> 2:     2  0.34  0.0000000
#> 3:     3  0.56  1.2649111
#> 4:     4  0.23 -0.6324555
#> 5:     5  0.45  0.6324555
```
