# Read a ukbflow audit manifest back into a ukbflow_audit object

Parses a JSON manifest written by
[`audit_write`](https://evanbio.github.io/ukbflow/reference/audit_write.md)
and reconstructs a `ukbflow_audit` object, so a past analysis's audit
trail can be inspected or compared (e.g. with
[`audit_diff`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
or
[`audit_cols`](https://evanbio.github.io/ukbflow/reference/audit_cols.md))
without having to re-run the analysis.

## Usage

``` r
audit_read(file)
```

## Arguments

- file:

  (character) Path to a JSON manifest written by
  [`audit_write`](https://evanbio.github.io/ukbflow/reference/audit_write.md).

## Value

A `ukbflow_audit` object.

## Details

Restoration is exact for the `fields`, `snapshots`, `models`, and `jobs`
layers and the `meta` block: array-valued fields (`field_id`, `columns`,
`exposures`, `covariates`, `strata`, `models`, the model `results`
table) come back as the same atomic vectors / data.frame they were
before writing, and optional scalar fields that were `NA` at write time
(e.g. `outcome_col`, `conf_level`) come back as `NA` rather than `NULL`
or the literal string `"NA"`.

The `recipes` and `phenotypes` layers are passed through as parsed from
JSON without this per-field restoration. Their record envelope (`label`
/ `recorded_at`) is always correct, but nested numeric fields that were
`NA` at write time (e.g. a phenotype's `n_cases`) come back as the
string `"NA"` rather than `NA_integer_`, since neither layer is
currently read by
[`audit_diff`](https://evanbio.github.io/ukbflow/reference/audit_diff.md)
or
[`audit_cols`](https://evanbio.github.io/ukbflow/reference/audit_cols.md).

`meta$session_info` was already reduced to printed text lines by
[`audit_write`](https://evanbio.github.io/ukbflow/reference/audit_write.md);
this returns that character vector rather than the original
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) object,
which cannot be reconstructed.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
aud <- audit_snapshot(aud, data.frame(eid = 1:3, x = 1:3), "raw", verbose = FALSE)
file <- tempfile(fileext = ".json")
audit_write(aud, file)
#> ✔ audit manifest written: /tmp/RtmpLXmOSW/file20cd711f1cd0.json
aud2 <- audit_read(file)
audit_cols(aud2, "raw")
#> [1] "eid" "x"  
```
