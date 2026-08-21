# Derive a unified ICD-9 disease flag across multiple UKB data sources

The ICD-9 counterpart of
[`derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md).
A high-level wrapper that calls one or both of
[`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md)
and
[`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md)
according to the `source` argument, then combines their results into a
single status flag and earliest-date column. Only two sources are
offered here (vs. four for
[`derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)):
UK Biobank's death registry and First Occurrence fields are ICD-10-only,
with no ICD-9 counterpart.

## Usage

``` r
derive_icd9(
  data,
  name,
  icd9,
  source = c("hes", "cancer_registry"),
  match = c("prefix", "exact", "regex"),
  histology = NULL,
  behaviour = NULL,
  hes_position = c("any", "main"),
  hes_code_col = NULL,
  hes_date_cols = NULL,
  cr_code_cols = NULL,
  cr_hist_cols = NULL,
  cr_behv_cols = NULL,
  cr_date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix, e.g. `"disease"` produces
  `disease_icd9` and `disease_icd9_date`, plus intermediate columns such
  as `disease_hes_icd9`, `disease_hes_icd9_date`, etc.

- icd9:

  (character) ICD-9 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("331.0", "331.1")`. For `"regex"`, supply a
  single regex string. When `"cancer_registry"` is included in `source`,
  `icd9` and `match` are automatically converted to a regex and passed
  to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).

- source:

  (character) One or more of `"hes"`, `"cancer_registry"`. Defaults to
  both.

- match:

  (character) Matching strategy passed to
  [`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md):
  `"prefix"` (default), `"exact"`, or `"regex"`.

- histology:

  (integer vector or NULL) Passed to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).
  Ignored for other sources.

- behaviour:

  (integer vector or NULL) Passed to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).
  Ignored for other sources.

- hes_position:

  (character) Passed as `position` to
  [`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md):
  `"any"` (default) or `"main"` (primary diagnoses only).

- hes_code_col:

  (character or NULL) Passed as `disease_cols` to
  [`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md).

- hes_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_hes_icd9`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md).

- cr_code_cols:

  (character or NULL) Passed as `code_cols` to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).

- cr_hist_cols:

  (character or NULL) Passed as `hist_cols` to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).

- cr_behv_cols:

  (character or NULL) Passed as `behv_cols` to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).

- cr_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_cancer_registry_icd9`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md).

## Value

The input `data` (invisibly) with `{name}_icd9` (logical) and
`{name}_icd9_date` (IDate) added in-place, plus all intermediate source
columns. Always returns a `data.table`.

## Details

All intermediate source columns (`{name}_hes_icd9`, `{name}_cancer_icd9`
and their `_date` counterparts) are retained in `data` so that
per-source contributions remain traceable.

- `{name}_icd9`:

  Logical flag: `TRUE` if any selected source contains a matching
  record.

- `{name}_icd9_date`:

  Earliest matching date across all selected sources (`IDate`).

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_icd9(dt, name = "dem", icd9 = c("331.0", "290.4"))
#> ! derive_hes_icd9 (dem): 0 cases found.
#> ! derive_cancer_registry_icd9 (dem): 0 cases after filtering.
#> ✔ derive_icd9 (dem): 0 cases across 2 sources, 0 with date.
```
