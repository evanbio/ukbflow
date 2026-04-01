# Remove raw source columns recorded at a snapshot

Drops columns that were present at snapshot `from` from `data`, while
automatically protecting built-in safe columns (`"eid"`, `"sex"`,
`"age"`, `"age_at_recruitment"`) and any user-registered safe columns
set via
[`ops_set_safe_cols`](https://evanbio.github.io/ukbflow/reference/ops_set_safe_cols.md).
Columns that no longer exist in `data` are silently skipped.

## Usage

``` r
ops_snapshot_remove(data, from, keep = NULL, verbose = TRUE)
```

## Arguments

- data:

  A data.frame or data.table.

- from:

  (character) Label of the snapshot whose columns should be dropped
  (typically `"raw"`).

- keep:

  (character or NULL) Additional column names to protect beyond the
  built-in and user-registered safe cols. Default `NULL`.

- verbose:

  (logical) Print a summary of dropped columns. Default `TRUE`.

## Value

A `data.table` with the specified columns removed. For `data.table`
input the operation is performed by reference (in-place); for
`data.frame` input the data is first converted to a new `data.table` —
the original `data.frame` is not modified.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
ops_snapshot(dt, label = "raw")
#> ── snapshot: raw ───────────────────────────────────────────────────────────────
#> rows 100 (= 0)
#> cols 75 (= 0)
#> NA cols 51 (-2)
#> size 0.09 MB (= 0)
#> ────────────────────────────────────────────────────────────────────────────────
dt <- derive_missing(dt)
#> ✔ derive_missing: replaced 47 values across 3 columns (action = "na").
ops_snapshot(dt, label = "derived")
#> ── snapshot: derived ───────────────────────────────────────────────────────────
#> rows 100 (= 0)
#> cols 75 (= 0)
#> NA cols 53 (+2)
#> size 0.09 MB (= 0)
#> ────────────────────────────────────────────────────────────────────────────────
ops_snapshot_diff("raw", "derived")
#> Columns added (0):
#> Columns removed (0):
dt <- ops_snapshot_remove(dt, from = "raw")
#> ✔ ops_snapshot_remove: dropped 74 raw columns, 1 remaining.
```
