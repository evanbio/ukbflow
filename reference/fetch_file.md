# Download a file from RAP project storage

Downloads one file or all files within a folder from RAP project storage
to the current directory or a specified destination within the RAP
environment. This function must be called from within RAP.

## Usage

``` r
fetch_file(path, dest_dir, overwrite = FALSE, resume = FALSE, verbose = TRUE)
```

## Arguments

- path:

  (character) Remote file or folder path.

- dest_dir:

  (character) Destination directory. Created automatically if it does
  not exist.

- overwrite:

  (logical) Overwrite existing local files. Default: `FALSE`.

- resume:

  (logical) Resume an interrupted download. Useful for large files (e.g.
  `.bed`, `.bgen`). Default: `FALSE`.

- verbose:

  (logical) Show download progress. Default: `TRUE`.

## Value

Invisibly returns the local file path(s) as a character vector.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download a single metadata file
fetch_file("Showcase metadata/field.tsv", dest_dir = "data/")

# Download an entire folder
fetch_file("Showcase metadata/", dest_dir = "data/metadata/")

# Resume an interrupted download
fetch_file("results/summary_stats.csv", dest_dir = "data/", resume = TRUE)
} # }
```
