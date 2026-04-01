# Cox regression lag sensitivity analysis

Runs Cox proportional hazards models at one or more lag periods to
assess whether associations are robust to the exclusion of early events.
For each lag, participants whose follow-up time is less than `lag_years`
are removed from the analysis dataset; follow-up time is kept on its
original scale (not shifted). This mirrors the approach used in UK
Biobank sensitivity analyses to address reverse causation and detection
bias.

## Usage

``` r
assoc_lag(
  data,
  outcome_col,
  time_col,
  exposure_col,
  lag_years = c(1, 2),
  covariates = NULL,
  base = TRUE,
  strata = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Event indicator column (0/1 or logical).

- time_col:

  (character) Follow-up time column (numeric, e.g. years).

- exposure_col:

  (character) One or more exposure variable names.

- lag_years:

  (numeric) One or more lag periods in the same units as `time_col`.
  Default: `c(1, 2)`. Use `0` to include the unfiltered full-cohort
  result as a reference.

- covariates:

  (character or NULL) Covariates for the Fully adjusted model. When
  `NULL`, only Unadjusted (and Age and sex adjusted if `base = TRUE`)
  are run.

- base:

  (logical) Auto-detect age and sex and include an Age and sex adjusted
  model. Default: `TRUE`.

- strata:

  (character or NULL) Optional stratification variable passed to
  [`survival::strata()`](https://rdrr.io/pkg/survival/man/strata.html).

- conf_level:

  (numeric) Confidence level for HR intervals. Default: `0.95`.

## Value

A `data.table` with one row per lag \\\times\\ exposure \\\times\\ term
\\\times\\ model combination, containing all columns produced by
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
plus:

- `lag_years`:

  The lag period applied (numeric).

- `n_excluded`:

  Number of participants excluded because their follow-up time was less
  than `lag_years`.

`lag_years` and `n_excluded` are placed immediately after `model` in the
column order.

## Details

Setting `lag_years = 0` (or including `0` in the vector) runs the model
on the full unfiltered cohort, providing a reference against which
lagged results can be compared.

The same three adjustment models produced by
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
are available here (**Unadjusted**, **Age and sex adjusted**, **Fully
adjusted**).

## Examples

``` r
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

res <- assoc_lag(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  lag_years    = c(0, 1, 2),
  covariates   = c("bmi_cat", "tdi_cat"),
  base         = FALSE
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_lag ───────────────────────────────────────────────────────────────────
#> ℹ 3 lag periods x 1 exposure x 1 model
#> 
#> ── Lag: 0 years ──
#> 
#> ℹ Excluded (time < 0 yr): 0 -- remaining: 463, events: 24
#> 
#> ── p20116_i0 ──
#> 
#> ── Lag: 1 year ──
#> 
#> ℹ Excluded (time < 1 yr): 3 -- remaining: 460, events: 21
#> 
#> ── p20116_i0 ──
#> 
#> ── Lag: 2 years ──
#> 
#> ℹ Excluded (time < 2 yr): 7 -- remaining: 456, events: 17
#> 
#> ── p20116_i0 ──
#> 
#> ✔ Done: 6 result rows across 3 lag periods, 1 exposure, and 1 model.
res[, .(lag_years, n, n_excluded, HR, CI_lower, CI_upper, p_value)]
#>    lag_years     n n_excluded        HR   CI_lower CI_upper   p_value
#>        <num> <int>      <int>     <num>      <num>    <num>     <num>
#> 1:         0   452          0 0.3927405 0.13251113 1.164016 0.0917984
#> 2:         0   452          0 0.4094191 0.09463282 1.771310 0.2321082
#> 3:         1   449          3 0.4610566 0.15228917 1.395853 0.1707241
#> 4:         1   449          3 0.4684395 0.10656446 2.059181 0.3154581
#> 5:         2   445          7 0.6225764 0.19727224 1.964804 0.4189975
#> 6:         2   445          7 0.6408615 0.14119296 2.908810 0.5642742
```
