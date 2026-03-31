# Download a remote RAP file or folder to local disk

Downloads one file or all files within a folder from the DNAnexus
Research Analysis Platform. Single files are downloaded sequentially;
folders are downloaded in parallel using
[`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html).

## Usage

``` r
fetch_file(
  path,
  dest_dir = ".",
  overwrite = FALSE,
  resume = FALSE,
  verbose = TRUE
)
```

## Arguments

- path:

  (character) Remote file or folder path.

- dest_dir:

  (character) Local destination directory. Created automatically if it
  does not exist. Default: `"."`.

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
