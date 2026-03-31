# Subgroup association analysis with optional interaction test

Stratifies the dataset by a single grouping variable (`by`) and runs the
specified association model (`coxph`, `logistic`, or `linear`) within
each subgroup. Unlike
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
and its siblings, there is no automatic age-and-sex-adjusted model: at
the subgroup level the variable that defines the stratum would have zero
variance, making the auto-detected adjustment meaningless. Accordingly,
this function does not accept a `base` argument. Instead, two models are
available:

## Usage

``` r
assoc_subgroup(
  data,
  outcome_col,
  time_col = NULL,
  exposure_col,
  by,
  method = c("coxph", "logistic", "linear"),
  covariates = NULL,
  interaction = TRUE,
  conf_level = 0.95
)

assoc_sub(
  data,
  outcome_col,
  time_col = NULL,
  exposure_col,
  by,
  method = c("coxph", "logistic", "linear"),
  covariates = NULL,
  interaction = TRUE,
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

  (character) One or more exposure variable names.

- by:

  (character) Single stratification variable name. Its unique non-NA
  values (or factor levels, in order) define the subgroups. Should be a
  categorical or binary variable with a small number of levels (e.g.
  sex, smoking status). Continuous variables are technically permitted
  and the interaction LRT will still run, but per-unique-value
  subgrouping is rarely meaningful in practice — use a pre-categorised
  version (e.g. via
  [`derive_cut`](https://evanbio.github.io/ukbflow/reference/derive_cut.md))
  instead.

- method:

  (character) Regression method: `"coxph"` (default), `"logistic"`, or
  `"linear"`.

- covariates:

  (character or NULL) Covariate column names for the Fully adjusted
  model. When `NULL`, only the Unadjusted model is run.

- interaction:

  (logical) Compute the LRT p-value for the exposure \\\times\\ by
  interaction on the full dataset. Default: `TRUE`.

- conf_level:

  (numeric) Confidence level. Default: `0.95`.

## Value

A `data.table` with one row per subgroup level \\\times\\ exposure
\\\times\\ term \\\times\\ model, containing:

- `subgroup`:

  Name of the `by` variable.

- `subgroup_level`:

  Factor: level of the `by` variable (ordered by original level / sort
  order).

- `exposure`:

  Exposure variable name.

- `term`:

  Coefficient name from the fitted model.

- `model`:

  Ordered factor: `Unadjusted` \< `Fully adjusted`.

- `n`:

  Participants in model (after NA removal).

- ...:

  Effect estimate columns: `HR`/`OR`/`beta`, `CI_lower`, `CI_upper`,
  `p_value`, and a formatted label column. Cox models additionally
  include `n_events` and `person_years`; logistic models include
  `n_cases`; linear models include `se`.

- `p_interaction`:

  LRT p-value for the exposure \\\times\\ by interaction on the full
  dataset. Shared across all subgroup levels for the same exposure
  \\\times\\ model. `NA` when the interaction model fails. Only present
  when `interaction = TRUE`.

## Details

- **Unadjusted** - always run (no covariates).

- **Fully adjusted** - run when `covariates` is non-NULL. Users are
  responsible for excluding the `by` variable from `covariates` (a
  warning is issued if it is included).

**Interaction test**: when `interaction = TRUE` (default), a likelihood
ratio test (LRT) for the exposure \\\times\\ by interaction is computed
on the *full* dataset for each exposure \\\times\\ model combination and
appended as `p_interaction`. LRT is preferred over Wald because it
handles factor, binary, and continuous `by` variables uniformly without
requiring the user to recode the `by` variable.

## Examples

``` r
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

# Subgroup Cox by sex (interaction test included by default)
res <- assoc_subgroup(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  by           = "p31",
  method       = "coxph"
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_subgroup ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 1 model x 2 subgroups (p31)
#> ℹ Computing interaction LRT (exposure x p31) on full data ...
#> ℹ   Unadjusted | p20116_i0: p_interaction = 0.105
#> 
#> ── p31 = Female  (n = 1027) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: HR 1.48 (0.90-2.43), p = 0.125
#> ✔   Unadjusted | p20116_i0Current: HR 0.95 (0.45-2.00), p = 0.895
#> 
#> ── p31 = Male  (n = 837) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: HR 0.63 (0.31-1.27), p = 0.198
#> ✔   Unadjusted | p20116_i0Current: HR 0.38 (0.12-1.25), p = 0.111
#> ✔ Done: 4 result rows across 1 exposure, 1 model, 2 subgroups.

# Fully adjusted; exclude subgroup variable from covariates
res <- assoc_subgroup(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  by           = "p31",
  method       = "coxph",
  covariates   = c("p21022", "bmi_cat", "tdi_cat")
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_subgroup ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models x 2 subgroups (p31)
#> ℹ Computing interaction LRT (exposure x p31) on full data ...
#> ℹ   Unadjusted | p20116_i0: p_interaction = 0.105
#> ℹ   Fully adjusted | p20116_i0: p_interaction = 0.108
#> 
#> ── p31 = Female  (n = 1027) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: HR 1.48 (0.90-2.43), p = 0.125
#> ✔   Unadjusted | p20116_i0Current: HR 0.95 (0.45-2.00), p = 0.895
#> ✔   Fully adjusted | p20116_i0Previous: HR 1.45 (0.88-2.40), p = 0.143
#> ✔   Fully adjusted | p20116_i0Current: HR 0.93 (0.44-1.96), p = 0.854
#> 
#> ── p31 = Male  (n = 837) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: HR 0.63 (0.31-1.27), p = 0.198
#> ✔   Unadjusted | p20116_i0Current: HR 0.38 (0.12-1.25), p = 0.111
#> ✔   Fully adjusted | p20116_i0Previous: HR 0.64 (0.31-1.28), p = 0.206
#> ✔   Fully adjusted | p20116_i0Current: HR 0.36 (0.11-1.18), p = 0.0921
#> ✔ Done: 8 result rows across 1 exposure, 2 models, 2 subgroups.

# Subgroup logistic by BMI category
res <- assoc_subgroup(
  data         = dt,
  outcome_col  = "dm_status",
  exposure_col = "p20116_i0",
  by           = "bmi_cat",
  method       = "logistic"
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_subgroup ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 1 model x 4 subgroups (bmi_cat)
#> ℹ Computing interaction LRT (exposure x bmi_cat) on full data ...
#> ℹ   Unadjusted | p20116_i0: p_interaction = 0.943
#> 
#> ── bmi_cat = Underweight  (n = 166) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: OR 0.78 (0.22-2.81), p = 0.708
#> ✔   Unadjusted | p20116_i0Current: OR 0.50 (0.06-4.32), p = 0.532
#> 
#> ── bmi_cat = Normal  (n = 625) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: OR 1.46 (0.72-2.95), p = 0.297
#> ✔   Unadjusted | p20116_i0Current: OR 1.09 (0.39-3.06), p = 0.863
#> 
#> ── bmi_cat = Overweight  (n = 626) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: OR 0.97 (0.48-1.95), p = 0.925
#> ✔   Unadjusted | p20116_i0Current: OR 0.54 (0.18-1.61), p = 0.267
#> 
#> ── bmi_cat = Obese  (n = 447) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: OR 1.08 (0.44-2.64), p = 0.872
#> ✔   Unadjusted | p20116_i0Current: OR 0.53 (0.12-2.39), p = 0.408
#> ✔ Done: 8 result rows across 1 exposure, 1 model, 4 subgroups.
```
