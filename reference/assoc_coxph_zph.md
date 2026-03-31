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
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

# Test PH assumption for the same model as assoc_coxph()
zph <- assoc_coxph_zph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0",
                   paste0("p22009_a", 1:4))
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph_zph ─────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 3 models = 3 PH assumption tests
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0: chisq = 0.423, p = 0.81 [OK] satisfied
#> ℹ   Global: chisq = 0.423, p = 0.81
#> ✔   Age and sex adjusted | p20116_i0: chisq = 0.4, p = 0.819 [OK] satisfied
#> ℹ   Global: chisq = 2.042, p = 0.728
#> ✔   Fully adjusted | p20116_i0: chisq = 0.482, p = 0.786 [OK] satisfied
#> ℹ   Global: chisq = 14.12, p = 0.659
#> ✔ Done: all 3 terms satisfy the PH assumption.

# Flag any term-level violations
zph[ph_satisfied == FALSE]
#> Empty data.table (0 rows and 10 cols): exposure,term,model,chisq,df,p_value...
```
