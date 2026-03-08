# Cox regression lag sensitivity analysis

Runs Cox proportional hazards models at one or more lag periods to
assess whether associations are robust to the exclusion of early events.
For each lag, participants whose follow-up time is less than `lag_years`
are removed from the analysis dataset; follow-up time is kept on its
original scale (not shifted). This mirrors the approach used in UK
Biobank sensitivity analyses to address reverse causation and detection
bias.

## Usage

``` r
assoc_lag(
  data,
  outcome_col,
  time_col,
  exposure_col,
  lag_years = c(1, 2),
  covariates = NULL,
  base = TRUE,
  strata = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Event indicator column (0/1 or logical).

- time_col:

  (character) Follow-up time column (numeric, e.g. years).

- exposure_col:

  (character) One or more exposure variable names.

- lag_years:

  (numeric) One or more lag periods in the same units as `time_col`.
  Default: `c(1, 2)`. Use `0` to include the unfiltered full-cohort
  result as a reference.

- covariates:

  (character or NULL) Covariates for the Fully adjusted model. When
  `NULL`, only Unadjusted (and Age and sex adjusted if `base = TRUE`)
  are run.

- base:

  (logical) Auto-detect age and sex and include an Age and sex adjusted
  model. Default: `TRUE`.

- strata:

  (character or NULL) Optional stratification variable passed to
  [`survival::strata()`](https://rdrr.io/pkg/survival/man/strata.html).

- conf_level:

  (numeric) Confidence level for HR intervals. Default: `0.95`.

## Value

A `data.table` with one row per lag \\\times\\ exposure \\\times\\ term
\\\times\\ model combination, containing all columns produced by
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
plus:

- `lag_years`:

  The lag period applied (numeric).

- `n_excluded`:

  Number of participants excluded because their follow-up time was less
  than `lag_years`.

`lag_years` and `n_excluded` are placed immediately after `model` in the
column order.

## Details

Setting `lag_years = 0` (or including `0` in the vector) runs the model
on the full unfiltered cohort, providing a reference against which
lagged results can be compared.

The same three adjustment models produced by
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
are available here (**Unadjusted**, **Age and sex adjusted**, **Fully
adjusted**).

## Examples

``` r
if (FALSE) { # \dontrun{
assoc_lag(
  data         = ukb_df,
  outcome_col  = "cscc_status",
  time_col     = "followup_years",
  exposure_col = "ad_tf",
  lag_years    = c(0, 1, 2),
  covariates   = c("tdi", "smoking")
)
} # }
```
