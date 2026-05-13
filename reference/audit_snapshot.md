# Record a data snapshot in a ukbflow audit object

Captures a lightweight structural snapshot of a data.frame at a named
analysis stage and appends it to the `snapshots` layer of a
`ukbflow_audit` object. This function mirrors the core behavior of
[`ops_snapshot`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
but stores records inside the explicit audit object rather than a
session cache.

## Usage

``` r
audit_snapshot(
  audit,
  data = NULL,
  label = NULL,
  reset = FALSE,
  check_na = TRUE,
  verbose = TRUE
)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- data:

  A data.frame or data.table to snapshot. Required unless
  `reset = TRUE`.

- label:

  (character) A unique label for this snapshot, e.g. `"raw_extracted"`
  or `"analysis_ready"`. Required unless `reset = TRUE`.

- reset:

  (logical) If `TRUE`, clears only the `audit$snapshots` layer and
  returns the updated audit object. Default: `FALSE`.

- check_na:

  (logical) Whether to count columns with any `NA` or blank string
  values. Set to `FALSE` to avoid scanning large datasets. Default:
  `TRUE`.

- verbose:

  (logical) Print a short status message. Default: `TRUE`.

## Value

The updated `ukbflow_audit` object.

## Examples

``` r
aud <- audit_start("example_analysis")
dt <- data.frame(eid = 1:3, x = c(1, NA, 3))
aud <- audit_snapshot(aud, dt, "raw")
#> ✔ audit snapshot "raw": 3 rows x 2 cols.
```
