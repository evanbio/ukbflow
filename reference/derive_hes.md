# Derive a binary disease flag from UKB HES inpatient diagnoses

Hospital Episode Statistics (HES) inpatient records store ICD-10
diagnosis codes in field `p41270` (single JSON-array column on UKB RAP)
and corresponding first-diagnosis dates in field `p41280` (`p41280_a0`,
`p41280_a1`, ...). The array index in `p41270` and `p41280` are aligned:
the *N*-th code in the JSON array corresponds to `p41280_aN` (date of
first in-patient diagnosis for that code).

## Usage

``` r
derive_hes(
  data,
  name,
  icd10,
  match = c("prefix", "exact", "regex"),
  position = c("any", "main"),
  disease_cols = NULL,
  date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data containing HES fields
  (`p41270` and `p41280_a*`).

- name:

  (character) Output column prefix, e.g. `"disease"` produces
  `disease_hes` and `disease_hes_date`.

- icd10:

  (character) ICD-10 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("L20", "L21")`. For `"regex"`, supply a
  single regex string.

- match:

  (character) Matching strategy: `"prefix"` (default) matches any code
  starting with the supplied string; `"exact"` requires a full match;
  `"regex"` uses `icd10` directly.

- position:

  (character) Diagnosis position: `"any"` (default) searches
  any-position diagnoses (`p41270` / `p41280`); `"main"` restricts to
  primary diagnoses (`p41202` / `p41262`). When `disease_cols` or
  `date_cols` are supplied explicitly they take precedence over the
  field pair implied by `position`.

- disease_cols:

  (character or NULL) Name of the diagnosis code column. `NULL` =
  auto-detect from `position` (`p41270` for `"any"`, `p41202` for
  `"main"`).

- date_cols:

  (character or NULL) Names of the aligned date columns (`p41280_a*` for
  `"any"`, `p41262_a*` for `"main"`). `NULL` = auto-detect from
  `position`.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_hes` (logical) and `{name}_hes_date` (IDate). Always returns a
`data.table`.

## Details

**Diagnosis position**: `position` selects the code/date field pair.
`"any"` (default) uses `p41270` / `p41280` and counts a code recorded in
*any* diagnosis position. `"main"` uses `p41202` / `p41262` and counts
only *primary* (main) diagnoses. Secondary-only selection is not
offered: UKB stores secondary diagnoses in `p41204` but provides no
aligned per-code date field for them, so a status-plus-date result
cannot be produced.

- `{name}_hes`:

  Logical flag: `TRUE` if any HES record contains a matching ICD-10
  code.

- `{name}_hes_date`:

  Earliest first-diagnosis date across all matching codes (`IDate`).
  `NA` if no date is available.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_hes(dt, name = "htn",      icd10 = "I10")
#> ✔ derive_hes (htn): 8 cases, 8 with date.
derive_hes(dt, name = "diabetes", icd10 = c("E10", "E11"))
#> ✔ derive_hes (diabetes): 7 cases, 7 with date.
derive_hes(dt, name = "asthma",   icd10 = "^J4", match = "regex")
#> ! derive_hes (asthma): 0 cases found.

# Primary diagnosis only: a subset of the any-position result above
derive_hes(dt, name = "htn_main", icd10 = "I10", position = "main")
#> ✔ derive_hes (htn_main): 6 cases, 6 with date.
```
