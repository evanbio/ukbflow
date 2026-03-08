# Logistic regression association analysis

Fits one or more logistic regression models for each exposure variable
and returns a tidy result table suitable for downstream forest plots. By
default, two standard adjustment models are always included:

## Usage

``` r
assoc_logistic(
  data,
  outcome_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  ci_method = c("wald", "profile"),
  conf_level = 0.95
)

assoc_logit(
  data,
  outcome_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  ci_method = c("wald", "profile"),
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Binary outcome column (`0`/`1` or `TRUE`/`FALSE`).

- exposure_col:

  (character) One or more exposure variable names.

- covariates:

  (character or NULL) Covariate column names for the **Fully adjusted**
  model. Default: `NULL`.

- base:

  (logical) Include **Unadjusted** and **Age and sex adjusted** models.
  Default: `TRUE`.

- ci_method:

  (character) CI calculation method: `"wald"` (default) or `"profile"`.

- conf_level:

  (numeric) Confidence level. Default: `0.95`.

## Value

A `data.table` with one row per exposure \\\times\\ term \\\times\\
model combination, and columns:

- `exposure`:

  Exposure variable name.

- `term`:

  Coefficient name (e.g. `"bmi_categoryObese"`).

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `n`:

  Participants in model (after NA removal).

- `n_cases`:

  Number of cases (outcome = 1) in model.

- `OR`:

  Odds ratio (point estimate).

- `CI_lower`:

  Lower confidence bound.

- `CI_upper`:

  Upper confidence bound.

- `p_value`:

  Wald test p-value.

- `OR_label`:

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

**CI methods**:

- `"wald"` (default) - fast, appropriate for large UKB samples.

- `"profile"` - profile likelihood CI via `confint.glm()`; slower but
  more accurate for small or sparse data.

## Examples

``` r
if (FALSE) { # \dontrun{
# Minimal: crude + age-sex adjusted
res <- assoc_logistic(
  data         = cohort,
  outcome_col  = "outcome_status",
  exposure_col = c("exposure", "bmi_category")
)

# With Fully adjusted model + profile likelihood CI
res <- assoc_logistic(
  data         = cohort,
  outcome_col  = "outcome_status",
  exposure_col = "exposure",
  covariates   = c("tdi", "smoking", paste0("pc", 1:10)),
  ci_method    = "profile"
)
} # }
```
