# List all approved fields in the UKB dataset

Returns a data.frame of all fields available for extraction in the
current UKB project dataset. Fields reflect what has been approved for
your project – not all UKB fields are present.

## Usage

``` r
extract_ls(dataset = NULL, pattern = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  (character) Dataset file name, e.g. `"app12345_20260101.dataset"`.
  Default: `NULL` (auto-detect). A name given here becomes the session
  dataset, so later calls that auto-detect use it instead of probing the
  project again.

- pattern:

  (character) Optional regex to filter results by `field_name` or
  `title`. Default: `NULL`.

- refresh:

  (logical) Force re-fetch from cloud, ignoring cache. Default: `FALSE`.

## Value

A data.frame with columns:

- field_name:

  Full field name as used in extraction, e.g. `"participant.p31"`,
  `"participant.p53_i0"`.

- title:

  Human-readable field description, e.g. `"Sex"`,
  `"Date of attending assessment centre | Instance 0"`.

Visibility depends on `pattern`. Without one the full table runs to tens
of thousands of rows, so it is returned **invisibly** and only a
one-line count is printed – assign it to a variable to use it. With a
`pattern` the filtered result is returned **visibly**, so an interactive
field search prints its matches directly.

## Details

Results are cached in the session after the first call. Subsequent calls
return instantly from cache. Use `refresh = TRUE` to force a new network
request (e.g. after switching projects).

## Examples

``` r
if (FALSE) { # \dontrun{
# List all approved fields
extract_ls()

# Search by keyword
extract_ls(pattern = "cancer")
extract_ls(pattern = "p31|p53|p22009")

# Force refresh after switching projects
extract_ls(refresh = TRUE)
} # }
```
