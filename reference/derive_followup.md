# Compute follow-up end date and follow-up time for survival analysis

Adds two columns to `data`:

- `{name}_followup_end` (IDate) - the earliest of the outcome event
  date, death date, lost-to-follow-up date, and the administrative
  censoring date.

- `{name}_followup_years` (numeric) - time in years from `baseline_col`
  to `{name}_followup_end`.

## Usage

``` r
derive_followup(
  data,
  name,
  event_col,
  baseline_col,
  censor_date,
  death_col = NULL,
  lost_col = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix, e.g. `"outcome"` produces
  `outcome_followup_end` and `outcome_followup_years`.

- event_col:

  (character) Name of the outcome event date column (e.g.
  `"outcome_date"`).

- baseline_col:

  (character) Name of the baseline date column (e.g. `"date_baseline"`).

- censor_date:

  (Date or character) Scalar administrative censoring date, e.g.
  `as.Date("2022-06-01")`. A character string in `"YYYY-MM-DD"` format
  is also accepted.

- death_col:

  (character or NULL) Name of the death date column (UKB field 40000).
  `NULL` (default) triggers auto-detection via the
  [`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
  cache; pass `FALSE` to explicitly disable death as a competing
  end-point.

- lost_col:

  (character or NULL) Name of the lost-to-follow-up date column (UKB
  field 191). `NULL` (default) triggers auto-detection; pass `FALSE` to
  explicitly disable.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_followup_end` (IDate) and `{name}_followup_years` (numeric).

## Details

**data.table pass-by-reference**: when the input is a `data.table`, new
columns are added in-place via `:=`.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_hes(dt, name = "htn", icd10 = "I10")
#> ✔ derive_hes (htn): 8 cases, 8 with date.

# Death (p40000_i0) and loss to follow-up (p191) are auto-detected and
# censor the person-time; both are present in ops_toy() output.
derive_followup(dt,
  name         = "htn_hes",
  event_col    = "htn_hes_date",
  baseline_col = "p53_i0",
  censor_date  = as.Date("2022-06-01"))
#> ✔ derive_followup (htn_hes):
#> ℹ   htn_hes_followup_end: 100 / 100 non-missing
#> ℹ   htn_hes_followup_years: mean=13.04, median=13.33, range=[0.82, 16.41]

# FALSE disables an end-point explicitly -- here everyone is followed to
# the event or the administrative censor date, ignoring loss to follow-up.
derive_followup(dt,
  name         = "htn_admin",
  event_col    = "htn_hes_date",
  baseline_col = "p53_i0",
  censor_date  = as.Date("2022-06-01"),
  death_col    = "p40000_i0",
  lost_col     = FALSE)
#> ✔ derive_followup (htn_admin):
#> ℹ   htn_admin_followup_end: 100 / 100 non-missing
#> ℹ   htn_admin_followup_years: mean=13.02, median=13.27, range=[0.82, 16.41]
```
