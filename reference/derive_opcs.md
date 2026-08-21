# Derive a binary procedure flag from UKB HES operative procedures (OPCS-4)

The OPCS-4 counterpart of
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md).
UK Biobank HES records store operative procedures (surgery /
intervention codes) in exactly the same array-aligned structure as the
ICD diagnosis fields, only under a different coding scheme (UKB encoding
240, OPCS-4). Field `p41272` (single JSON-array column on RAP) holds
any-position OPCS-4 codes with corresponding dates in `p41282`
(`p41282_a0`, `p41282_a1`, ...); field `p41200` / `p41260` is the main
(primary-procedure-only) equivalent. As with
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
secondary-only selection is not offered: UKB stores secondary OPCS-4
procedures in `p41210` but provides no aligned per-code date field.

## Usage

``` r
derive_opcs(
  data,
  name,
  opcs,
  match = c("prefix", "exact", "regex"),
  position = c("any", "main"),
  disease_cols = NULL,
  date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data containing HES OPCS-4
  fields (`p41272` and `p41282_a*`).

- name:

  (character) Output column prefix, e.g. `"chole"` produces `chole_opcs`
  and `chole_opcs_date`.

- opcs:

  (character) OPCS-4 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("J18", "J21")`. For `"regex"`, supply a
  single regex string.

- match:

  (character) Matching strategy: `"prefix"` (default) matches any code
  starting with the supplied string; `"exact"` requires a full match;
  `"regex"` uses `opcs` directly.

- position:

  (character) Procedure position: `"any"` (default) searches
  any-position procedures (`p41272` / `p41282`); `"main"` restricts to
  primary procedures (`p41200` / `p41260`). When `disease_cols` or
  `date_cols` are supplied explicitly they take precedence over the
  field pair implied by `position`.

- disease_cols:

  (character or NULL) Name of the procedure code column. `NULL` =
  auto-detect from `position` (`p41272` for `"any"`, `p41200` for
  `"main"`).

- date_cols:

  (character or NULL) Names of the aligned date columns (`p41282_a*` for
  `"any"`, `p41260_a*` for `"main"`). `NULL` = auto-detect from
  `position`.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_opcs` (logical) and `{name}_opcs_date` (IDate). Always returns a
`data.table`.

## Details

- `{name}_opcs`:

  Logical flag: `TRUE` if any HES record contains a matching OPCS-4
  code.

- `{name}_opcs_date`:

  Earliest first-procedure date across all matching codes (`IDate`).
  `NA` if no date is available.

Output columns are named `{name}_opcs` / `{name}_opcs_date`, a namespace
distinct from
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)'s
`{name}_hes` and
[`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md)'s
`{name}_hes_icd9`, so an ICD diagnosis call and an OPCS-4 procedure call
against the same `name` can both be run and combined without one
overwriting the other.

HES OPCS-4 values are stored in the dotted format (e.g. `"A01.1"`),
matching the ICD-10 convention, so supply codes in the same form (a
prefix such as `"A01"` matches every subcode of that operation).

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_opcs(dt, name = "cabg", opcs = c("K40", "K44"))
#> ✔ derive_opcs (cabg): 13 cases, 13 with date.

# Primary procedure only (p41200 / p41260)
derive_opcs(dt, name = "cabg_main", opcs = c("K40", "K44"),
            position = "main")
#> ✔ derive_opcs (cabg_main): 12 cases, 12 with date.
```
