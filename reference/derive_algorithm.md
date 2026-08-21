# Derive a binary disease flag from UKB algorithmically-defined outcomes

UKB's Outcomes Adjudication Group pre-computes a small set of
*algorithmically-defined outcomes* (ADOs, Category 42, fields `p420xx`)
by combining baseline self-report, hospital admission records (HES), and
death registries into a validated case definition with an earliest event
date. Each outcome is a **pair** of fields: an even-numbered *Date*
field (e.g. `42018`, all-cause dementia) and an odd-numbered *Source*
field (e.g. `42019`) recording which dataset supplied the date. This
function reads the Date field, converts it to `IDate`, and writes two
analysis-ready columns:

## Usage

``` r
derive_algorithm(data, name, field, col = NULL)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix, e.g. `"dementia"` produces
  `dementia_alg` and `dementia_alg_date`.

- field:

  (integer or character) UKB field ID of the ADO *Date* field, e.g.
  `42018` for all-cause dementia.

- col:

  (character or NULL) Name of the source column in `data`. When `NULL`
  (default) the column is detected automatically from `field`.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_alg` (logical) and `{name}_alg_date` (IDate).

## Details

- `{name}_alg_date`:

  Earliest algorithmically-defined event date (`IDate`). Values that
  cannot be coerced to a valid date, and the `1900-01-01` sentinel (see
  below), are set to `NA`.

- `{name}_alg`:

  Logical flag derived from `{name}_alg_date`: `TRUE` if and only if a
  valid, non-sentinel date exists. This guarantees every positive case
  carries a usable date for time-to-event and prevalent/incident
  classification.

**The `1900-01-01` sentinel (why this is not
[`derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md))**:
per the UKB ADO documentation (Resource 460, *Algorithmically-defined
outcomes v2.0*), a "Self-reported only" case whose year of onset is
missing (UKB field `20008`) has its date set to `1900-01-01`. Unlike a
true error code, this parses to a valid date, so `as.IDate` alone would
silently admit it as a real 1900 event. `derive_algorithm()` therefore
filters `1900-01-01` to `NA` explicitly and reports how many rows were
affected. Following the package convention that a case must imply a
usable date, such rows become non-cases (`{name}_alg = FALSE`). Cases
sourced from HES or death registries always carry real dates and are
unaffected.

**A self-contained case definition (do not route through
[`derive_case`](https://evanbio.github.io/ukbflow/reference/derive_case.md))**:
an ADO already reconciles self-report, HES, and death internally, so
`{name}_alg` / `{name}_alg_date` *is* the final case definition. Feed
these columns straight into `assoc_*` (via `outcome_col` / `time_col`).
Do not combine an ADO with a separate
[`derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
for the same phenotype through
[`derive_case`](https://evanbio.github.io/ukbflow/reference/derive_case.md):
that double-counts self-report and lets `pmin` pull in a date the
adjudication algorithm deliberately excluded. Unlike the ICD-10 sources,
an ADO is not an argument to
[`derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md),
which matches ICD-10 codes.

**Column detection**: the source column is located automatically from
`field`, handling both the raw format used by
[`extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
and the snake_case format produced by
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md).
Supply `col` to override auto-detection.

**data.table pass-by-reference**: when the input is a `data.table`, new
columns are added in-place via `:=`.

## Examples

``` r
# p42018 = all-cause dementia ADO date. Rows stamped 1900-01-01 are
# self-report-only cases with an unknown onset year and become non-cases.
dt <- ops_toy(n = 200)
#> ✔ ops_toy: 200 participants | 107 columns | scenario = "cohort" | seed = 42
derive_algorithm(dt, name = "dementia", field = 42018L)
#> ✔ derive_algorithm (dementia): 33 cases with valid date.
#> ℹ   5 self-report-only records with unknown onset year (1900-01-01) set to NA (not counted as cases).
```
