# Exclude withdrawn participants from a dataset

Reads a UK Biobank withdrawal list (a headerless single-column CSV of
anonymised participant IDs) and removes the corresponding rows from
`data`. A pair of
[`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
calls is made automatically so the before/after row counts are recorded
in the session snapshot history.

## Usage

``` r
ops_withdraw(data, file, eid_col = "eid", verbose = TRUE)
```

## Arguments

- data:

  A data.frame or data.table containing a participant ID column.

- file:

  (character) Path to the UKB withdrawal CSV file. The file must be a
  single-column, **header-free** CSV as supplied by UK Biobank (e.g.
  `w854944_20260310.csv`).

- eid_col:

  (character) Name of the participant ID column in `data`. Default
  `"eid"`.

- verbose:

  (logical) Print the CLI report. Default `TRUE`.

## Value

A data.table with withdrawn participants removed.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
withdraw_file <- tempfile(fileext = ".csv")
writeLines(as.character(dt$eid[1:5]), withdraw_file)
dt <- ops_withdraw(dt, file = withdraw_file)
#> ── snapshot: before_withdraw ───────────────────────────────────────────────────
#> rows 100 (= 0)
#> cols 75 (= 0)
#> NA cols (skipped)
#> size 0.09 MB (= 0)
#> ────────────────────────────────────────────────────────────────────────────────
#> ── snapshot: after_withdraw ────────────────────────────────────────────────────
#> rows 95 (-5)
#> cols 75 (= 0)
#> NA cols (skipped)
#> size 0.09 MB (= 0)
#> ────────────────────────────────────────────────────────────────────────────────
#> ℹ Withdrawal file: file23167f65769d.csv (5 IDs)
#> ✖ Excluded: 5 participants found in data
#> ✔ Remaining: 95 participants
```
