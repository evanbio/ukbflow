# Association Analysis for UKB Outcomes

## Overview

The `assoc_*` functions fit regression models for each exposure variable
and return tidy result tables suitable for downstream forest plots and
publication tables.

| Function | Alias | Model | Effect measure |
|----|----|----|----|
| [`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md) | [`assoc_cox()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md) | Cox proportional hazards | HR |
| [`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md) | [`assoc_logit()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md) | Logistic regression | OR |
| [`assoc_linear()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md) | [`assoc_lm()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md) | Linear regression | beta |
| [`assoc_coxph_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md) | [`assoc_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md) | Schoenfeld residual PH test | chisq / p |
| [`assoc_subgroup()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md) | [`assoc_sub()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md) | Stratified analysis + LRT interaction | HR / OR / beta |
| [`assoc_trend()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md) | [`assoc_tr()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md) | Dose-response trend | HR / OR / beta + p_trend |
| [`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md) | — | Restricted cubic spline dose-response | HR / OR / beta + p-nonlinear |
| [`assoc_competing()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md) | [`assoc_fg()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md) | Fine-Gray competing risks | SHR |
| [`assoc_lag()`](https://evanbio.github.io/ukbflow/reference/assoc_lag.md) | — | Cox lag sensitivity analysis | HR |
| [`assoc_evalue()`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md) | — | E-value for unmeasured confounding | E-value |

> **Prerequisite**: the analysis dataset should already contain derived
> case status, follow-up time, and covariates produced by the `derive_*`
> functions. See
> [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
> and
> [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md).

``` r

library(ukbflow)

# ops_toy(scenario = "association") returns a pre-derived analysis-ready table:
# covariates already as factors, bmi_cat / tdi_cat binned, and two outcomes
# (dm_* and htn_*) with status / date / timing / followup columns in place.
dt <- ops_toy(scenario = "association")
dt <- dt[dm_timing != 1L]   # incident analysis: exclude prevalent DM cases
```

------------------------------------------------------------------------

## The Three-Model Framework

All main functions automatically produce up to three adjustment levels
without requiring manual formula construction:

| Model | Covariates | When included |
|----|----|----|
| **Unadjusted** | None (crude) | Always (when `base = TRUE`) |
| **Age and sex adjusted** | Age (field 21022) + sex (field 31), auto-detected | When one age column and one sex column are found |
| **Fully adjusted** | User-supplied `covariates` | When `covariates` is non-NULL |

Age and sex columns are located automatically from a small set of
standard UKB and ukbflow names: `age_at_recruitment`, `p21022`, `21022`,
or `participant.p21022` for age, and `sex`, `p31`, `31`, or
`participant.p31` for sex. If these columns were manually renamed, set
`base = FALSE` and pass the intended age and sex columns through
`covariates`. Set `base = FALSE` to skip the first two models and run
only the Fully adjusted model.

------------------------------------------------------------------------

## Step 1: Cox Proportional Hazards

[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
is the primary function for time-to-event outcomes. It accepts logical
(`TRUE`/`FALSE`) or integer (`0`/`1`) event indicators and returns one
row per exposure x term x model combination.

``` r

# Crude + age-sex adjusted (automatic); p21022 and p31 auto-detected
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = c("p20116_i0", "bmi_cat")
)
```

``` r

# Add a Fully adjusted model
res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0",
                   paste0("p22009_a", 1:10))
)
```

Output columns:

| Column | Description |
|----|----|
| `exposure` | Exposure variable name |
| `term` | Coefficient name from `coxph` |
| `model` | Ordered factor: Unadjusted \< Age and sex adjusted \< Fully adjusted |
| `n` | Participants in model (after NA removal) |
| `n_events` | Events in model |
| `person_years` | Total person-years (rounded) |
| `HR` | Hazard ratio |
| `CI_lower`, `CI_upper` | Confidence interval bounds |
| `p_value` | P-value from the selected test method |
| `HR_label` | Formatted string, e.g. `"1.43 (1.28-1.60)"` |

> `n`, `n_events`, and `person_years` all reflect the model-specific
> complete-case analysis set — participants with any missing value
> across outcome, time, exposure, or covariates are dropped before
> fitting. These counts therefore differ between models (e.g. Fully
> adjusted typically has fewer participants than Unadjusted).

By default,
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
uses `test = "wald"` for term-level Wald p-values. Set `test = "lrt"` to
return an exposure-level likelihood-ratio p-value from single-term
deletion. When `cluster_col` is supplied for cluster-robust Cox
variance, only `test = "wald"` is supported.

------------------------------------------------------------------------

## Step 2: Logistic Regression

[`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
is for binary outcomes without a time dimension (e.g. case-control or
cross-sectional designs).

``` r

res <- assoc_logistic(
  data         = dt,
  outcome_col  = "dm_status",
  exposure_col = c("p20116_i0", "bmi_cat"),
  covariates   = c("tdi_cat", "p1558_i0", paste0("p22009_a", 1:10))
)
```

For sparse data or small samples, use profile likelihood confidence
intervals:

``` r

res <- assoc_logistic(
  data         = dt,
  outcome_col  = "dm_status",
  exposure_col = "grs_bmi",
  ci_method    = "profile"   # slower but more accurate for sparse data
)
```

Output is identical in structure to
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
but with `OR` and `OR_label` in place of `HR` / `HR_label`, and
`n_cases` instead of `n_events` / `person_years`.

------------------------------------------------------------------------

## Step 3: Linear Regression

[`assoc_linear()`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
is for continuous outcomes (e.g. biomarker levels, BMI). The standard
error of beta is included to support downstream meta-analysis.

``` r

# Continuous outcome (BMI); smoking and GRS as exposures
res <- assoc_linear(
  data         = dt,
  outcome_col  = "p21001_i0",
  exposure_col = c("p20116_i0", "grs_bmi"),
  covariates   = c("tdi_cat", "p1558_i0", paste0("p22009_a", 1:10))
)
```

> **Common mistake**: passing a binary (0/1) or logical column as
> `outcome_col` is permitted (linear probability model) but triggers a
> warning. Use
> [`assoc_logistic()`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
> for binary outcomes — linear regression on a 0/1 outcome produces
> unbounded predictions and is rarely appropriate in epidemiological
> analyses.

------------------------------------------------------------------------

## Step 4: Proportional Hazards Assumption Test

[`assoc_coxph_zph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md)
re-fits the same Cox models and tests the PH assumption via Schoenfeld
residuals (`cox.zph()`). Use it alongside
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
to validate model assumptions.

``` r

zph <- assoc_coxph_zph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = c("p20116_i0", "bmi_cat"),
  covariates   = c("tdi_cat", "p1558_i0")
)

# Identify any violations
zph[ph_satisfied == FALSE]
```

Output columns include `chisq`, `df`, `p_value`, `ph_satisfied`
(logical), and global test statistics (`global_chisq`, `global_df`,
`global_p`).

When the PH assumption is violated, consider adding `strata()` to
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
or modelling time-varying effects.

------------------------------------------------------------------------

## Step 5: Subgroup Analysis

[`assoc_subgroup()`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md)
stratifies the dataset by a grouping variable and fits the specified
model within each subgroup. A likelihood ratio test (LRT) for the
exposure x subgroup interaction is computed on the full dataset and
appended as `p_interaction`.

``` r

# Subgroup by sex; p31 is automatically excluded from within-stratum models
res <- assoc_subgroup(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  by           = "p31",
  method       = "coxph",
  covariates   = c("p21022", "bmi_cat", "tdi_cat")
)
```

Output columns include `subgroup`, `subgroup_level`, and `p_interaction`
in addition to the standard effect estimate columns.

> **Note**: the `by` variable is automatically excluded from the
> subgroup models. Do not include it in `covariates` — a collinearity
> warning is issued if you do. Subgroup analysis is most interpretable
> when `by` has a small number of levels (e.g. sex, smoking status);
> continuous variables are technically permitted but per-unique-value
> subgrouping is rarely meaningful in practice — use a pre-categorised
> version (e.g. via
> [`derive_cut()`](https://evanbio.github.io/ukbflow/reference/derive_cut.md))
> instead.

------------------------------------------------------------------------

## Step 6: Dose-Response Trend Analysis

[`assoc_trend()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
fits categorical and trend models simultaneously for each ordered-factor
exposure, returning per-category estimates alongside a p-value for
linear trend.

``` r

# assoc_trend() requires an ordered factor; make bmi_cat ordered in-place
dt[, bmi_cat := factor(bmi_cat, levels = levels(bmi_cat), ordered = TRUE)]
```

``` r

res <- assoc_trend(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "bmi_cat",
  method       = "coxph",
  covariates   = c("p21022", "p31", "tdi_cat", "p20116_i0")
)
```

Supply custom scores reflecting approximate median BMI per category:

``` r

res <- assoc_trend(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "bmi_cat",
  method       = "coxph",
  covariates   = c("p21022", "p31", "tdi_cat", "p20116_i0"),
  scores       = c(17, 22, 27, 35)   # approximate median BMI per category
)
```

The output contains a reference row (`HR = 1.00 (ref)`) followed by
non-reference rows, with `HR_per_score`, `HR_per_score_label`, and
`p_trend` appended as shared columns. These trend columns carry the same
value across every row within the same exposure × model combination —
including the reference row — so the full result table remains
self-contained and easy to filter or export.

------------------------------------------------------------------------

## Step 7: Non-Linear Dose-Response (Restricted Cubic Splines)

Where
[`assoc_trend()`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md)
summarises an *ordered categorical* exposure with a single linear-trend
estimate,
[`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md)
models the full — possibly non-linear — shape of a **continuous**
exposure using restricted cubic splines. It returns a prediction *curve*
(one row per grid point) together with an overall-association p-value
and a **p-value for non-linearity**, capturing U-shaped, J-shaped,
threshold, or plateau relationships that a single linear term would
miss.

It supports the same three methods (`"coxph"`, `"logistic"`, `"linear"`)
and the same base / covariates adjustment logic as the rest of the
`assoc_*` family. The exposure must be **continuous**; the reference
value (`ref`, default the median) is where the effect equals 1 (HR / OR)
or 0 (mean difference).

``` r

res <- assoc_rcs(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p21001_i0",              # BMI (continuous)
  method       = "coxph",
  covariates   = c("p21022", "p31", "tdi_cat", "p20116_i0"),
  knots        = 4,                        # Harrell quantile knots (3-5 typical)
  ref          = 25                        # centre the curve at BMI 25 (HR = 1)
)
```

The result holds the fitted curve (`x`, `estimate`, `conf_low`,
`conf_high`), the `p_overall` and `p_nonlinear` values (repeated within
each model), plus hidden `measure` / `knots` / `ref` attributes. When
`base = TRUE` (default), one curve is returned per adjustment model.
Pass the result straight to
[`plot_rcs()`](https://evanbio.github.io/ukbflow/reference/plot_rcs.md)
to draw the dose-response curve — see
[`vignette("plot")`](https://evanbio.github.io/ukbflow/articles/plot.md).

> **Requires the `rms` package** (a `Suggests` dependency):
> [`assoc_rcs()`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md)
> fits the spline through
> [`rms::cph()`](https://rdrr.io/pkg/rms/man/cph.html) /
> [`rms::lrm()`](https://rdrr.io/pkg/rms/man/lrm.html) /
> [`rms::ols()`](https://rdrr.io/pkg/rms/man/ols.html), so the
> non-linearity test follows the canonical Harrell RCS workflow. Install
> it with `install.packages("rms")`.

------------------------------------------------------------------------

## Step 8: Fine-Gray Competing Risks

[`assoc_competing()`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md)
fits a Fine-Gray subdistribution hazard model via
[`survival::finegray()`](https://rdrr.io/pkg/survival/man/finegray.html) +
inverse-probability-of-censoring-weighted Cox regression. Use this when
a competing event (e.g. death) can preclude the outcome of interest.

Two input modes are supported:

**Mode A** — a single column encodes all event types:

``` r

# Construct a combined event column: 0 = censored, 1 = DM, 2 = HTN (competing)
dt_cr <- dt[htn_timing != 1L]   # also exclude prevalent HTN
dt_cr[, event_type := data.table::fcase(
  dm_timing  == 2L, 1L,
  htn_timing == 2L, 2L,
  default          = 0L
)]

res <- assoc_competing(
  data         = dt_cr,
  outcome_col  = "event_type",       # 0 = censored, 1 = DM, 2 = HTN
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  event_val    = 1L,
  compete_val  = 2L,
  covariates   = c("bmi_cat", "tdi_cat")
)
```

**Mode B** — separate 0/1 columns for primary and competing events:

``` r

res <- assoc_competing(
  data         = dt_cr,
  outcome_col  = "dm_status",        # primary event
  time_col     = "dm_followup_years",
  exposure_col = c("p20116_i0", "bmi_cat"),
  compete_col  = "htn_status",       # competing event
  covariates   = c("tdi_cat", "p1558_i0")
)
```

Output uses `SHR` (subdistribution hazard ratio) and `SHR_label` in
place of HR, and adds `n_compete` (number of competing events in the
analysis set).

------------------------------------------------------------------------

## Working with Results

All functions return a `data.table` that feeds directly into
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md):

``` r

res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0")
)

# Pass directly to plot_forest() — est/CI/columns auto-derived
plot_forest(res)

# Filter to a single model
res[model == "Fully adjusted"]

# Export
data.table::fwrite(res, "assoc_results.csv")
```

------------------------------------------------------------------------

## Step 9: Lag Sensitivity Analysis

[`assoc_lag()`](https://evanbio.github.io/ukbflow/reference/assoc_lag.md)
re-runs the same Cox models at one or more lag periods to assess whether
associations are driven by early events (reverse causation or detection
bias). For each lag, participants whose follow-up time is less than
`lag_years` are excluded; follow-up is kept on its original scale.

``` r

res <- assoc_lag(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  lag_years    = c(0, 1, 2),   # 0 = full cohort reference
  covariates   = c("bmi_cat", "tdi_cat", "p1558_i0")
)
```

Setting `lag_years = 0` (or including `0` in the vector) runs the model
on the full unfiltered cohort, providing a reference row against which
lagged results can be compared.

Output adds two columns to the standard
[`assoc_coxph()`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
result:

| Column       | Description                                            |
|--------------|--------------------------------------------------------|
| `lag_years`  | Lag period applied (numeric, same units as `time_col`) |
| `n_excluded` | Participants excluded because follow-up \< `lag_years` |

------------------------------------------------------------------------

## Step 10: E-value Sensitivity Analysis

Observational associations can always be questioned on the grounds of
unmeasured confounding.
[`assoc_evalue()`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md)
quantifies that concern with the E-value (VanderWeele & Ding, 2017): the
minimum strength of association — on the risk-ratio scale — that an
unmeasured confounder would need with **both** the exposure and the
outcome, beyond the measured covariates, to fully explain away the
observed effect. A larger E-value means a more robust finding; you
benchmark it against how strongly the measured confounders (and any
plausible unmeasured one) associate with the outcome.

It reports two numbers per estimate: the E-value for the point estimate,
and the E-value for the confidence limit closest to the null (which is 1
when the interval already spans the null).

Pass a Cox or logistic result straight in — the `HR`/`OR` and CI columns
are read automatically, and two columns (`evalue_point`, `evalue_ci`)
are appended:

``` r

res <- assoc_coxph(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0"            # smoking status
)

assoc_evalue(res)
```

The **rare-outcome assumption** matters: the E-value is defined on the
risk-ratio scale, so a hazard or odds ratio is used directly only when
the outcome is rare; for a common outcome it is first converted to an
RR. In result mode the prevalence is inferred from `n_events`/`n` (or
`n_cases`/`n`) and the outcome is treated as rare below 15%; use
`rare = TRUE`/`FALSE` to override.

You can also evaluate a single hand-entered estimate — e.g. one reported
in another paper — with argument names matching
[`plot_forest()`](https://evanbio.github.io/ukbflow/reference/plot_forest.md):

``` r

assoc_evalue(est = 2.0, lower = 1.5, upper = 2.7, measure = "HR", rare = TRUE)
```

Linear (`beta`) and competing-risks (`SHR`) results are not supported;
the E-value needs a ratio effect measure.

------------------------------------------------------------------------

## Getting Help

- [`?assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
  [`?assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md),
  [`?assoc_linear`](https://evanbio.github.io/ukbflow/reference/assoc_linear.md)
- [`?assoc_coxph_zph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph_zph.md),
  [`?assoc_subgroup`](https://evanbio.github.io/ukbflow/reference/assoc_subgroup.md),
  [`?assoc_trend`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md),
  [`?assoc_rcs`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md),
  [`?assoc_competing`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md),
  [`?assoc_lag`](https://evanbio.github.io/ukbflow/reference/assoc_lag.md),
  [`?assoc_evalue`](https://evanbio.github.io/ukbflow/reference/assoc_evalue.md)
- [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md)
  — follow-up time and event derivation
- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
  — disease phenotype derivation
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
