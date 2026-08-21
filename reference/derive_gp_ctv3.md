# Derive a disease flag from GP clinical events (CTV3 / Read v3)

Matches a CTV3 (Clinical Terms Version 3, "Read v3") code list against
the `read_3` column of `gp_clinical`. CTV3 is used by the England TPP
data provider (the single largest source of GP clinical events), and its
codes differ from Read v2 for the same concept, so it is a separate
source from
[`derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
with its own code list.

## Usage

``` r
derive_gp_ctv3(data, name, ctv3, gp, match = c("exact", "prefix", "regex"))
```

## Arguments

- data:

  (data.frame or data.table) Participant-level data, one row per `eid`.

- name:

  (character) Phenotype name; column stem for the outputs.

- ctv3:

  (character) CTV3 code(s), 5-char and case-sensitive.

- gp:

  The `gp_clinical` long table with columns `eid`, `read_3`, `event_dt`.

- match:

  (character) `"exact"` (default), `"prefix"`, or `"regex"`. `"prefix"`
  is discouraged for CTV3 (see Details) and warns.

## Value

The input `data` (invisibly) with two new columns added:
`{name}_gp_ctv3` (logical) and `{name}_gp_ctv3_date` (IDate). Always
returns a `data.table`; in-place modification is only guaranteed when
the input is already a `data.table`.

## Details

Output columns are `{name}_gp_ctv3` / `{name}_gp_ctv3_date`, with
identical status/date semantics and placeholder-date handling as
[`derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md).

Unlike Read v2, CTV3 codes are opaque identifiers whose hierarchy lives
in a separate relationship table (a polyhierarchy), **not** in the code
string: two CTV3 codes sharing leading characters are not necessarily
related. Prefix matching is therefore not clinically meaningful for
CTV3, so `match` defaults to `"exact"` and a warning is issued if
`"prefix"` is requested. CTV3 code lists are always enumerated exact
codes.

**data.table pass-by-reference**: when the input is a `data.table`, new
columns are added in-place via `:=` and the returned object and the
original variable point to the same memory. When the input is a plain
`data.frame` it is converted with `as.data.table()`, so the caller's
original object is unchanged – always assign the result back.

## Examples

``` r
# Match n and seed so the toy cohort and GP table share their eids
cohort <- ops_toy(n = 200, seed = 1)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 1
gp     <- ops_toy(scenario = "gp", n = 200, seed = 1)
#> ✔ ops_toy: 83 linked participants | 952 records | 5 columns | scenario = "gp" | seed = 1
cohort <- derive_gp_ctv3(cohort, "t2d", ctv3 = c("XaELQ", "C1091"), gp = gp)
#> ✔ derive_gp_ctv3 (t2d): 1 case, 1 with date.

if (FALSE) { # \dontrun{
# On the RAP, load the real gp_clinical table once and reuse it
gp <- extract_gp()
cohort <- derive_gp_ctv3(cohort, "t2d", ctv3 = c("XaELP"), gp = gp)
} # }
```
