# Combine self-report and ICD-10 sources into a unified case definition

Takes the self-report flag and ICD-10 flag produced by
[`derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md)
and
[`derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)
(or any pair of logical columns) and merges them into a single logical
case status and earliest date.

## Usage

``` r
derive_case(
  data,
  name,
  icd10_col = NULL,
  selfreport_col = NULL,
  icd10_date_col = NULL,
  selfreport_date_col = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Column prefix used both to locate the default input
  columns and to name the output columns. Defaults: `{name}_icd10`,
  `{name}_selfreport`, `{name}_icd10_date`, `{name}_selfreport_date`.

- icd10_col:

  (character or NULL) Name of the ICD-10 status column. `NULL` =
  `paste0(name, "_icd10")`.

- selfreport_col:

  (character or NULL) Name of the self-report status column. `NULL` =
  `paste0(name, "_selfreport")`.

- icd10_date_col:

  (character or NULL) Name of the ICD-10 date column. `NULL` =
  `paste0(name, "_icd10_date")`.

- selfreport_date_col:

  (character or NULL) Name of the self-report date column. `NULL` =
  `paste0(name, "_selfreport_date")`.

## Value

The input `data` with two new columns added in-place: `{name}_status`
(logical) and `{name}_date` (IDate). Always returns a `data.table`.

## Details

- `{name}_status`:

  Logical: `TRUE` if positive in at least one source.

- `{name}_date`:

  Earliest diagnosis/report date across both sources (`IDate`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Default: looks for disease_icd10, disease_selfreport, and their date columns
df <- derive_case(df, name = "disease")

# Explicit column names
df <- derive_case(df, name = "disease",
                  icd10_col      = "disease_icd10",
                  selfreport_col = "disease_selfreport_noncancer")
} # }
```
