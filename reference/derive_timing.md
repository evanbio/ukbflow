# Classify disease timing relative to UKB baseline assessment

Assigns each participant an integer timing category based on whether
their disease date falls before or after the baseline visit date:

## Usage

``` r
derive_timing(data, name, baseline_col, status_col = NULL, date_col = NULL)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix. The new column is named
  `{name}_timing`. Also used to derive default `status_col` and
  `date_col` when those are `NULL`.

- baseline_col:

  (character) Name of the baseline date column in `data` (e.g.
  `"date_baseline"` or `"p53_i0"`).

- status_col:

  (character or NULL) Name of the logical disease flag. `NULL` =
  `paste0(name, "_status")`.

- date_col:

  (character or NULL) Name of the disease date column (`IDate` or
  `Date`). `NULL` = `paste0(name, "_date")`.

## Value

The input `data` (invisibly) with one new integer column `{name}_timing`
(0/1/2/`NA`) added in-place. Always returns a `data.table`.

## Details

- `0`:

  No disease (`status_col` is `FALSE`).

- `1`:

  Prevalent - disease date on or before baseline.

- `2`:

  Incident - disease date strictly after baseline.

- `NA`:

  Case with missing date; timing cannot be determined.

Call once per timing variable needed (e.g. once for the combined case,
once per individual source).

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_hes(dt, name = "htn", icd10 = "I10")
#> ✔ derive_hes (htn): 8 cases, 8 with date.
derive_timing(dt, name = "htn_hes",
              status_col   = "htn_hes",
              date_col     = "htn_hes_date",
              baseline_col = "p53_i0")
#> ✔ derive_timing (htn_hes_timing):
#> ℹ   0 (no disease): 92
#> ℹ   1 (prevalent):  3
#> ℹ   2 (incident):   5
#> ℹ   NA (no date):   0
```
