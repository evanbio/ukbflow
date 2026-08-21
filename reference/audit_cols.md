# Retrieve column names from an audit snapshot

Returns the complete column names recorded by
[`audit_snapshot`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md)
for a given snapshot label. Unlike
[`ops_snapshot_cols`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md),
this helper does not exclude protected columns; it returns exactly the
columns stored in the audit manifest.

## Usage

``` r
audit_cols(audit, label)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- label:

  (character) Snapshot label passed to
  [`audit_snapshot`](https://evanbio.github.io/ukbflow/reference/audit_snapshot.md).

## Value

A character vector of column names.

## Examples

``` r
aud <- audit_start("example_analysis")
dt <- data.frame(eid = 1:3, x = c(1, NA, 3))
aud <- audit_snapshot(aud, dt, "raw", verbose = FALSE)
audit_cols(aud, "raw")
#> [1] "eid" "x"  
```
