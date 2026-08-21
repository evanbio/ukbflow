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

Invisibly, a named list with two character vectors: `added` (columns
present in `label2` but not `label1`) and `removed` (columns present in
`label1` but not `label2`). The comparison is printed to the console, so
assign the result when you need the vectors themselves.

## Examples

``` r
ops_snapshot(reset = TRUE, verbose = FALSE)

dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
ops_snapshot(dt, label = "raw")
#> ── snapshot: raw ───────────────────────────────────────────────────────────────
#> rows 100
#> cols 107
#> NA cols 83
#> size 0.14 MB
#> ────────────────────────────────────────────────────────────────────────────────
dt <- derive_missing(dt)
#> ✔ derive_missing: replaced 48 values across 3 columns (action = "na").
ops_snapshot(dt, label = "derived")
#> ── snapshot: derived ───────────────────────────────────────────────────────────
#> rows 100 (= 0)
#> cols 107 (= 0)
#> NA cols 85 (+2)
#> size 0.14 MB (= 0)
#> ────────────────────────────────────────────────────────────────────────────────
ops_snapshot_diff("raw", "derived")
#> Columns added (0):
#> Columns removed (0):
# $added   -- newly derived columns
# $removed -- columns dropped between snapshots

ops_snapshot(reset = TRUE, verbose = FALSE)
```
