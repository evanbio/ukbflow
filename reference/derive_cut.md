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

  (integer) Number of groups. Any integer `>= 2` is accepted. Commonly
  used values are `2`, `3`, `4`, `5`.

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
  / 5; other values of `n` produce `"{col}_g{n}"`.

## Value

The input `data` (invisibly) with one new factor column appended. Always
returns a `data.table`.

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
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_cut(dt, col = "p21001_i0", n = 3)
#> ── Source: p21001_i0 ───────────────────────────────────────────────────────────
#> p21001_i0: mean=25.86, median=25.66, sd=5.51, Q1=22.27, Q3=29.4, NA=0% (n=0)
#> ── New column: p21001_i0_tri ───────────────────────────────────────────────────
#> p21001_i0_tri [3 levels]
#> Q1: n=34 (34%)
#> Q2: n=33 (33%)
#> Q3: n=33 (33%)
#> <NA>: n=0 (0%)

# Custom breaks and labels
derive_cut(dt, col = "p21001_i0", n = 3,
           breaks = c(25, 30),
           labels = c("<25", "25-30", "30+"),
           name   = "bmi_group")
#> ── Source: p21001_i0 ───────────────────────────────────────────────────────────
#> p21001_i0: mean=25.86, median=25.66, sd=5.51, Q1=22.27, Q3=29.4, NA=0% (n=0)
#> ── New column: bmi_group ───────────────────────────────────────────────────────
#> bmi_group [3 levels]
#> <25: n=45 (45%)
#> 25-30: n=31 (31%)
#> 30+: n=24 (24%)
#> <NA>: n=0 (0%)
```
