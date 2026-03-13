# Record and review dataset pipeline snapshots

Captures a lightweight summary of a data.frame at a given pipeline stage
and stores it in the session cache. Subsequent calls automatically
compute deltas (Δ) against the previous snapshot, making it easy to
track how data changes through `derive_*`, `assoc_*`, and other
processing steps.

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
if (FALSE) { # \dontrun{
dt <- ops_toy()
ops_snapshot(dt, label = "raw")

dt <- derive_missing(dt)
ops_snapshot(dt, label = "after_derive_missing")

# View full history
ops_snapshot()

# Reset history
ops_snapshot(reset = TRUE)
} # }
```
