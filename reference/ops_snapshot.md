# Record and review dataset pipeline snapshots

Captures a lightweight summary of a data.frame at a given pipeline stage
and stores it in the session cache. Subsequent calls automatically
compute deltas against the previous snapshot, making it easy to track
how data changes through `derive_*`, `assoc_*`, and other processing
steps.

## Usage

``` r
ops_snapshot(
  data = NULL,
  label = NULL,
  reset = FALSE,
  verbose = TRUE,
  check_na = TRUE
)
```

## Arguments

- data:

  A data.frame or data.table to snapshot. Pass `NULL` (or omit) to print
  the full snapshot history without recording a new entry.

- label:

  (character) A short name for this pipeline stage, e.g. `"raw"`,
  `"after_derive_missing"`. Defaults to `"snapshot_N"` where N is the
  sequential index.

- reset:

  (logical) If `TRUE`, clears the entire snapshot history and returns
  invisibly. Default `FALSE`.

- verbose:

  (logical) Print the CLI report. Default `TRUE`.

- check_na:

  (logical) Whether to count columns with any `NA` or blank string
  values and include the delta in the report. Set to `FALSE` to skip the
  NA scan (useful for large datasets or when NA tracking is not needed).
  Default `TRUE`.

## Value

When `data` is supplied, returns the new snapshot row invisibly (a
one-row data.table). When called with no `data`, returns the full
history data.table invisibly.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
ops_snapshot(dt, label = "raw")
#> ── snapshot: raw ───────────────────────────────────────────────────────────────
#> rows 100
#> cols 75
#> NA cols 51
#> size 0.09 MB
#> ────────────────────────────────────────────────────────────────────────────────

dt <- derive_missing(dt)
#> ✔ derive_missing: replaced 47 values across 3 columns (action = "na").
ops_snapshot(dt, label = "after_derive_missing")
#> ── snapshot: after_derive_missing ──────────────────────────────────────────────
#> rows 100 (= 0)
#> cols 75 (= 0)
#> NA cols 53 (+2)
#> size 0.09 MB (= 0)
#> ────────────────────────────────────────────────────────────────────────────────

# View full history
ops_snapshot()
#> ── ops_snapshot history ────────────────────────────────────────────────────────
#>      idx                label timestamp  nrow  ncol n_na_cols size_mb
#>    <int>               <char>    <char> <int> <int>     <int>   <num>
#> 1:     1                  raw  07:27:02   100    75        51    0.09
#> 2:     2 after_derive_missing  07:27:02   100    75        53    0.09
#> ────────────────────────────────────────────────────────────────────────────────

# Reset history
ops_snapshot(reset = TRUE)
#> ✔ Snapshot history cleared.
```
