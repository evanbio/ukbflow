# Derive a binary disease flag from UKB cancer registry

The UK Biobank cancer registry links each participant's cancer diagnoses
from national cancer registries. Each diagnosis is stored as a separate
instance with four parallel fields: ICD-10 code (`p40006`), histology
code (`p40011`), behaviour code (`p40012`), and diagnosis date
(`p40005`). Unlike HES or self-report data, each instance holds exactly
one record - there is no array (`a*`) dimension.

## Usage

``` r
derive_cancer_registry(
  data,
  name,
  icd10 = NULL,
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
  `outcome_invasive_cancer` and `outcome_invasive_cancer_date`.

- icd10:

  (character or NULL) Regular expression matched against the ICD-10 code
  column (`p40006`). `NULL` = no ICD-10 filter. Examples: `"^C44"`,
  `"^(C44|D04)"`.

- histology:

  (integer vector or NULL) Histology codes to retain (`p40011`). `NULL`
  = no histology filter. Example: `c(8070:8078, 8083, 8084)`.

- behaviour:

  (integer vector or NULL) Behaviour codes to retain (`p40012`). `NULL`
  = no behaviour filter. Typical values: `3L` (invasive / malignant),
  `2L` (in situ).

- code_cols:

  (character or NULL) Names of ICD-10 code columns (`p40006_i*`). `NULL`
  = auto-detect via field 40006.

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
`{name}_cancer` (logical) and `{name}_cancer_date` (IDate). Always
returns a `data.table`.

## Details

All three filter arguments (`icd10`, `histology`, `behaviour`) are
applied with AND logic: a record must satisfy every non-`NULL` filter to
be counted. For OR conditions (e.g.\\ D04 *or* C44 with specific
histology), call the function twice and combine the resulting columns
downstream.

- `{name}_cancer`:

  Logical flag: `TRUE` if any cancer registry record satisfies all
  supplied filters.

- `{name}_cancer_date`:

  Earliest matching diagnosis date (`IDate`).

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_cancer_registry(dt, name = "skin",     icd10 = "^C44")
#> ✔ derive_cancer_registry (skin): 1 case, 1 with date.
derive_cancer_registry(dt, name = "invasive", icd10 = "^C", behaviour = 3L)
#> ✔ derive_cancer_registry (invasive): 6 cases, 6 with date.
```
