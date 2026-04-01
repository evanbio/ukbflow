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
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

res <- assoc_subgroup(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  by           = "p31",
  method       = "coxph",
  covariates   = c("bmi_cat", "tdi_cat")
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_subgroup ──────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models x 2 subgroups (p31)
#> ℹ Computing interaction LRT (exposure x p31) on full data ...
#> ℹ   Unadjusted | p20116_i0: p_interaction = 0.852
#> ℹ   Fully adjusted | p20116_i0: p_interaction = 0.864
#> 
#> ── p31 = Female  (n = 263) ──
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: HR 0.32 (0.07-1.42), p = 0.135
#> ✔   Unadjusted | p20116_i0Current: HR 0.35 (0.05-2.70), p = 0.316
#> ✔   Fully adjusted | p20116_i0Previous: HR 0.35 (0.08-1.56), p = 0.169
#> ✔   Fully adjusted | p20116_i0Current: HR 0.39 (0.05-3.00), p = 0.364
#> 
#> ── p31 = Male  (n = 200) ──
#> 
#> !   p31 = Male: only 8 events -- results may be unstable.
#> 
#> ── p20116_i0 
#> ✔   Unadjusted | p20116_i0Previous: HR 0.57 (0.11-2.93), p = 0.498
#> ✔   Unadjusted | p20116_i0Current: HR 0.57 (0.07-4.87), p = 0.606
#> Warning: Loglik converged before variable  4,6 ; coefficient may be infinite. 
#> ✔   Fully adjusted | p20116_i0Previous: HR 0.54 (0.10-2.90), p = 0.469
#> ✔   Fully adjusted | p20116_i0Current: HR 0.39 (0.04-4.25), p = 0.439
#> ✔ Done: 8 result rows across 1 exposure, 2 models, 2 subgroups.
```
