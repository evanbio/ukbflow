# Proportional hazards assumption test for Cox regression

Tests the proportional hazards (PH) assumption using Schoenfeld
residuals via
[`cox.zph`](https://rdrr.io/pkg/survival/man/cox.zph.html). Re-fits the
same models as
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
(same interface) and returns a tidy result table with term-level and
global test statistics.

## Usage

``` r
assoc_coxph_zph(
  data,
  outcome_col,
  time_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  strata = NULL
)

assoc_zph(
  data,
  outcome_col,
  time_col,
  exposure_col,
  covariates = NULL,
  base = TRUE,
  strata = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Binary event indicator (`0`/`1` or `TRUE`/`FALSE`).

- time_col:

  (character) Follow-up time column name.

- exposure_col:

  (character) One or more exposure variable names.

- covariates:

  (character or NULL) Covariates for the Fully adjusted model. Default:
  `NULL`.

- base:

  (logical) Include Unadjusted and Age and sex adjusted models. Default:
  `TRUE`.

- strata:

  (character or NULL) Optional stratification variable.

## Value

A `data.table` with one row per exposure \\\times\\ term \\\times\\
model combination, and columns:

- `exposure`:

  Exposure variable name.

- `term`:

  Coefficient name.

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `chisq`:

  Schoenfeld residual chi-squared statistic.

- `df`:

  Degrees of freedom.

- `p_value`:

  P-value for the PH test (term-level).

- `ph_satisfied`:

  Logical; `TRUE` if `p_value > 0.05`.

- `global_chisq`:

  Global chi-squared for the whole model.

- `global_df`:

  Global degrees of freedom.

- `global_p`:

  Global p-value for the whole model.

## Details

A non-significant p-value (p \> 0.05) indicates the PH assumption is
satisfied for that term. The global test (`global_p`) reflects the
overall PH assumption for the whole model.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check PH assumption for same models as assoc_coxph()
zph <- assoc_coxph_zph(
  data         = cohort,
  outcome_col  = "outcome_status",
  time_col     = "followup_years",
  exposure_col = c("exposure", "bmi_category"),
  covariates   = c("tdi", "smoking", paste0("pc", 1:10))
)

# Quick check: any violations?
zph[ph_satisfied == FALSE]
} # }
```
