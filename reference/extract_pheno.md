# Extract phenotype data from a UKB dataset

Extracts phenotypic fields from the UKB Research Analysis Platform
dataset and returns a `data.table`. All instances and arrays are
returned for each requested field. Column names are kept as-is (e.g.
`participant.p53_i0`); use the `clean_` series for renaming.

## Usage

``` r
extract_pheno(field_id, dataset = NULL, timeout = 300)
```

## Arguments

- field_id:

  (integer) Vector of UKB Field IDs to extract, e.g. `c(31, 53, 22189)`.
  `eid` is always included automatically.

- dataset:

  (character) Dataset file name. Default: `NULL` (auto-detect from
  project root).

- timeout:

  (integer) Extraction timeout in seconds. Default: `300`.

## Value

A `data.table` with one row per participant. Column names follow the
`participant.p<id>_i<n>_a<m>` convention. Fields not found are skipped
with a warning.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- extract_pheno(c(31, 53, 21022))
df <- extract_pheno(c(31, 53, 20002), dataset = "app12345_20260101.dataset")
} # }
```
