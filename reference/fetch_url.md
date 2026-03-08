# Get pre-authenticated download URL(s) for a remote RAP file or folder

Generates temporary HTTPS URLs for files on the DNAnexus Research
Analysis Platform. For a single file, returns one URL. For a folder,
lists all files inside and returns a named character vector of URLs.

## Usage

``` r
fetch_url(path, duration = "1d")
```

## Arguments

- path:

  (character) Remote file path or folder path, e.g.
  `"Showcase metadata/field.tsv"` or `"Showcase metadata/"`.

- duration:

  (character) How long the URLs remain valid. Accepts suffixes: `s`,
  `m`, `h`, `d`, `w`, `M`, `y`. Default: `"1d"` (one day).

## Value

A named character vector of pre-authenticated HTTPS URLs. Names are the
file names.

## Examples

``` r
if (FALSE) { # \dontrun{
# Single file
fetch_url("Showcase metadata/field.tsv")

# Entire folder
fetch_url("Showcase metadata/", duration = "7d")
} # }
```
