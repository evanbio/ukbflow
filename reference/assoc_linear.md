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
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42

# Crude + age-sex adjusted (default); outcome is continuous BMI
res <- assoc_linear(
  data         = dt,
  outcome_col  = "p21001_i0",
  exposure_col = "p20116_i0"
)
#> 
#> ── assoc_linear ────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 linear regressions
#> ℹ Input cohort: 2000 participants (n reflects each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: beta -0.45 (-1.00-0.10), p = 0.109
#> ✔   Unadjusted | p20116_i0Current: beta 0.08 (-0.64-0.80), p = 0.834
#> ✔   Age and sex adjusted | p20116_i0Previous: beta -0.44 (-1.00-0.11), p = 0.114
#> ✔   Age and sex adjusted | p20116_i0Current: beta 0.08 (-0.64-0.80), p = 0.826
#> ✔ Done: 4 result rows across 1 exposure and 2 models.

# Add Fully adjusted model
res <- assoc_linear(
  data         = dt,
  outcome_col  = "p21001_i0",
  exposure_col = "p20116_i0",
  covariates   = c("tdi_cat", "p1558_i0", paste0("p22009_a", 1:4))
)
#> 
#> ── assoc_linear ────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models = 3 linear regressions
#> ℹ Input cohort: 2000 participants (n reflects each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: beta -0.45 (-1.00-0.10), p = 0.109
#> ✔   Unadjusted | p20116_i0Current: beta 0.08 (-0.64-0.80), p = 0.834
#> ✔   Age and sex adjusted | p20116_i0Previous: beta -0.44 (-1.00-0.11), p = 0.114
#> ✔   Age and sex adjusted | p20116_i0Current: beta 0.08 (-0.64-0.80), p = 0.826
#> ✔   Fully adjusted | p20116_i0Previous: beta -0.42 (-0.97-0.14), p = 0.145
#> ✔   Fully adjusted | p20116_i0Current: beta 0.10 (-0.64-0.84), p = 0.788
#> ✔ Done: 6 result rows across 1 exposure and 3 models.

# Continuous exposure (GRS → BMI); Fully adjusted only
res <- assoc_linear(
  data         = dt,
  outcome_col  = "p21001_i0",
  exposure_col = "grs_bmi",
  covariates   = c("p21022", "p31", "tdi_cat"),
  base         = FALSE
)
#> 
#> ── assoc_linear ────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 1 model = 1 linear regression
#> ℹ Input cohort: 2000 participants (n reflects each model's actual analysis set)
#> 
#> ── grs_bmi ──
#> 
#> ✔   Fully adjusted | grs_bmi: beta 0.03 (-0.07-0.13), p = 0.552
#> ✔ Done: 1 result row across 1 exposure and 1 model.
```
