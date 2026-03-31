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
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
ops_snapshot(dt, label = "raw")
#> ── snapshot: raw ───────────────────────────────────────────────────────────────
#> rows 100 (= 0)
#> cols 75 (= 0)
#> NA cols 51 (= 0)
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
# $added   — newly derived columns
# $removed — columns dropped between snapshots
```
