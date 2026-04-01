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
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

res <- assoc_trend(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "bmi_cat",
  method       = "coxph",
  covariates   = c("tdi_cat", "p20116_i0"),
  base         = FALSE
)
#> ! Exposure bmi_cat is not an ordered factor -- levels will be scored 0, 1, 2, ... (equal spacing assumed).
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_trend ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 1 model (categorical + trend model per combination)
#> 
#> ── bmi_cat ──
#> 
#> ℹ Levels: Underweight -> Normal -> Overweight -> Obese | Scores: 0, 1, 2, 3
#> ℹ   Fully adjusted | bmi_catUnderweight: 1.00 (ref)
#> ✔   Fully adjusted | bmi_catNormal: HR 0.40 (0.10-1.64), p = 0.203
#> ✔   Fully adjusted | bmi_catOverweight: HR 0.40 (0.10-1.61), p = 0.196
#> ✔   Fully adjusted | bmi_catObese: HR 0.64 (0.17-2.43), p = 0.516
#> ℹ   Fully adjusted | trend: HR_per_score = 1.03 (0.66-1.60), p_trend = 0.893
#> ✔ Done: 4 result rows across 1 exposure and 1 model.
```
