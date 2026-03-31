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
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]

# Lag sensitivity analysis: 0 = full cohort reference, then 1 and 2 year lags
res <- assoc_lag(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  lag_years    = c(0, 1, 2),
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0",
                   paste0("p22009_a", 1:4))
)
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_lag ───────────────────────────────────────────────────────────────────
#> ℹ 3 lag periods x 1 exposure x 3 models
#> 
#> ── Lag: 0 years ──
#> 
#> ℹ Excluded (time < 0 yr): 0 -- remaining: 1864, events: 114
#> 
#> ── p20116_i0 ──
#> 
#> ── Lag: 1 year ──
#> 
#> ℹ Excluded (time < 1 yr): 7 -- remaining: 1857, events: 107
#> 
#> ── p20116_i0 ──
#> 
#> ── Lag: 2 years ──
#> 
#> ℹ Excluded (time < 2 yr): 13 -- remaining: 1851, events: 101
#> 
#> ── p20116_i0 ──
#> 
#> ✔ Done: 18 result rows across 3 lag periods, 1 exposure, and 3 models.

# Check how many participants were excluded at each lag
res[, .(lag_years, n, n_excluded, HR, CI_lower, CI_upper, p_value)]
#>     lag_years     n n_excluded        HR  CI_lower CI_upper   p_value
#>         <num> <int>      <int>     <num>     <num>    <num>     <num>
#>  1:         0  1798          0 1.1045476 0.7435625 1.640784 0.6223846
#>  2:         0  1798          0 0.6889420 0.3703591 1.281570 0.2393668
#>  3:         0  1798          0 1.0946264 0.7366790 1.626498 0.6545337
#>  4:         0  1798          0 0.6842045 0.3677853 1.272851 0.2308320
#>  5:         0  1743          0 1.0852617 0.7280619 1.617710 0.6878831
#>  6:         0  1743          0 0.6868077 0.3677241 1.282768 0.2385167
#>  7:         1  1791          7 1.0339525 0.6858267 1.558787 0.8733457
#>  8:         1  1791          7 0.6531091 0.3424993 1.245408 0.1958140
#>  9:         1  1791          7 1.0251203 0.6797799 1.545900 0.9057732
#> 10:         1  1791          7 0.6486161 0.3401191 1.236928 0.1887159
#> 11:         1  1736          7 1.0128114 0.6694224 1.532346 0.9519515
#> 12:         1  1736          7 0.6481449 0.3385146 1.240986 0.1907098
#> 13:         2  1785         13 0.9864448 0.6456515 1.507119 0.9496782
#> 14:         2  1785         13 0.6147141 0.3133601 1.205876 0.1569461
#> 15:         2  1785         13 0.9779534 0.6399179 1.494556 0.9179455
#> 16:         2  1785         13 0.6102537 0.3110646 1.197210 0.1508738
#> 17:         2  1730         13 0.9615926 0.6270081 1.474718 0.8575434
#> 18:         2  1730         13 0.6085264 0.3088433 1.199004 0.1511539
```
