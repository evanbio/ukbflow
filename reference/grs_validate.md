# Validate GRS predictive performance

For each GRS column, computes four sets of validation metrics:

1.  **Per SD** - OR (logistic) or HR (Cox) per 1-SD increase.

2.  **High vs Low** - OR / HR comparing top 20\\ (extreme tertile
    grouping: Low / Mid / High).

3.  **Trend test** - P-trend across quartiles (Q1–Q4).

4.  **Discrimination** - AUC (logistic) or C-index (Cox).

## Usage

``` r
grs_validate(
  data,
  grs_cols = NULL,
  outcome_col,
  time_col = NULL,
  covariates = NULL
)
```

## Arguments

- data:

  A `data.frame` or `data.table`.

- grs_cols:

  Character vector of GRS column names to validate. If `NULL` (default),
  all columns whose names contain `"grs"` (case-insensitive) are
  selected automatically. All specified columns must be numeric.

- outcome_col:

  Character scalar. Name of the outcome column (`0`/`1` or
  `TRUE`/`FALSE`).

- time_col:

  Character scalar or `NULL`. Name of the follow-up time column. When
  `NULL` (default), logistic regression is used; when supplied, Cox
  regression is used.

- covariates:

  Character vector or `NULL`. Covariates for the fully adjusted model.
  When `NULL`, only unadjusted and age-sex adjusted models are run.

## Value

A named `list` with four `data.table` elements:

- `per_sd`: OR / HR per 1-SD increase in GRS.

- `high_vs_low`: OR / HR for High vs Low extreme tertile.

- `trend`: P-trend across Q1–Q4 quartiles.

- `discrimination`: AUC (logistic) or C-index (Cox) with 95\\

## Details

GRS grouping columns are created internally via
[`derive_cut`](https://evanbio.github.io/ukbflow/reference/derive_cut.md)
and are not added to the user's data. When `time_col` is `NULL`,
logistic regression is used throughout; when supplied, Cox proportional
hazards models are used.

Models follow the same adjustment logic as
[`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
/
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md):
unadjusted and age-sex adjusted models are always included; a fully
adjusted model is added when `covariates` is non-`NULL`.

## Examples

``` r
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- grs_standardize(dt, grs_cols = c("grs_bmi", "grs_raw"))
#> Error: Column(s) not found in data: "grs_raw"

# Cox (survival)
res <- grs_validate(
  data        = dt,
  grs_cols    = c("grs_bmi_z", "grs_raw_z"),
  outcome_col = "dm_status",
  time_col    = "dm_followup_years"
)
#> Error: Column(s) not found in data: "grs_bmi_z" and "grs_raw_z"
res$per_sd
#> Error: object 'res' not found
res$discrimination
#> Error: object 'res' not found

# Logistic (cross-sectional) — requires pROC
if (requireNamespace("pROC", quietly = TRUE)) {
  res_logit <- grs_validate(
    data        = dt,
    grs_cols    = c("grs_bmi_z", "grs_raw_z"),
    outcome_col = "dm_status"
  )
  res_logit$discrimination
}
#> Error: Column(s) not found in data: "grs_bmi_z" and "grs_raw_z"
```
