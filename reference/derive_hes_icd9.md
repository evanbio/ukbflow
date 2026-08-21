# Derive a binary disease flag from UKB HES inpatient diagnoses (ICD-9)

The ICD-9 counterpart of
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md).
UK Biobank HES inpatient records store a legacy minority of diagnoses in
ICD-9 (mostly older Scottish records that predate the transition to
ICD-10). The field pair has the identical structure to the ICD-10
fields: field `p41271` (single JSON-array column on RAP) holds
any-position ICD-9 codes with corresponding dates in `p41281`
(`p41281_a0`, `p41281_a1`, ...); field `p41203` / `p41263` is the main
(primary-diagnosis-only) equivalent. As with
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
secondary-only selection is not offered: UKB stores secondary ICD-9
diagnoses in `p41205` but provides no aligned per-code date field.

## Usage

``` r
derive_hes_icd9(
  data,
  name,
  icd9,
  match = c("prefix", "exact", "regex"),
  position = c("any", "main"),
  disease_cols = NULL,
  date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data containing HES fields
  (`p41271` and `p41281_a*`).

- name:

  (character) Output column prefix, e.g. `"disease"` produces
  `disease_hes_icd9` and `disease_hes_icd9_date`.

- icd9:

  (character) ICD-9 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("331.0", "331.1")`. For `"regex"`, supply a
  single regex string.

- match:

  (character) Matching strategy: `"prefix"` (default) matches any code
  starting with the supplied string; `"exact"` requires a full match;
  `"regex"` uses `icd9` directly.

- position:

  (character) Diagnosis position: `"any"` (default) searches
  any-position diagnoses (`p41271` / `p41281`); `"main"` restricts to
  primary diagnoses (`p41203` / `p41263`). When `disease_cols` or
  `date_cols` are supplied explicitly they take precedence over the
  field pair implied by `position`.

- disease_cols:

  (character or NULL) Name of the diagnosis code column. `NULL` =
  auto-detect from `position` (`p41271` for `"any"`, `p41203` for
  `"main"`).

- date_cols:

  (character or NULL) Names of the aligned date columns (`p41281_a*` for
  `"any"`, `p41263_a*` for `"main"`). `NULL` = auto-detect from
  `position`.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_hes_icd9` (logical) and `{name}_hes_icd9_date` (IDate). Always
returns a `data.table`.

## Details

- `{name}_hes_icd9`:

  Logical flag: `TRUE` if any HES record contains a matching ICD-9 code.

- `{name}_hes_icd9_date`:

  Earliest first-diagnosis date across all matching codes (`IDate`).
  `NA` if no date is available.

Output columns are named `{name}_hes_icd9` / `{name}_hes_icd9_date`
rather than reusing `{name}_hes` / `{name}_hes_date`
([`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)'s
columns), so that an ICD-10 and an ICD-9 call against the same `name`
can both be run and combined (e.g. via OR on status, `pmin` on date)
without one overwriting the other.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_hes_icd9(dt, name = "dementia", icd9 = c("290.4", "331.0"))
#> ! derive_hes_icd9 (dementia): 0 cases found.

# Primary diagnosis only (p41203 / p41263)
derive_hes_icd9(dt, name = "dementia_main", icd9 = c("290.4", "331.0"),
                position = "main")
#> ! derive_hes_icd9 (dementia_main): 0 cases found.
```
