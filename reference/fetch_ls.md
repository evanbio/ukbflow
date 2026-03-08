# List files and folders at a remote RAP path

Returns a structured data.frame describing the contents of a remote
DNAnexus Research Analysis Platform (RAP) directory. Analogous to
`file_info()` but for remote project storage.

## Usage

``` r
fetch_ls(path = ".", type = "all", pattern = NULL)
```

## Arguments

- path:

  (character) Remote path to list. Default: `"."` (project root). Both
  `"Bulk/"` and `"/Bulk/"` are accepted.

- type:

  (character) Filter results by entry type: `"all"` (default), `"file"`,
  or `"folder"`.

- pattern:

  (character) Optional regex to filter by name, e.g. `"\.bed$"`.
  Default: `NULL`.

## Value

A data.frame with columns:

- name:

  Entry name (no trailing slash for folders).

- type:

  `"file"` or `"folder"`.

- size:

  File size string (e.g. `"120.94 GB"`), `NA` for folders or non-file
  objects.

- modified:

  Last modified time (`POSIXct`), `NA` for folders.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_ls()
fetch_ls("Showcase metadata/", type = "file")
fetch_ls("results/", pattern = "\\.csv$")
} # }
```
