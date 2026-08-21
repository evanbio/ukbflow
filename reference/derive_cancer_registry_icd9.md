# Derive a binary disease flag from UKB cancer registry (ICD-9)

The ICD-9 counterpart of
[`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).
A minority of UK Biobank cancer registrations (older records) are coded
in ICD-9 (field `p40013`) instead of ICD-10 (`p40006`). Diagnosis date
(`p40005`), histology (`p40011`), and behaviour (`p40012`) are the same
instance-indexed fields for both code systems: a given registration
instance carries a code in *either* `p40006` or `p40013`, and its
date/histology/behaviour live in the shared fields at that same instance
index. `p40013` has fewer instances than `p40006` (older, legacy
minority of registrations), but this does not affect matching against
the shared fields, which are looked up by instance number rather than by
array position.

## Usage

``` r
derive_cancer_registry_icd9(
  data,
  name,
  icd9 = NULL,
  histology = NULL,
  behaviour = NULL,
  code_cols = NULL,
  hist_cols = NULL,
  behv_cols = NULL,
  date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data containing cancer
  registry fields.

- name:

  (character) Output column prefix, e.g. `"outcome_invasive"` produces
  `outcome_invasive_cancer_icd9` and
  `outcome_invasive_cancer_icd9_date`.

- icd9:

  (character or NULL) Regular expression matched against the ICD-9 code
  column (`p40013`). `NULL` = no ICD-9 filter.

- histology:

  (integer vector or NULL) Histology codes to retain (`p40011`). `NULL`
  = no histology filter.

- behaviour:

  (integer vector or NULL) Behaviour codes to retain (`p40012`). `NULL`
  = no behaviour filter. Typical values: `3L` (invasive / malignant),
  `2L` (in situ).

- code_cols:

  (character or NULL) Names of ICD-9 code columns (`p40013_i*`). `NULL`
  = auto-detect via field 40013.

- hist_cols:

  (character or NULL) Names of histology columns (`p40011_i*`). `NULL` =
  auto-detect via field 40011.

- behv_cols:

  (character or NULL) Names of behaviour columns (`p40012_i*`). `NULL` =
  auto-detect via field 40012.

- date_cols:

  (character or NULL) Names of diagnosis date columns (`p40005_i*`).
  `NULL` = auto-detect via field 40005.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_cancer_icd9` (logical) and `{name}_cancer_icd9_date` (IDate).
Always returns a `data.table`.

## Details

All three filter arguments (`icd9`, `histology`, `behaviour`) are
applied with AND logic: a record must satisfy every non-`NULL` filter to
be counted. For OR conditions, call the function twice and combine the
resulting columns downstream.

- `{name}_cancer_icd9`:

  Logical flag: `TRUE` if any cancer registry record satisfies all
  supplied filters.

- `{name}_cancer_icd9_date`:

  Earliest matching diagnosis date (`IDate`).

Output columns are named `{name}_cancer_icd9` /
`{name}_cancer_icd9_date` rather than reusing `{name}_cancer` /
`{name}_cancer_date`
([`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)'s
columns), so that an ICD-10 and an ICD-9 call against the same `name`
can both be run and combined without one overwriting the other.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_cancer_registry_icd9(dt, name = "skin", icd9 = "^173")
#> ! derive_cancer_registry_icd9 (skin): 0 cases after filtering.
```
