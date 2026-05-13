# Record a derived phenotype audit summary

Summarises phenotype columns created by the `derive_*` family using
ukbflow's standard `name` prefix convention. The function records
whichever columns are present and marks missing components as not
present.

## Usage

``` r
audit_pheno(audit, data, name)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- data:

  A data.frame or data.table containing derived phenotype columns.

- name:

  (character) Phenotype prefix used by `derive_*`, e.g. `"lung"` for
  `lung_status`, `lung_icd10`, and `lung_timing`.

## Value

The updated `ukbflow_audit` object.

## Examples

``` r
aud <- audit_start("example_analysis")
dt <- data.frame(
  eid = 1:3,
  lung_status = c(TRUE, FALSE, TRUE),
  lung_date = as.Date(c("2020-01-01", NA, "2021-01-01"))
)
aud <- audit_pheno(aud, dt, "lung")
```
