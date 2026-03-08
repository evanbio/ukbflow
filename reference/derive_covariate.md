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

The input `data` with converted columns. Always returns a `data.table`.

## Details

**data.table pass-by-reference**: when the input is a `data.table`,
modifications are made in-place. Pass `data.table::copy(data)` to
preserve the original.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- extract_pheno(c(31, 20116, 738, 874)) |>
  decode_values() |>
  decode_names() |>
  derive_missing() |>
  derive_covariate(
    as_numeric = "duration_of_walks_i0",
    as_factor  = c("sex", "smoking_status_i0"),
    factor_levels = list(
      smoking_status_i0 = c("Never", "Previous", "Current")
    )
  )
} # }
```
