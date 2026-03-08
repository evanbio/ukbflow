# Derive a unified ICD-10 disease flag across multiple UKB data sources

A high-level wrapper that calls one or more of
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
[`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md),
[`derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md),
and
[`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
according to the `source` argument, then combines their results into a
single status flag and earliest-date column.

## Usage

``` r
derive_icd10(
  data,
  name,
  icd10,
  source = c("hes", "death", "first_occurrence", "cancer_registry"),
  match = c("prefix", "exact", "regex"),
  fo_field = NULL,
  fo_col = NULL,
  histology = NULL,
  behaviour = NULL,
  hes_code_col = NULL,
  hes_date_cols = NULL,
  primary_cols = NULL,
  secondary_cols = NULL,
  death_date_cols = NULL,
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

  (character) Output column prefix, e.g. `"ad"` produces `ad_icd10` and
  `ad_icd10_date`, plus intermediate columns such as `ad_hes`,
  `ad_hes_date`, etc.

- icd10:

  (character) ICD-10 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("L20", "L21")`. For `"regex"`, supply a
  single regex string. When `"cancer_registry"` is included in `source`,
  `icd10` and `match` are automatically converted to a regex and passed
  to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- source:

  (character) One or more of `"hes"`, `"death"`, `"first_occurrence"`,
  `"cancer_registry"`. Defaults to all four.

- match:

  (character) Matching strategy passed to `derive_hes` and
  `derive_death_registry`: `"prefix"` (default), `"exact"`, or
  `"regex"`.

- fo_field:

  (integer or character or NULL) UKB field ID for the First Occurrence
  column (e.g. `131720L` for AD). Required when `"first_occurrence"` is
  in `source` and `fo_col` is `NULL`.

- fo_col:

  (character or NULL) Column name of the First Occurrence field in
  `data`. Alternative to `fo_field`.

- histology:

  (integer vector or NULL) Passed to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).
  Ignored for other sources.

- behaviour:

  (integer vector or NULL) Passed to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).
  Ignored for other sources.

- hes_code_col:

  (character or NULL) Passed as `disease_cols` to
  [`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md).

- hes_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md).

- primary_cols:

  (character or NULL) Passed to
  [`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md).

- secondary_cols:

  (character or NULL) Passed to
  [`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md).

- death_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md).

- cr_code_cols:

  (character or NULL) Passed as `code_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- cr_hist_cols:

  (character or NULL) Passed as `hist_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- cr_behv_cols:

  (character or NULL) Passed as `behv_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- cr_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

## Value

The input `data` with `{name}_icd10` (logical) and `{name}_icd10_date`
(IDate) added in-place, plus all intermediate source columns. Always
returns a `data.table`.

## Details

All intermediate source columns (`{name}_hes`, `{name}_death`,
`{name}_fo`, `{name}_cancer` and their `_date` counterparts) are
retained in `data` so that per-source contributions remain traceable.

- `{name}_icd10`:

  Logical flag: `TRUE` if any selected source contains a matching
  record.

- `{name}_icd10_date`:

  Earliest matching date across all selected sources (`IDate`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Non-cancer disease: HES + death + First Occurrence
df <- derive_icd10(df, name = "disease", icd10 = "E11",
                   source   = c("hes", "death", "first_occurrence"),
                   fo_field = 131000L)

# COPD: HES + death only, exact 4-digit codes
df <- derive_icd10(df, name = "copd",
                   icd10  = c("J440", "J441"),
                   source = c("hes", "death"),
                   match  = "exact")

# Cancer outcome: HES + cancer registry + death
df <- derive_icd10(df, name = "cancer_outcome",
                   icd10  = "^C50",
                   match  = "regex",
                   source = c("hes", "death", "cancer_registry"))
} # }
```
