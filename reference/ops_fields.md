# Search approved UKB fields in the current project

Searches the field list returned by
[`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
and summarizes matching RAP columns at the UKB field-ID level. This is a
project-specific field-discovery helper: results reflect fields approved
and available in the active RAP dataset, not the full UK Biobank data
dictionary.

## Usage

``` r
ops_fields(
  pattern,
  dataset = NULL,
  refresh = FALSE,
  regex = FALSE,
  details = FALSE
)
```

## Arguments

- pattern:

  (character) Keyword string or regular expression to search. For
  keyword search, separate multiple required keywords with spaces, e.g.
  `"age recruitment"`.

- dataset:

  (character or NULL) Dataset file name, e.g.
  `"app12345_20260101.dataset"`. Default: `NULL` (auto-detect).

- refresh:

  (logical) Force re-fetch from cloud, ignoring the cached field list.
  Default: `FALSE`.

- regex:

  (logical) Interpret `pattern` as a regular expression. Default:
  `FALSE`.

- details:

  (logical) Return the raw matching RAP columns instead of the
  field-level summary. Default: `FALSE`.

## Value

A `data.table`. With `details = FALSE`, columns are: `field_id`,
`title`, `n_cols`, and `example_field_name`. With `details = TRUE`,
columns are: `field_id`, `field_name`, and `title`.

## Details

By default, `pattern` is treated as one or more case-insensitive
keywords that must all be present in either the RAP field name or the
field title. Set `regex = TRUE` to use `pattern` as a regular
expression.

## Examples

``` r
if (FALSE) { # \dontrun{
ops_fields("sex")
ops_fields("age recruitment")
ops_fields("p31|p53|p21022", regex = TRUE)
ops_fields("cancer", details = TRUE)
} # }
```
