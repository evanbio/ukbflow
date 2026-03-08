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

  (character) Output column prefix, e.g. `"ad"` produces `ad_death` and
  `ad_death_date`.

- icd10:

  (character) ICD-10 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("L20", "L21")`. For `"regex"`, supply a
  single regex string.

- match:

  (character) Matching strategy: `"prefix"` (default), `"exact"`, or
  `"regex"`.

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

The input `data` with two new columns added in-place: `{name}_death`
(logical) and `{name}_death_date` (IDate). Always returns a
`data.table`.

## Details

- `{name}_death`:

  Logical flag: `TRUE` if any death registry record (primary or
  secondary cause) contains a matching ICD-10 code.

- `{name}_death_date`:

  Earliest death date across matching instances (`IDate`). Note: this is
  the *date of death*, not onset date.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- derive_death_registry(df, name = "disease", icd10 = "E11")
df <- derive_death_registry(df, name = "copd",
                            icd10 = c("J440", "J441"), match = "exact")
} # }
```
