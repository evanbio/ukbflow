# Cut a continuous UKB variable into quantile-based or custom groups

Creates a new factor column by binning a continuous variable into `n`
groups. When `breaks` is omitted, group boundaries are derived from
quantiles of the observed data (equal-frequency binning). When `breaks`
is supplied, those values are used as interior cut points.

## Usage

``` r
derive_cut(data, col, n, breaks = NULL, labels = NULL, name = NULL)
```

## Arguments

- data:

  (data.frame or data.table) UKB data.

- col:

  (character) Name of the source numeric column.

- n:

  (integer) Number of groups. Supported values: `2`, `3`, `4`, `5`.

- breaks:

  (numeric vector or NULL) Interior cut points; length must equal
  `n - 1`. When `NULL` (default), quantile-based equal- frequency
  boundaries are computed automatically.

- labels:

  (character vector or NULL) Group labels of length `n`. Defaults to
  `"Q1"`, `"Q2"`, ..., `"Qn"`.

- name:

  (character or NULL) Name for the new column. Defaults to `"{col}_bi"`
  / `"{col}_tri"` / `"{col}_quad"` / `"{col}_quin"` for `n` = 2 / 3 / 4
  / 5.

## Value

The input `data` with one new factor column appended. Always returns a
`data.table`.

## Details

Before binning, a numeric summary (mean, median, SD, Q1, Q3, missing
rate) is printed for the source column. After binning, the group
distribution is printed via an internal summary helper.

Only one column can be processed per call; loop over columns explicitly
when binning multiple variables.

**data.table pass-by-reference**: when the input is a `data.table`, the
new column is added in-place. Pass `data.table::copy(data)` to preserve
the original.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- derive_cut(df, col = "age_at_recruitment", n = 3)
# → adds age_at_recruitment_tri with groups Q1 / Q2 / Q3

df <- derive_cut(df, col = "age_at_recruitment", n = 3,
                 breaks = c(50, 60),
                 labels = c("<50", "50-59", "60+"),
                 name   = "age_group")
} # }
```
