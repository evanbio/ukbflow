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
# \donttest{
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- grs_standardize(dt, grs_cols = "grs_bmi")
#> ✔ grs_bmi -> grs_bmi_z  [mean=0.8844, sd=2.5272]

res <- grs_validate(
  data        = dt,
  grs_cols    = "grs_bmi_z",
  outcome_col = "dm_status",
  time_col    = "dm_followup_years"
)
#> ── Creating GRS groups ─────────────────────────────────────────────────────────
#> ── Source: grs_bmi_z ───────────────────────────────────────────────────────────
#> grs_bmi_z: mean=0, median=0.01, sd=1, Q1=-0.69, Q3=0.66, NA=0% (n=0)
#> ── New column: grs_bmi_z_quad ──────────────────────────────────────────────────
#> grs_bmi_z_quad [4 levels]
#> Q1: n=125 (25%)
#> Q2: n=125 (25%)
#> Q3: n=125 (25%)
#> Q4: n=125 (25%)
#> <NA>: n=0 (0%)
#> ── Source: grs_bmi_z ───────────────────────────────────────────────────────────
#> grs_bmi_z: mean=0, median=0.01, sd=1, Q1=-0.69, Q3=0.66, NA=0% (n=0)
#> ── New column: grs_bmi_z_tri ───────────────────────────────────────────────────
#> grs_bmi_z_tri [3 levels]
#> Low: n=100 (20%)
#> Mid: n=300 (60%)
#> High: n=100 (20%)
#> <NA>: n=0 (0%)
#> ── Effect per SD (HR) ──────────────────────────────────────────────────────────
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 Cox regressions
#> ℹ Input cohort: 500 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── grs_bmi_z ──
#> 
#> ✔   Unadjusted | grs_bmi_z: HR 1.10 (0.74-1.65), p = 0.639
#> ✔   Age and sex adjusted | grs_bmi_z: HR 1.10 (0.73-1.66), p = 0.644
#> ✔ Done: 2 result rows across 1 exposure and 2 models.
#> ── High vs Low ─────────────────────────────────────────────────────────────────
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 Cox regressions
#> ℹ Input cohort: 500 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── grs_bmi_z_tri ──
#> 
#> ✔   Unadjusted | grs_bmi_z_triMid: HR 1.14 (0.38-3.47), p = 0.816
#> ✔   Unadjusted | grs_bmi_z_triHigh: HR 1.49 (0.42-5.29), p = 0.536
#> ✔   Age and sex adjusted | grs_bmi_z_triMid: HR 1.07 (0.35-3.30), p = 0.901
#> ✔   Age and sex adjusted | grs_bmi_z_triHigh: HR 1.48 (0.42-5.24), p = 0.547
#> ✔ Done: 4 result rows across 1 exposure and 2 models.
#> ── Trend test ──────────────────────────────────────────────────────────────────
#> ! Exposure grs_bmi_z_quad is not an ordered factor -- levels will be scored 0, 1, 2, ... (equal spacing assumed).
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_trend ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models (categorical + trend model per combination)
#> 
#> ── grs_bmi_z_quad ──
#> 
#> ℹ Levels: Q1 -> Q2 -> Q3 -> Q4 | Scores: 0, 1, 2, 3
#> ℹ   Unadjusted | grs_bmi_z_quadQ1: 1.00 (ref)
#> ✔   Unadjusted | grs_bmi_z_quadQ2: HR 1.52 (0.50-4.65), p = 0.461
#> ✔   Unadjusted | grs_bmi_z_quadQ3: HR 0.79 (0.21-2.93), p = 0.721
#> ✔   Unadjusted | grs_bmi_z_quadQ4: HR 1.38 (0.44-4.36), p = 0.579
#> ℹ   Unadjusted | trend: HR_per_score = 1.03 (0.72-1.48), p_trend = 0.854
#> ℹ   Age and sex adjusted | grs_bmi_z_quadQ1: 1.00 (ref)
#> ✔   Age and sex adjusted | grs_bmi_z_quadQ2: HR 1.45 (0.47-4.46), p = 0.513
#> ✔   Age and sex adjusted | grs_bmi_z_quadQ3: HR 0.76 (0.20-2.83), p = 0.677
#> ✔   Age and sex adjusted | grs_bmi_z_quadQ4: HR 1.37 (0.43-4.31), p = 0.594
#> ℹ   Age and sex adjusted | trend: HR_per_score = 1.03 (0.72-1.48), p_trend = 0.864
#> ✔ Done: 8 result rows across 1 exposure and 2 models.
#> ── C-index ─────────────────────────────────────────────────────────────────────
#> ✔ Validation complete.
res$per_sd
#>     exposure      term                model     n n_events person_years
#>       <char>    <char>                <ord> <int>    <num>        <num>
#> 1: grs_bmi_z grs_bmi_z           Unadjusted   463       24         6445
#> 2: grs_bmi_z grs_bmi_z Age and sex adjusted   463       24         6445
#>          HR  CI_lower CI_upper   p_value         HR_label
#>       <num>     <num>    <num>     <num>           <char>
#> 1: 1.101385 0.7361392 1.647854 0.6385214 1.10 (0.74-1.65)
#> 2: 1.101363 0.7312927 1.658707 0.6439986 1.10 (0.73-1.66)

if (requireNamespace("pROC", quietly = TRUE)) {
  res_logit <- grs_validate(
    data        = dt,
    grs_cols    = "grs_bmi_z",
    outcome_col = "dm_status"
  )
  res_logit$discrimination
}
#> ── Creating GRS groups ─────────────────────────────────────────────────────────
#> ── Source: grs_bmi_z ───────────────────────────────────────────────────────────
#> grs_bmi_z: mean=0, median=0.01, sd=1, Q1=-0.69, Q3=0.66, NA=0% (n=0)
#> ── New column: grs_bmi_z_quad ──────────────────────────────────────────────────
#> grs_bmi_z_quad [4 levels]
#> Q1: n=125 (25%)
#> Q2: n=125 (25%)
#> Q3: n=125 (25%)
#> Q4: n=125 (25%)
#> <NA>: n=0 (0%)
#> ── Source: grs_bmi_z ───────────────────────────────────────────────────────────
#> grs_bmi_z: mean=0, median=0.01, sd=1, Q1=-0.69, Q3=0.66, NA=0% (n=0)
#> ── New column: grs_bmi_z_tri ───────────────────────────────────────────────────
#> grs_bmi_z_tri [3 levels]
#> Low: n=100 (20%)
#> Mid: n=300 (60%)
#> High: n=100 (20%)
#> <NA>: n=0 (0%)
#> ── Effect per SD (OR) ──────────────────────────────────────────────────────────
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_logistic ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 logistic regressions
#> ℹ Input cohort: 500 participants | CI method: wald (n/n_cases reflect each model's actual analysis set)
#> 
#> ── grs_bmi_z ──
#> 
#> ✔   Unadjusted | grs_bmi_z: OR 0.97 (0.74-1.27), p = 0.81
#> ✔   Age and sex adjusted | grs_bmi_z: OR 0.96 (0.74-1.26), p = 0.79
#> ✔ Done: 2 result rows across 1 exposure and 2 models.
#> ── High vs Low ─────────────────────────────────────────────────────────────────
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_logistic ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 logistic regressions
#> ℹ Input cohort: 500 participants | CI method: wald (n/n_cases reflect each model's actual analysis set)
#> 
#> ── grs_bmi_z_tri ──
#> 
#> ✔   Unadjusted | grs_bmi_z_triMid: OR 0.79 (0.40-1.53), p = 0.478
#> ✔   Unadjusted | grs_bmi_z_triHigh: OR 0.92 (0.41-2.07), p = 0.836
#> ✔   Age and sex adjusted | grs_bmi_z_triMid: OR 0.76 (0.39-1.50), p = 0.428
#> ✔   Age and sex adjusted | grs_bmi_z_triHigh: OR 0.91 (0.40-2.05), p = 0.815
#> ✔ Done: 4 result rows across 1 exposure and 2 models.
#> ── Trend test ──────────────────────────────────────────────────────────────────
#> ! Exposure grs_bmi_z_quad is not an ordered factor -- levels will be scored 0, 1, 2, ... (equal spacing assumed).
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_trend ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models (categorical + trend model per combination)
#> 
#> ── grs_bmi_z_quad ──
#> 
#> ℹ Levels: Q1 -> Q2 -> Q3 -> Q4 | Scores: 0, 1, 2, 3
#> ℹ   Unadjusted | grs_bmi_z_quadQ1: 1.00 (ref)
#> ✔   Unadjusted | grs_bmi_z_quadQ2: OR 0.69 (0.32-1.48), p = 0.339
#> ✔   Unadjusted | grs_bmi_z_quadQ3: OR 0.75 (0.36-1.58), p = 0.45
#> ✔   Unadjusted | grs_bmi_z_quadQ4: OR 0.87 (0.42-1.80), p = 0.712
#> ℹ   Unadjusted | trend: OR_per_score = 0.96 (0.76-1.22), p_trend = 0.76
#> ℹ   Age and sex adjusted | grs_bmi_z_quadQ1: 1.00 (ref)
#> ✔   Age and sex adjusted | grs_bmi_z_quadQ2: OR 0.67 (0.31-1.44), p = 0.306
#> ✔   Age and sex adjusted | grs_bmi_z_quadQ3: OR 0.73 (0.34-1.55), p = 0.41
#> ✔   Age and sex adjusted | grs_bmi_z_quadQ4: OR 0.86 (0.42-1.78), p = 0.683
#> ℹ   Age and sex adjusted | trend: OR_per_score = 0.96 (0.75-1.22), p_trend = 0.738
#> ✔ Done: 8 result rows across 1 exposure and 2 models.
#> ── AUC ─────────────────────────────────────────────────────────────────────────
#> ✔ Validation complete.
#>          GRS       AUC  CI_lower  CI_upper
#>       <char>     <num>     <num>     <num>
#> 1: grs_bmi_z 0.5103253 0.4291761 0.5914745
# }
```
