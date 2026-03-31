# Handle informative missing labels in UKB decoded data

After
[`decode_values`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
converts categorical codes to character labels, some values represent
meaningful non-response rather than true data: `"Do not know"`,
`"Prefer not to answer"`, and `"Prefer not to say"`. This function
either converts them to `NA` (for complete-case analysis) or retains
them as `"Unknown"` (to preserve the informative missingness as a model
category).

## Usage

``` r
derive_missing(
  data,
  cols = tidyselect::everything(),
  action = c("na", "unknown"),
  extra_labels = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) Decoded UKB data, typically output of
  [`decode_values`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
  followed by
  [`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md).

- cols:

  (tidyselect) Columns to process. Default: `everything()` (all
  columns). Non-character columns in the selection are silently skipped.

- action:

  (character) One of `"na"` (default) or `"unknown"`.

  - `"na"`: convert all informative missing labels to `NA`.

  - `"unknown"`: convert informative missing labels to `"Unknown"`,
    preserving them as a distinct model category.

  Empty strings are always converted to `NA` regardless of this
  parameter.

- extra_labels:

  (character or NULL) Additional labels to treat as informative missing,
  appended to the built-in list. Default: `NULL`.

## Value

The input `data` with missing labels replaced in-place. Always returns a
`data.table`.

## Details

Empty strings (`""`) are always converted to `NA` regardless of
`action`, as they carry no informational content.

Only character columns are modified; numeric, integer, Date, and logical
columns are silently skipped.

**data.table pass-by-reference**: when the input is a `data.table`,
modifications are made in-place via
[`set`](https://rdrr.io/pkg/data.table/man/assign.html). The returned
object and the original variable point to the same memory. If you need
to preserve the original, pass `data.table::copy(data)` instead.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- extract_pheno(c(31, 20116, 2080)) |>
  decode_values() |>
  decode_names() |>
  derive_missing()                          # "Do not know" -> NA

# Retain informative non-response as a model category
df <- derive_missing(df, action = "unknown")  # "Prefer not to answer" -> "Unknown"

# Add a custom label
df <- derive_missing(df, extra_labels = "Not applicable")
} # }
```
