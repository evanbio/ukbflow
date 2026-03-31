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
if (FALSE) { # \dontrun{
dt <- fread("ukb_phenotype.csv")
dt <- ops_withdraw(dt, file = "w854944_20260310.csv")
} # }
```
