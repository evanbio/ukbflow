# Record an association model result

Stores a model result table returned by the `assoc_*` family in the
audit manifest. The result table is recorded directly because it is
usually small and contains the most useful analysis summary. Optional
covariates can be supplied when they already exist as a vector in the
analysis script.

## Usage

``` r
audit_model(audit, result, label = NULL, covariates = NULL)
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

- covariates:

  (character or NULL) Optional covariate column names used in the model.
  Default: `NULL`.

## Value

The updated `ukbflow_audit` object.

## Examples

``` r
aud <- audit_start("example_analysis")
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
aud <- audit_model(aud, res, "smoking_model", covariates = c("age", "sex"))
```
