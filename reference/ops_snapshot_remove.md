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
if (FALSE) { # \dontrun{
ops_snapshot(data, label = "raw")
# ... derive_* operations ...
ops_snapshot(data, label = "derived")
ops_snapshot_diff("raw", "derived")   # inspect
data <- ops_snapshot_remove(data, from = "raw")  # clean up
} # }
```
