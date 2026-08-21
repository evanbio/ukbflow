# Derive a disease flag from GP clinical events (Read v2)

Matches a Read version 2 code list against the `read_2` column of the UK
Biobank primary-care clinical-events table (`gp_clinical`, Record Table
1060) and writes a status flag plus earliest event date. Read v2 and
CTV3 are separate coding systems captured by different data providers
(Read v2: England Vision, Scotland, Wales), so they are handled as two
independent sources; see
[`derive_gp_ctv3`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md)
for the CTV3 arm.

## Usage

``` r
derive_gp_read2(data, name, read2, gp, match = c("exact", "prefix", "regex"))
```

## Arguments

- data:

  (data.frame or data.table) Participant-level data, one row per `eid`.

- name:

  (character) Phenotype name; column stem for the outputs.

- read2:

  (character) Read v2 code(s). Stored 5-char dot-padded and
  case-sensitive; supply codes as written (e.g. `"C10F."`).

- gp:

  The `gp_clinical` long table (`data.frame`/`data.table`) with columns
  `eid`, `read_2`, `event_dt`. Load once (e.g. with a future
  [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md))
  and reuse across calls.

- match:

  (character) `"exact"` (default), `"prefix"`, or `"regex"`. Read v2 is
  a positional single-hierarchy terminology, so a shared prefix *is* a
  genuine parent/child relationship and `"prefix"` validly selects a
  whole subtree (e.g. `"C10.."` for all diabetes). `"exact"` is the
  default because published Read v2 code lists are enumerated 5-char
  codes and exact matching reproduces them faithfully without silently
  over-capturing. All are hashed except `"regex"`, which scans the whole
  column and is slow on the full table.

## Value

The input `data` (invisibly) with two new columns added:
`{name}_gp_read2` (logical) and `{name}_gp_read2_date` (IDate). Always
returns a `data.table`; in-place modification is only guaranteed when
the input is already a `data.table`.

## Details

Output columns are named `{name}_gp_read2` / `{name}_gp_read2_date`. A
matching code always sets status `TRUE`. The date is the earliest
`event_dt` across matching records, **excluding** the UKB placeholder
dates (Coding 819: 1900-01-01, 1901-01-01, 1902-02-02, 1903-03-03,
1909-09-09, 2037-07-07); if every matching record has a placeholder
date, status is `TRUE` but date is `NA`.

Absence of a code yields `FALSE`, including the ~55\\ with no linked
primary-care data at all. Distinguishing "no code" from "not observed"
requires GP registration windows and is out of scope here.

**data.table pass-by-reference**: when the input is a `data.table`, new
columns are added in-place via `:=` and the returned object and the
original variable point to the same memory. When the input is a plain
`data.frame` it is first converted with `as.data.table()`, so the new
columns land only on the returned `data.table` and the caller's original
object is unchanged – always assign the result back.

## Examples

``` r
# Match n and seed so the toy cohort and GP table share their eids
cohort <- ops_toy(n = 200, seed = 1)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 1
gp     <- ops_toy(scenario = "gp", n = 200, seed = 1)
#> ✔ ops_toy: 83 linked participants | 952 records | 5 columns | scenario = "gp" | seed = 1
cohort <- derive_gp_read2(cohort, "t2d", read2 = c("C1041", "C10F6"), gp = gp)
#> ✔ derive_gp_read2 (t2d): 2 cases, 2 with date.

if (FALSE) { # \dontrun{
# On the RAP, load the real gp_clinical table once and reuse it
gp <- extract_gp()
cohort <- derive_gp_read2(cohort, "t2d", read2 = c("C10F.", "C10F0"), gp = gp)
} # }
```
