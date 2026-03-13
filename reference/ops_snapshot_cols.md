# Retrieve column names recorded at a snapshot

Returns the column names stored by a previous
[`ops_snapshot`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
call, optionally excluding columns you wish to keep.

## Usage

``` r
ops_snapshot_cols(label, keep = NULL)
```

## Arguments

- label:

  (character) Snapshot label passed to
  [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md).

- keep:

  (character or NULL) Column names to exclude from the returned vector
  (i.e. columns to retain in the data even if they were present at that
  snapshot). Default `NULL`.

## Value

A character vector of column names.

## Examples

``` r
if (FALSE) { # \dontrun{
ops_snapshot_cols("raw")
ops_snapshot_cols("raw", keep = "eid")
} # }
```
