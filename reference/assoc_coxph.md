# Cox proportional hazards association analysis

Fits one or more Cox models for each exposure variable and returns a
tidy result table suitable for downstream forest plots. By default, two
standard adjustment models are always included alongside any
user-specified model:

## Usage

``` r
assoc_coxph(
  data,
  outcome_col,
  time_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  strata = NULL,
  conf_level = 0.95
)

assoc_cox(
  data,
  outcome_col,
  time_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  strata = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset. Must contain all columns
  referenced by `outcome_col`, `time_col`, and `exposure_col`.

- outcome_col:

  (character) Name of the event indicator column. Accepts `logical`
  (`TRUE`/`FALSE`) or numeric/integer (`0`/`1`).

- time_col:

  (character) Name of the follow-up time column (numeric, in consistent
  units, e.g. years).

- exposure_col:

  (character) One or more exposure variable names. Each variable is
  analysed separately; results are stacked row-wise.

- covariates:

  (character or NULL) Additional covariate column names for the **Fully
  adjusted** model (e.g. `c("tdi", "smoking", paste0("pc", 1:10))`).
  When `NULL` (default), the Fully adjusted model is not run.

- base:

  (logical) If `TRUE` (default), always include the **Unadjusted** and
  **Age and sex adjusted** models in addition to any user-specified
  `covariates` model. Set to `FALSE` to run only the Fully adjusted
  model (requires `covariates` to be non-NULL).

- strata:

  (character or NULL) Optional stratification variable. Passed to
  [`survival::strata()`](https://rdrr.io/pkg/survival/man/strata.html)
  in the Cox formula.

- conf_level:

  (numeric) Confidence level for hazard ratio intervals. Default:
  `0.95`.

## Value

A `data.table` with one row per exposure \\\times\\ term \\\times\\
model combination, and the following columns:

- `exposure`:

  Exposure variable name.

- `term`:

  Coefficient name as returned by `coxph` (e.g. `"bmi_categoryObese"`
  for a factor, or the variable name itself for numeric/binary
  exposures).

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `n`:

  Number of participants included in the model (after `NA` removal).

- `n_events`:

  Number of events in the model's analysis set (after `NA` removal).

- `person_years`:

  Total person-years of follow-up in the model's analysis set (rounded,
  after `NA` removal).

- `HR`:

  Hazard ratio (point estimate).

- `CI_lower`:

  Lower bound of the confidence interval.

- `CI_upper`:

  Upper bound of the confidence interval.

- `p_value`:

  Wald test p-value.

- `HR_label`:

  Formatted string, e.g. `"1.23 (1.05-1.44)"`.

## Details

- **Unadjusted** - no covariates (crude).

- **Age and sex adjusted** - age + sex auto-detected from the data via
  UKB field IDs (21022 and 31). Skipped with a warning if either column
  cannot be found.

- **Fully adjusted** - the covariates supplied via the `covariates`
  argument. Only run when `covariates` is non-NULL.

**Outcome coding**: `outcome_col` may be `logical` (`TRUE`/`FALSE`) or
integer/numeric (`0`/`1`). Logical values are converted to integer
internally.

**Exposure types supported**:

- *Binary* - `0`/`1` or `TRUE`/`FALSE`; produces one `term` row per
  model.

- *Factor* - produces one `term` row per non-reference level.

- *Numeric* (continuous) - produces one `term` row per model.

## Examples

``` r
if (FALSE) { # \dontrun{
# Minimal: crude + age-sex adjusted only
res <- assoc_coxph(
  data         = cohort,
  outcome_col  = "outcome_status",   # 0/1 or TRUE/FALSE
  time_col     = "followup_years",
  exposure_col = c("exposure", "bmi_category")
)

# Add a Fully adjusted model (Model 3)
res <- assoc_coxph(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = "exposure",
  covariates   = c("tdi", "smoking", "alcohol_freq",
                   paste0("pc", 1:10))
)

# Only run the Fully adjusted model (skip Unadjusted + Age-sex)
res <- assoc_coxph(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = "exposure",
  covariates   = c("age_at_recruitment", "sex", "tdi"),
  base         = FALSE
)
} # }
```
