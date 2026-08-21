# Prepare UKB covariates for analysis

Converts decoded UKB columns to analysis-ready types: character-encoded
numeric fields to `numeric`, and categorical fields to `factor`. Prints
a concise summary for each converted column - mean / median / SD /
missing rate for numeric columns, and level counts for factor columns -
so you can verify distributions without leaving the pipeline.

## Usage

``` r
derive_covariate(
  data,
  as_numeric = NULL,
  as_factor = NULL,
  factor_levels = NULL,
  max_levels = 5L
)
```

## Arguments

- data:

  (data.frame or data.table) UKB data, typically output of
  [`derive_missing`](https://evanbio.github.io/ukbflow/reference/derive_missing.md).

- as_numeric:

  (character or NULL) Column names to convert to `numeric`. Values that
  cannot be coerced (e.g. residual text) become `NA` with a warning.
  Default: `NULL`.

- as_factor:

  (character or NULL) Column names to convert to `factor`. Default
  levels are the sorted unique non-NA values unless overridden by
  `factor_levels`. Default: `NULL`.

- factor_levels:

  (named list or NULL) Custom level ordering for specific factor
  columns. Names must match entries in `as_factor`; values are character
  vectors of levels in the desired order (first level = reference group
  in regression). Columns not listed use default ordering. Default:
  `NULL`.

- max_levels:

  (integer) Factor columns with more levels than this threshold trigger
  a warning suggesting the user consider collapsing categories. Default:
  `5L`.

## Value

The input `data` (invisibly) with converted columns. Always returns a
`data.table`.

## Details

**data.table pass-by-reference**: when the input is a `data.table`,
modifications are made in-place. Pass `data.table::copy(data)` to
preserve the original.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
dt <- derive_missing(dt)
#> ✔ derive_missing: replaced 48 values across 3 columns (action = "na").
# messy_label is a character column with numeric-looking values ("-1", "999")
# mixed with non-parseable strings -- demonstrates coercion and NA warnings
derive_covariate(dt,
  as_numeric = "messy_label",
  as_factor  = c("p31", "p20116_i0"),
  factor_levels = list(
    p20116_i0 = c("Never", "Previous", "Current")
  )
)
#> ── Numeric ─────────────────────────────────────────────────────────────────────
#> ! messy_label: 23 values coerced to NA.
#> messy_label: mean=465.67, median=-1, sd=516.4, Q1=-1, Q3=999, NA=85% (n=85)
#> ── Factor ──────────────────────────────────────────────────────────────────────
#> p31 [2 levels]
#> Female: n=50 (50%)
#> Male: n=50 (50%)
#> <NA>: n=0 (0%)
#> p20116_i0 [3 levels]
#> Never: n=51 (51%)
#> Previous: n=29 (29%)
#> Current: n=18 (18%)
#> <NA>: n=2 (2%)
```
