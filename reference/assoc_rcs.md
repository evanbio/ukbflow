# Restricted cubic spline dose-response analysis

Models the (possibly non-linear) dose-response relationship between a
single **continuous** exposure and an outcome using restricted cubic
splines (RCS), and returns a prediction *curve* - one row per grid
point - rather than a single effect estimate. Whereas
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
and friends assume a linear (log-)effect and
[`assoc_trend`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
handles *ordered categorical* exposures, `assoc_rcs` lets the effect
bend, capturing U-shaped, J-shaped, threshold, or plateau relationships
and reporting a test for non-linearity.

## Usage

``` r
assoc_rcs(
  data,
  outcome_col,
  time_col = NULL,
  exposure_col,
  method = c("coxph", "logistic", "linear"),
  covariates = NULL,
  base = TRUE,
  knots = 4,
  ref = NULL,
  test = c("lrt", "wald"),
  conf_level = 0.95,
  np = 100
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Outcome column name. Event indicator (`0`/`1` or
  `TRUE`/`FALSE`) for `coxph`/ `logistic`; continuous for `linear`.

- time_col:

  (character or NULL) Follow-up time column. Required when
  `method = "coxph"`.

- exposure_col:

  (character) A single **continuous** exposure column name. Factor or
  logical exposures are rejected - use
  [`assoc_trend`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
  or
  [`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  for those.

- method:

  (character) Regression method: `"coxph"` (default), `"logistic"`, or
  `"linear"`.

- covariates:

  (character or NULL) Covariates for the Fully adjusted model. Default:
  `NULL`.

- base:

  (logical) Include Unadjusted and Age-and-sex-adjusted models. Default:
  `TRUE`.

- knots:

  (numeric) Number of spline knots (a single integer, typically `3`,
  `4`, or `5`) placed at Harrell's recommended quantiles, or an explicit
  vector of knot positions. Default: `4`.

- ref:

  (numeric or NULL) Reference exposure value the curve is centred on
  (where the effect equals 1 on the HR/OR scale, or 0 for `linear`).
  `NULL` (default) uses the exposure median.

- test:

  (character) P-value method: `"lrt"` (likelihood ratio, default) or
  `"wald"`.

- conf_level:

  (numeric) Confidence level for the CI band. Default: `0.95`.

- np:

  (integer) Number of points along the prediction curve. Affects curve
  resolution only, not the fitted model or p-values. Default: `100`.

## Value

A `data.table` with one row per model \\\times\\ grid point:

- `exposure`:

  Exposure variable name.

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `x`:

  Exposure value at the grid point.

- `estimate`:

  Effect at `x` relative to `ref` - a hazard ratio (`coxph`), odds ratio
  (`logistic`), or mean difference (`linear`). The measure is recorded
  in the `"measure"` attribute.

- `conf_low`, `conf_high`:

  Confidence band bounds.

- `p_overall`:

  Overall association p-value (repeated within each model).

- `p_nonlinear`:

  Non-linearity p-value (repeated within each model).

- `n`:

  Participants in the model (after NA removal). `coxph` additionally
  includes `n_events`.

The table carries hidden attributes recording `measure`
(`"HR"`/`"OR"`/`"Mean difference"`), `knots` (the knot positions
actually used), `ref`, and a `ukbflow_call` entry that
[`audit_model`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
reads automatically.

## Details

Two standard adjustment models are included by default, matching the
rest of the `assoc_*` family:

- **Unadjusted** - spline term only (crude).

- **Age and sex adjusted** - age + sex auto-detected from standard UKB
  names (`p21022`/`p31`) or decoded names (`age_at_recruitment`/`sex`).

- **Fully adjusted** - the covariates supplied via `covariates`. Only
  run when `covariates` is non-NULL.

Each model produces its own curve, so adjusted and unadjusted
dose-response relationships can be overlaid on a single panel by
[`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md).

**Implementation**: the exposure enters the model as
`rms::rcs(exposure, knots)` and is fitted with
[`rms::cph()`](https://rdrr.io/pkg/rms/man/cph.html),
[`rms::lrm()`](https://rdrr.io/pkg/rms/man/lrm.html), or
[`rms::ols()`](https://rdrr.io/pkg/rms/man/ols.html) depending on
`method`. Predictions relative to a reference value come from
[`rms::Predict()`](https://rdrr.io/pkg/rms/man/Predict.html), and the
overall-association and non-linearity p-values from
[`anova()`](https://rdrr.io/r/stats/anova.html) - the canonical Harrell
RCS workflow, so results match mainstream epidemiological practice. The
rms package is a `Suggests` dependency; it must be installed to use this
function.

## See also

[`assoc_trend`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
for categorical dose-response,
[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
for the linear-effect models.

## Examples

``` r
if (requireNamespace("rms", quietly = TRUE)) {
  dt <- ops_toy(scenario = "association", n = 500)
  dt <- dt[dm_timing != 1L]

  res <- assoc_rcs(
    data         = dt,
    outcome_col  = "dm_status",
    time_col     = "dm_followup_years",
    exposure_col = "p21001_i0",              # BMI
    method       = "coxph",
    covariates   = c("p22189", "p20116_i0"), # TDI, smoking status
    knots        = 4
  )
}
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_rcs ───────────────────────────────────────────────────────────────────
#> ℹ Exposure p21001_i0 | coxph | 4 knots | 3 models | test: lrt
#> ✔   Unadjusted: p_overall = 0.56, p_nonlinear = 0.359
#> ✔   Age and sex adjusted: p_overall = 0.597, p_nonlinear = 0.392
#> ✔   Fully adjusted: p_overall = 0.607, p_nonlinear = 0.412
#> ✔ Done: 3 dose-response curves (300 grid points).
```
