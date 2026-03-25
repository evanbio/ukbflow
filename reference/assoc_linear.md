# Linear regression association analysis

Fits one or more linear regression models for each exposure variable and
returns a tidy result table. By default, two standard adjustment models
are always included:

## Usage

``` r
assoc_linear(
  data,
  outcome_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  conf_level = 0.95
)

assoc_lm(
  data,
  outcome_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Name of the continuous numeric outcome column.

- exposure_col:

  (character) One or more exposure variable names.

- covariates:

  (character or NULL) Covariate column names for the **Fully adjusted**
  model. Default: `NULL`.

- base:

  (logical) Include **Unadjusted** and **Age and sex adjusted** models.
  Default: `TRUE`.

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

- `beta`:

  Regression coefficient (\\\beta\\).

- `se`:

  Standard error of \\\beta\\.

- `CI_lower`:

  Lower confidence bound.

- `CI_upper`:

  Upper confidence bound.

- `p_value`:

  t-test p-value.

- `beta_label`:

  Formatted string, e.g. `"0.23 (0.05-0.41)"`.

## Details

- **Unadjusted** - no covariates (crude).

- **Age and sex adjusted** - age + sex auto-detected from the data via
  UKB field IDs (21022 and 31). Skipped with a warning if either column
  cannot be found.

- **Fully adjusted** - the covariates supplied via the `covariates`
  argument. Only run when `covariates` is non-NULL.

**Outcome**: intended for continuous numeric variables. Passing a binary
(0/1) or logical column is permitted (linear probability model) but will
trigger a warning recommending
[`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
instead.

**CI method**: based on the t-distribution via
[`confint.lm()`](https://rdrr.io/r/stats/confint.html), which is exact
under the normal linear model assumption. There is no `ci_method`
argument (unlike
[`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md))
as profile likelihood does not apply to `lm`.

**SE column**: the standard error of \\\beta\\ is included to support
downstream meta-analysis and GWAS-style summary statistics.

## Examples

``` r
if (FALSE) { # \dontrun{
# Minimal: crude + age-sex adjusted
res <- assoc_linear(
  data         = cohort,
  outcome_col  = "bmi",
  exposure_col = c("exposure", "smoking_pack_years")
)

# With Fully adjusted model
res <- assoc_linear(
  data         = cohort,
  outcome_col  = "bmi",
  exposure_col = "exposure",
  covariates   = c("tdi", "alcohol_freq", paste0("pc", 1:10))
)
} # }
```
