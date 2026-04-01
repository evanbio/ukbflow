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
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat"),
  base         = FALSE
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 1 model = 1 Cox regression
#> ℹ Input cohort: 463 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Fully adjusted | p20116_i0Previous: HR 0.39 (0.13-1.16), p = 0.0918
#> ✔   Fully adjusted | p20116_i0Current: HR 0.41 (0.09-1.77), p = 0.232
#> ✔ Done: 2 result rows across 1 exposure and 1 model.

# Fully adjusted only (skip Unadjusted + Age-sex)
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("p21022", "p31", "bmi_cat", "tdi_cat"),
  base         = FALSE
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 1 model = 1 Cox regression
#> ℹ Input cohort: 463 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Fully adjusted | p20116_i0Previous: HR 0.41 (0.14-1.21), p = 0.105
#> ✔   Fully adjusted | p20116_i0Current: HR 0.42 (0.10-1.84), p = 0.253
#> ✔ Done: 2 result rows across 1 exposure and 1 model.
```
