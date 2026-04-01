# Download the UKB field dictionary file

Downloads `field.tsv` from the `Showcase metadata/` folder on the
DNAnexus Research Analysis Platform. This file contains the complete UKB
data dictionary: field IDs, titles, value types, and encoding
references.

## Usage

``` r
fetch_field(dest_dir, overwrite = FALSE, resume = FALSE, verbose = TRUE)
```

## Arguments

- dest_dir:

  (character) Destination directory. Created automatically if it does
  not exist.

- overwrite:

  (logical) Overwrite existing local file. Default: `FALSE`.

- resume:

  (logical) Resume an interrupted download. Default: `FALSE`.

- verbose:

  (logical) Show download progress. Default: `TRUE`.

## Value

Invisibly returns the local file path as a character string.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_field(dest_dir = "metadata")
fetch_field(dest_dir = "metadata", overwrite = TRUE)
} # }
```
