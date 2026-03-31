# Derive a binary disease flag from UKB First Occurrence fields

UKB pre-computes the earliest recorded date for hundreds of ICD-10
chapters and categories as *First Occurrence* fields (`p131xxx`). Each
field contains a single date per participant; no array or instance depth
is involved. This function reads that date, converts it to `IDate`, and
writes two analysis-ready columns:

## Usage

``` r
derive_first_occurrence(data, name, field, col = NULL)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix, e.g. `"disease"` produces
  `disease_fo` and `disease_fo_date`.

- field:

  (integer or character) UKB field ID of the First Occurrence field,
  e.g. `131666` for E11 (type 2 diabetes).

- col:

  (character or NULL) Name of the source column in `data`. When `NULL`
  (default) the column is detected automatically from `field`.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_fo` (logical) and `{name}_fo_date` (IDate).

## Details

- `{name}_fo_date`:

  Earliest First Occurrence date (`IDate`). Values that cannot be
  coerced to a valid date (e.g. UKB error codes) are silently set to
  `NA`.

- `{name}_fo`:

  Logical flag derived from `{name}_fo_date`: `TRUE` if and only if a
  valid date exists. This guarantees that every positive case has a
  usable date - essential for time-to-event and prevalent/incident
  classification.

**Column detection**: the function locates the source column
automatically from `field`, handling both the raw format used by
[`extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
(`participant.p131666`) and the snake_case format produced by
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
(`date_e11_first_reported_type_2_diabetes`). Supply `col` to override
auto-detection.

**data.table pass-by-reference**: when the input is a `data.table`, new
columns are added in-place via `:=`. The returned object and the
original variable point to the same memory.

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
derive_first_occurrence(dt, name = "outcome", field = 131742L, col = "p131742")
#> ✔ derive_first_occurrence (outcome): 5 cases with valid date.
```
