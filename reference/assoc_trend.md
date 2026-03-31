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
if (FALSE) { # \dontrun{
# Create an ordered factor exposure with 3 levels
cohort[, exposure_cat := factor(exposure_source,
                                 levels = c(0, 1, 2),
                                 labels = c("None", "Mild", "Severe"))]

# Trend analysis: default scores 0, 1, 2
res <- assoc_trend(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = "exposure_cat",
  method       = "coxph",
  covariates   = c("age_at_recruitment", "sex", "tdi", "smoking")
)

# Custom scores (e.g. median value per category)
res <- assoc_trend(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = "exposure_cat",
  method       = "coxph",
  covariates   = c("age_at_recruitment", "sex", "tdi"),
  scores       = c(0, 5, 14)
)
} # }
```
