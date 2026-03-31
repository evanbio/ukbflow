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
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]   # incident analysis only

# Crude + age-sex adjusted (default)
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0"
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 Cox regressions
#> ℹ Input cohort: 1864 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: HR 1.10 (0.74-1.64), p = 0.622
#> ✔   Unadjusted | p20116_i0Current: HR 0.69 (0.37-1.28), p = 0.239
#> ✔   Age and sex adjusted | p20116_i0Previous: HR 1.09 (0.74-1.63), p = 0.655
#> ✔   Age and sex adjusted | p20116_i0Current: HR 0.68 (0.37-1.27), p = 0.231
#> ✔ Done: 4 result rows across 1 exposure and 2 models.

# Add Fully adjusted model
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0",
                   paste0("p22009_a", 1:4))
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models = 3 Cox regressions
#> ℹ Input cohort: 1864 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: HR 1.10 (0.74-1.64), p = 0.622
#> ✔   Unadjusted | p20116_i0Current: HR 0.69 (0.37-1.28), p = 0.239
#> ✔   Age and sex adjusted | p20116_i0Previous: HR 1.09 (0.74-1.63), p = 0.655
#> ✔   Age and sex adjusted | p20116_i0Current: HR 0.68 (0.37-1.27), p = 0.231
#> ✔   Fully adjusted | p20116_i0Previous: HR 1.09 (0.73-1.62), p = 0.688
#> ✔   Fully adjusted | p20116_i0Current: HR 0.69 (0.37-1.28), p = 0.239
#> ✔ Done: 6 result rows across 1 exposure and 3 models.

# Multiple exposures in one call
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = c("p20116_i0", "bmi_cat", "grs_bmi")
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 3 exposures x 2 models = 6 Cox regressions
#> ℹ Input cohort: 1864 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: HR 1.10 (0.74-1.64), p = 0.622
#> ✔   Unadjusted | p20116_i0Current: HR 0.69 (0.37-1.28), p = 0.239
#> ✔   Age and sex adjusted | p20116_i0Previous: HR 1.09 (0.74-1.63), p = 0.655
#> ✔   Age and sex adjusted | p20116_i0Current: HR 0.68 (0.37-1.27), p = 0.231
#> 
#> ── bmi_cat ──
#> 
#> ✔   Unadjusted | bmi_catNormal: HR 0.82 (0.43-1.57), p = 0.552
#> ✔   Unadjusted | bmi_catOverweight: HR 0.87 (0.46-1.66), p = 0.671
#> ✔   Unadjusted | bmi_catObese: HR 0.72 (0.36-1.44), p = 0.354
#> ✔   Age and sex adjusted | bmi_catNormal: HR 0.83 (0.43-1.59), p = 0.572
#> ✔   Age and sex adjusted | bmi_catOverweight: HR 0.88 (0.46-1.68), p = 0.699
#> ✔   Age and sex adjusted | bmi_catObese: HR 0.72 (0.36-1.45), p = 0.361
#> 
#> ── grs_bmi ──
#> 
#> ✔   Unadjusted | grs_bmi: HR 1.03 (0.96-1.11), p = 0.386
#> ✔   Age and sex adjusted | grs_bmi: HR 1.04 (0.96-1.11), p = 0.36
#> ✔ Done: 12 result rows across 3 exposures and 2 models.

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
#> ℹ Input cohort: 1864 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Fully adjusted | p20116_i0Previous: HR 1.09 (0.73-1.61), p = 0.685
#> ✔   Fully adjusted | p20116_i0Current: HR 0.68 (0.37-1.27), p = 0.228
#> ✔ Done: 2 result rows across 1 exposure and 1 model.
```
