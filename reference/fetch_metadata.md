# Download the Showcase metadata folder

Downloads the entire `Showcase metadata/` folder from the DNAnexus
Research Analysis Platform to a local directory. This includes
`field.tsv`, `encoding.tsv`, and all associated encoding tables.

## Usage

``` r
fetch_metadata(dest_dir, overwrite = FALSE, resume = FALSE, verbose = TRUE)
```

## Arguments

- dest_dir:

  (character) Destination directory. Created automatically if it does
  not exist.

- overwrite:

  (logical) Overwrite existing local files. Default: `FALSE`.

- resume:

  (logical) Resume interrupted downloads. Default: `FALSE`.

- verbose:

  (logical) Show download progress. Default: `TRUE`.

## Value

Invisibly returns the local file paths as a character vector.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_metadata(dest_dir = "metadata")
fetch_metadata(dest_dir = "metadata", overwrite = TRUE)
} # }
```
