# Derive a binary disease flag from UKB death registry

Death registry records store the underlying (primary) cause of death in
field `p40001` and contributory (secondary) causes in field `p40002`,
both coded in ICD-10. The date of death is in field `p40000`. All three
fields have an instance dimension (`i0`, `i1`) reflecting potential
amendments; `p40002` additionally has an array dimension (`a0`, `a1`,
...).

## Usage

``` r
derive_death_registry(
  data,
  name,
  icd10,
  match = c("prefix", "exact", "regex"),
  cause = c("any", "primary", "secondary"),
  primary_cols = NULL,
  secondary_cols = NULL,
  date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data containing death
  registry fields.

- name:

  (character) Output column prefix, e.g. `"disease"` produces
  `disease_death` and `disease_death_date`.

- icd10:

  (character) ICD-10 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("L20", "L21")`. For `"regex"`, supply a
  single regex string.

- match:

  (character) Matching strategy: `"prefix"` (default), `"exact"`, or
  `"regex"`.

- cause:

  (character) Which death-certificate position to search: `"any"`
  (default) matches a code in either the underlying or a contributory
  cause; `"primary"` restricts to the underlying cause (`p40001`);
  `"secondary"` restricts to contributory causes (`p40002`). Use
  `"primary"` to reproduce studies that count only the underlying cause
  of death.

- primary_cols:

  (character or NULL) Names of primary cause columns (`p40001_i*`).
  `NULL` = auto-detect via field 40001.

- secondary_cols:

  (character or NULL) Names of secondary cause columns (`p40002_i*_a*`).
  `NULL` = auto-detect via field 40002.

- date_cols:

  (character or NULL) Names of death date columns (`p40000_i*`). `NULL`
  = auto-detect via field 40000.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_death` (logical) and `{name}_death_date` (IDate). Always returns
a `data.table`.

## Details

- `{name}_death`:

  Logical flag: `TRUE` if a matching ICD-10 code appears in a death
  registry record at the position selected by `cause` (underlying,
  contributory, or either).

- `{name}_death_date`:

  Earliest death date across matching instances (`IDate`). Note: this is
  the *date of death*, not onset date.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_death_registry(dt, name = "mi",   icd10 = "I21")
#> ✔ derive_death_registry (mi): 2 cases, 2 with date.
derive_death_registry(dt, name = "lung", icd10 = "C34")
#> ✔ derive_death_registry (lung): 1 case, 1 with date.
```
