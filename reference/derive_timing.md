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

The input `data` with one new integer column `{name}_timing`
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
if (FALSE) { # \dontrun{
# Combined case timing (uses outcome_status + outcome_date from derive_case)
df <- derive_timing(df, name = "outcome", baseline_col = "date_baseline")
# → outcome_timing

# Individual source timing
df <- derive_timing(df, name = "outcome_icd10",
                    status_col   = "outcome_icd10",
                    date_col     = "outcome_icd10_date",
                    baseline_col = "date_baseline")
# → outcome_icd10_timing
} # }
```
