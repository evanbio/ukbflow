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

- disease_cols:

  (character or NULL) Name of the `p41270` column. `NULL` = auto-detect.

- date_cols:

  (character or NULL) Names of `p41280_a*` columns. `NULL` =
  auto-detect.

## Value

The input `data` with two new columns added in-place: `{name}_hes`
(logical) and `{name}_hes_date` (IDate). Always returns a `data.table`.

## Details

- `{name}_hes`:

  Logical flag: `TRUE` if any HES record contains a matching ICD-10
  code.

- `{name}_hes_date`:

  Earliest first-diagnosis date across all matching codes (`IDate`).
  `NA` if no date is available.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- derive_hes(df, name = "disease", icd10 = "E11")
df <- derive_hes(df, name = "disease",
                 icd10 = c("J440", "J441"), match = "exact")
df <- derive_hes(df, name = "disease",
                 icd10 = "^(E10|E11)", match = "regex")
} # }
```
