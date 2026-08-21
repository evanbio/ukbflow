# E-value for unmeasured confounding

Computes the E-value (VanderWeele & Ding, 2017) for one or more ratio
effect estimates. The E-value is the minimum strength of association, on
the risk ratio scale, that an unmeasured confounder would need to have
with *both* the exposure and the outcome - over and above the measured
covariates - to fully explain away the observed association. A larger
E-value means a more robust finding; benchmark it against the strength
of the measured confounders and of any plausible unmeasured one.

## Usage

``` r
assoc_evalue(
  data = NULL,
  est = NULL,
  lower = NULL,
  upper = NULL,
  measure = NULL,
  rare = NULL
)
```

## Arguments

- data:

  (data.frame or NULL) An
  [`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  /
  [`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  result (result mode). Omit for manual mode.

- est, lower, upper:

  (numeric or NULL) A single point estimate and its confidence limits
  (manual mode), named to match
  [`plot_forest`](https://evanbio.github.io/ukbflow/reference/plot_forest.md).

- measure:

  (character or NULL) Effect measure: `"HR"`, `"OR"`, or `"RR"`.
  Required in manual mode; auto-detected from the result columns in
  result mode.

- rare:

  (logical or NULL) Whether the outcome is rare (roughly \< 15\\ `NULL`
  (default) infers it from the result's prevalence in result mode; it
  must be supplied in manual mode.

## Value

In result mode, the input table with `evalue_point` and `evalue_ci`
columns appended (reference rows get `evalue_point = 1` and
`evalue_ci = NA`). In manual mode, a one-row `data.table` with
`measure`, `est`, `lower`, `upper`, `rare`, `evalue_point`, and
`evalue_ci`.

Unlike the model-fitting `assoc_*` functions, this one records no call
of its own. In result mode it keeps the input table's `ukbflow_call`
attribute and adds one `evalue_rare` entry to it, so passing the
augmented table to
[`audit_model`](https://evanbio.github.io/ukbflow/reference/audit_model.md)
records both the model that produced the estimate and the rare-outcome
assumption the E-value was computed under. In manual mode there is no
model and no such attribute.

## Details

Two values are reported per estimate: the E-value for the point
estimate, and the E-value for the confidence limit closest to the null
(which is 1 when the interval already spans the null).

**Two ways to call it:**

- *Result mode* - pass an
  [`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md)
  or
  [`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)
  result as `data`; the `HR`/`OR` and `CI_lower`/`CI_upper` columns are
  read automatically and two columns (`evalue_point`, `evalue_ci`) are
  appended.

- *Manual mode* - supply a single estimate via `est`, `lower`, `upper`,
  `measure`, and `rare`.

**Effect measure and the rare-outcome assumption**: the E-value is
defined on the risk ratio (RR) scale. When the outcome is rare, hazard
and odds ratios approximate the RR directly; when it is common they are
converted first (`OR -> sqrt(OR)`;
`HR -> (1 - 0.5^sqrt(HR)) / (1 - 0.5^sqrt(1/HR))`). In result mode the
outcome prevalence is inferred from `n_events`/`n` (Cox) or
`n_cases`/`n` (logistic) and the outcome is treated as rare below 15\\
stated explicitly.

Linear (`beta`) and competing-risks (`SHR`) results are not supported.

## References

VanderWeele TJ, Ding P (2017). Sensitivity Analysis in Observational
Research: Introducing the E-Value. *Annals of Internal Medicine*,
167(4):268-274. [doi:10.7326/M16-2607](https://doi.org/10.7326/M16-2607)

## See also

[`assoc_coxph`](https://evanbio.github.io/ukbflow/reference/assoc_coxph.md),
[`assoc_logistic`](https://evanbio.github.io/ukbflow/reference/assoc_logistic.md)

## Examples

``` r
# Manual mode: a single hazard ratio from a rare outcome
assoc_evalue(est = 2.0, lower = 1.5, upper = 2.7, measure = "HR", rare = TRUE)
#> 
#> ── assoc_evalue ────────────────────────────────────────────────────────────────
#> ℹ HR = 2 (1.5-2.7) | rare = TRUE
#> ✔ E-value: point = 3.41, CI = 2.37
#>    measure   est lower upper   rare evalue_point evalue_ci
#>     <char> <num> <num> <num> <lgcl>        <num>     <num>
#> 1:      HR     2   1.5   2.7   TRUE     3.414214  2.366025

# Result mode: append E-values to a Cox result
dt <- ops_toy(scenario = "association", n = 500)
#> ✔ ops_toy: 500 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L]
res <- assoc_coxph(dt, "dm_status", "dm_followup_years", "p20116_i0")
#> ℹ outcome_col dm_status: logical detected, converting TRUE/FALSE -> 1/0
#> 
#> ── assoc_coxph ─────────────────────────────────────────────────────────────────
#> ℹ 1 exposure x 2 models = 2 Cox regressions
#> ℹ Input cohort: 463 participants (n/n_events/person_years reflect each model's actual analysis set)
#> 
#> ── p20116_i0 ──
#> 
#> ✔   Unadjusted | p20116_i0Previous: HR 0.39 (0.13-1.16), p = 0.0905
#> ✔   Unadjusted | p20116_i0Current: HR 0.41 (0.10-1.77), p = 0.233
#> ✔   Age and sex adjusted | p20116_i0Previous: HR 0.40 (0.14-1.20), p = 0.102
#> ✔   Age and sex adjusted | p20116_i0Current: HR 0.43 (0.10-1.85), p = 0.255
#> ✔ Done: 4 result rows across 1 exposure and 2 models.
assoc_evalue(res)
#> ℹ Outcome prevalence ~ 5.3% -> treating outcome as rare (set `rare` to override).
#> 
#> ── assoc_evalue ────────────────────────────────────────────────────────────────
#> ℹ 4 estimates | measure: HR | rare: TRUE
#> ✔ Appended evalue_point and evalue_ci.
#>     exposure              term                model     n n_events person_years
#>       <char>            <char>                <ord> <int>    <num>        <num>
#> 1: p20116_i0 p20116_i0Previous           Unadjusted   452       24         6282
#> 2: p20116_i0  p20116_i0Current           Unadjusted   452       24         6282
#> 3: p20116_i0 p20116_i0Previous Age and sex adjusted   452       24         6282
#> 4: p20116_i0  p20116_i0Current Age and sex adjusted   452       24         6282
#>           HR   CI_lower CI_upper    p_value         HR_label evalue_point
#>        <num>      <num>    <num>      <num>           <char>        <num>
#> 1: 0.3922323 0.13273660 1.159034 0.09045762 0.39 (0.13-1.16)     4.537093
#> 2: 0.4113660 0.09544740 1.772934 0.23337427 0.41 (0.10-1.77)     4.295992
#> 3: 0.4042074 0.13639439 1.197877 0.10221104 0.40 (0.14-1.20)     4.383581
#> 4: 0.4264325 0.09815851 1.852561 0.25543188 0.43 (0.10-1.85)     4.121033
#>    evalue_ci
#>        <num>
#> 1:         1
#> 2:         1
#> 3:         1
#> 4:         1
```
