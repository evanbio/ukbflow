# Dose-response trend analysis

Fits categorical and trend models simultaneously for each ordered-factor
exposure, returning per-category effect estimates alongside a p-value
for linear trend. Two models are run internally per exposure \\\times\\
adjustment combination:

## Usage

``` r
assoc_trend(
  data,
  outcome_col,
  time_col = NULL,
  exposure_col,
  method = c("coxph", "logistic", "linear"),
  covariates = NULL,
  base = TRUE,
  scores = NULL,
  conf_level = 0.95
)

assoc_tr(
  data,
  outcome_col,
  time_col = NULL,
  exposure_col,
  method = c("coxph", "logistic", "linear"),
  covariates = NULL,
  base = TRUE,
  scores = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Outcome column name.

- time_col:

  (character or NULL) Follow-up time column (required when
  `method = "coxph"`).

- exposure_col:

  (character) One or more exposure column names. Each must be a `factor`
  (ordered or unordered). The first level is used as the reference
  group.

- method:

  (character) Regression method: `"coxph"` (default), `"logistic"`, or
  `"linear"`.

- covariates:

  (character or NULL) Covariates for the Fully adjusted model. Default:
  `NULL`.

- base:

  (logical) Include Unadjusted and Age-and-sex-adjusted models. Default:
  `TRUE`.

- scores:

  (numeric or NULL) Numeric scores assigned to factor levels in level
  order. Length must equal `nlevels` of every exposure. `NULL` (default)
  uses `0, 1, 2, ...`

- conf_level:

  (numeric) Confidence level. Default: `0.95`.

## Value

A `data.table` with one row per exposure \\\times\\ level \\\times\\
model, containing:

- `exposure`:

  Exposure variable name.

- `level`:

  Factor level (ordered factor preserving original level order).

- `term`:

  Coefficient name as returned by the model (reference row uses
  `paste0(exposure, ref_level)`).

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `n`:

  Participants in model (after NA removal).

- ...:

  Effect estimate columns from the categorical model: `HR`/`OR`/`beta`,
  `CI_lower`, `CI_upper`, `p_value`, and a formatted label. Reference
  row has `HR = 1` / `beta = 0` and `NA` for CI and p. Cox models
  additionally include `n_events` and `person_years`; logistic includes
  `n_cases`; linear includes `se`.

- `HR_per_score` / `OR_per_score` / `beta_per_score`:

  Per-score-unit effect estimate from the trend model. Shared across all
  levels within the same exposure \\\times\\ model.

- `HR_per_score_label` / `OR_per_score_label` / `beta_per_score_label`:

  Formatted string for the per-score estimate.

- `p_trend`:

  P-value for linear trend from the trend model. Shared across all
  levels within the same exposure \\\times\\ model.

## Details

1.  **Categorical model** - exposure treated as a factor; produces one
    row per non-reference level (HR / OR / \\\beta\\ vs reference).

2.  **Trend model** - exposure recoded as numeric scores (default: 0, 1,
    2, ...); produces the per-score-unit effect estimate (`*_per_score`)
    and `p_trend`.

Both results are merged: the output contains a reference row (effect = 1
/ 0, CI = NA) followed by non-reference rows, with `*_per_score` and
`p_trend` appended as shared columns (same value within each exposure
\\\times\\ model combination).

**Scores**: By default levels are scored 0, 1, 2, ... so the reference
group = 0 and each step = 1 unit. Supply `scores` to use meaningful
units (e.g. median years per category) - only `p_trend` and the
per-score estimate change; per-category HRs are unaffected.

**Adjustment models**: follows the same logic as
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md) -
Unadjusted and Age-and-sex-adjusted models are included by default
(`base = TRUE`); a Fully adjusted model is added when `covariates` is
non-NULL.

## Examples

``` r
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

# Trend across BMI categories (default integer scores 0, 1, 2, 3)
res <- assoc_trend(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "bmi_cat",
  method       = "coxph",
  covariates   = c("p21022", "p31", "tdi_cat", "p20116_i0")
)
#> ! Exposure bmi_cat is not an ordered factor -- levels will be scored 0, 1, 2, ... (equal spacing assumed).
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_trend ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models (categorical + trend model per combination)
#> 
#> ── bmi_cat ──
#> 
#> ℹ Levels: Underweight -> Normal -> Overweight -> Obese | Scores: 0, 1, 2, 3
#> ℹ   Unadjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Unadjusted | bmi_catNormal: HR 0.82 (0.43-1.57), p = 0.552
#> ✔   Unadjusted | bmi_catOverweight: HR 0.87 (0.46-1.66), p = 0.671
#> ✔   Unadjusted | bmi_catObese: HR 0.72 (0.36-1.44), p = 0.354
#> ℹ   Unadjusted | trend: HR_per_score = 0.93 (0.76-1.13), p_trend = 0.455
#> ℹ   Age and sex adjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Age and sex adjusted | bmi_catNormal: HR 0.83 (0.43-1.59), p = 0.572
#> ✔   Age and sex adjusted | bmi_catOverweight: HR 0.88 (0.46-1.68), p = 0.699
#> ✔   Age and sex adjusted | bmi_catObese: HR 0.72 (0.36-1.45), p = 0.361
#> ℹ   Age and sex adjusted | trend: HR_per_score = 0.93 (0.76-1.13), p_trend = 0.458
#> ℹ   Fully adjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Fully adjusted | bmi_catNormal: HR 0.84 (0.44-1.61), p = 0.601
#> ✔   Fully adjusted | bmi_catOverweight: HR 0.88 (0.46-1.68), p = 0.698
#> ✔   Fully adjusted | bmi_catObese: HR 0.74 (0.37-1.48), p = 0.39
#> ℹ   Fully adjusted | trend: HR_per_score = 0.93 (0.76-1.13), p_trend = 0.474
#> ✔ Done: 12 result rows across 1 exposure and 3 models.

# Custom scores reflecting approximate median BMI per category
res <- assoc_trend(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "bmi_cat",
  method       = "coxph",
  covariates   = c("p21022", "p31", "tdi_cat", "p20116_i0"),
  scores       = c(17, 22, 27, 35)
)
#> ! Exposure bmi_cat is not an ordered factor -- levels will be scored 0, 1, 2, ... (equal spacing assumed).
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_trend ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models (categorical + trend model per combination)
#> 
#> ── bmi_cat ──
#> 
#> ℹ Levels: Underweight -> Normal -> Overweight -> Obese | Scores: 17, 22, 27, 35
#> ℹ   Unadjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Unadjusted | bmi_catNormal: HR 0.82 (0.43-1.57), p = 0.552
#> ✔   Unadjusted | bmi_catOverweight: HR 0.87 (0.46-1.66), p = 0.671
#> ✔   Unadjusted | bmi_catObese: HR 0.72 (0.36-1.44), p = 0.354
#> ℹ   Unadjusted | trend: HR_per_score = 0.99 (0.96-1.02), p_trend = 0.432
#> ℹ   Age and sex adjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Age and sex adjusted | bmi_catNormal: HR 0.83 (0.43-1.59), p = 0.572
#> ✔   Age and sex adjusted | bmi_catOverweight: HR 0.88 (0.46-1.68), p = 0.699
#> ✔   Age and sex adjusted | bmi_catObese: HR 0.72 (0.36-1.45), p = 0.361
#> ℹ   Age and sex adjusted | trend: HR_per_score = 0.99 (0.96-1.02), p_trend = 0.432
#> ℹ   Fully adjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Fully adjusted | bmi_catNormal: HR 0.84 (0.44-1.61), p = 0.601
#> ✔   Fully adjusted | bmi_catOverweight: HR 0.88 (0.46-1.68), p = 0.698
#> ✔   Fully adjusted | bmi_catObese: HR 0.74 (0.37-1.48), p = 0.39
#> ℹ   Fully adjusted | trend: HR_per_score = 0.99 (0.96-1.02), p_trend = 0.452
#> ✔ Done: 12 result rows across 1 exposure and 3 models.

# Logistic trend (no time_col needed)
res <- assoc_trend(
  data         = dt,
  outcome_col  = "dm_status",
  exposure_col = "bmi_cat",
  method       = "logistic"
)
#> ! Exposure bmi_cat is not an ordered factor -- levels will be scored 0, 1, 2, ... (equal spacing assumed).
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_trend ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models (categorical + trend model per combination)
#> 
#> ── bmi_cat ──
#> 
#> ℹ Levels: Underweight -> Normal -> Overweight -> Obese | Scores: 0, 1, 2, 3
#> ℹ   Unadjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Unadjusted | bmi_catNormal: OR 0.83 (0.42-1.63), p = 0.589
#> ✔   Unadjusted | bmi_catOverweight: OR 0.88 (0.45-1.71), p = 0.698
#> ✔   Unadjusted | bmi_catObese: OR 0.73 (0.36-1.49), p = 0.386
#> ℹ   Unadjusted | trend: OR_per_score = 0.93 (0.76-1.14), p_trend = 0.477
#> ℹ   Age and sex adjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Age and sex adjusted | bmi_catNormal: OR 0.84 (0.43-1.65), p = 0.612
#> ✔   Age and sex adjusted | bmi_catOverweight: OR 0.89 (0.46-1.74), p = 0.733
#> ✔   Age and sex adjusted | bmi_catObese: OR 0.73 (0.36-1.51), p = 0.4
#> ℹ   Age and sex adjusted | trend: OR_per_score = 0.93 (0.76-1.14), p_trend = 0.489
#> ✔ Done: 8 result rows across 1 exposure and 2 models.
```
