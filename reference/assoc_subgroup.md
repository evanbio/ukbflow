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
if (FALSE) { # \dontrun{
# Subgroup by sex, coxph, unadjusted only
res <- assoc_subgroup(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = c("exposure", "bmi_category"),
  by           = "sex",
  method       = "coxph"
)

# With Fully adjusted model (exclude 'sex' from covariates)
res <- assoc_subgroup(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = "exposure",
  by           = "sex",
  method       = "coxph",
  covariates   = c("age_at_recruitment", "tdi", "smoking")
)
} # }
```
