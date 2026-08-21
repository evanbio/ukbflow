# Record an association model result

Stores a model result table returned by the `assoc_*` family in the
audit manifest. The result table is recorded directly because it is
usually small and contains the most useful analysis summary.

## Usage

``` r
audit_model(audit, result, label = NULL)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- result:

  A data.frame or data.table result table, typically returned by
  `assoc_coxph`, `assoc_logistic`, `assoc_linear`, or related helpers.

- label:

  (character or NULL) Optional label for this model record. Default:
  `NULL`, which creates `"model_N"`.

## Value

The updated `ukbflow_audit` object. The appended record includes:

- `method`:

  Model family, e.g. `"coxph"`, `"logistic"`, `"linear"`, `"coxph_zph"`,
  or `"competing"`. Read from the `assoc_*` call when available,
  otherwise inferred from result columns (`HR`/`OR`/ `beta`/`SHR`).

- `n_rows`:

  Number of rows in `result`.

- `exposures`:

  Exposure column name(s).

- `exposure_levels`:

  Named list of factor/character levels per exposure, including
  reference levels that never appear as their own row in `result`.

- `models`:

  Adjustment model labels present in `result`.

- `outcome_col`, `time_col`:

  Outcome and follow-up time column names.

- `covariates`:

  Covariate column names for the fully adjusted model.

- `strata`, `cluster_col`:

  Stratification and clustering variables, when used.

- `test`, `ci_method`, `conf_level`:

  P-value method, confidence-interval method, and confidence level.

- `exposure_scores`:

  For
  [`assoc_trend`](https://evanbio.github.io/ukbflow/reference/assoc_trend.md):
  named list of the numeric trend scores actually used per exposure
  (including auto-generated `0, 1, 2, ...` scores when none were
  supplied).

- `compete_col`, `event_val`, `compete_val`:

  For
  [`assoc_competing`](https://evanbio.github.io/ukbflow/reference/assoc_competing.md):
  how the competing event was encoded.

- `knots`, `ref`:

  For
  [`assoc_rcs`](https://evanbio.github.io/ukbflow/reference/assoc_rcs.md):
  the spline knot positions actually used and the reference exposure
  value the dose-response curve is centred on. Both are
  result-determining, so recording them keeps the analysis reproducible
  from the manifest alone (`knots` is empty and `ref` is `NA` for other
  model families).

- `results`:

  The full result table (factors converted to character for JSON
  safety).

- `recorded_at`:

  Timestamp.

## Details

When `result` comes straight from an `assoc_*` call, call-time details
that never appear as columns in the result table – the outcome column,
time column, covariates, exposure reference levels, and method-specific
settings such as `strata`, `test`, or `scores` – are picked up
automatically from a hidden attribute that `assoc_*` attaches to its own
return value. Nothing needs to be re-typed, and the result table itself
is unaffected: printing or plotting `result` looks exactly as it did
before. If `result` does not carry this attribute (e.g. a hand-built
data.frame), the corresponding fields are recorded as `NA` or empty
rather than failing.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
res <- data.frame(
  exposure = "smoking",
  term = "smokingEver",
  model = "Fully adjusted",
  n = 100,
  HR = 1.2,
  CI_lower = 1.0,
  CI_upper = 1.4,
  p_value = 0.04
)
aud <- audit_model(aud, res, "smoking_model")
```
