# Compare column names between two snapshots

Returns lists of columns added and removed between two recorded
snapshots.

## Usage

``` r
ops_snapshot_diff(label1, label2)
```

## Arguments

- label1:

  (character) Label of the earlier snapshot.

- label2:

  (character) Label of the later snapshot.

## Value

A named list with two character vectors: `added` (columns present in
`label2` but not `label1`) and `removed` (columns present in `label1`
but not `label2`).

## Examples

``` r
if (FALSE) { # \dontrun{
ops_snapshot_diff("raw", "derived")
# $added   — newly derived columns
# $removed — columns dropped between snapshots
} # }
```
