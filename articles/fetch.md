# Exploring and Fetching RAP Files

## Overview

The `fetch_*` functions provide a convenient R interface for exploring
and downloading files from your UK Biobank RAP project. Rather than
switching to the terminal and using `dx` commands directly, you can
browse your remote project structure and retrieve files entirely within
your R session.

> **UK Biobank Data Policy (2024+)**: Only summary-level outputs and
> metadata files may be downloaded locally. Individual-level phenotype
> and genotype data must remain within the RAP environment.

------------------------------------------------------------------------

## Prerequisites

Ensure you are authenticated before using any `fetch_*` functions:

``` r
library(ukbflow)

auth_login()
auth_select_project("project-XXXXXXXXXXXX")
```

See
[`vignette("auth")`](https://evanbio.github.io/ukbflow/articles/auth.md)
for details.

------------------------------------------------------------------------

## Exploring Remote Files

### List files and folders

[`fetch_ls()`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md)
lists the contents of a remote RAP directory, returning a structured
data frame:

``` r
# List project root
fetch_ls()
#>                  name   type    size            modified
#> 1  Showcase metadata folder    <NA>                <NA>
#> 2             results folder    <NA>                <NA>
#> 3        analysis.log   file  4.2 KB 2024-11-01 10:22:03

# List a specific folder
fetch_ls("Showcase metadata/")
#>          name  type     size            modified
#> 1   field.tsv  file  12.3 MB 2024-10-15 08:01:44
#> 2 esimpint.tsv  file   3.1 MB 2024-10-15 08:01:50

# Filter by type
fetch_ls("results/", type = "file")

# Filter by name pattern
fetch_ls("results/", pattern = "\\.csv$")
```

The returned data frame has four columns:

| Column     | Description                                      |
|------------|--------------------------------------------------|
| `name`     | File or folder name                              |
| `type`     | `"file"` or `"folder"`                           |
| `size`     | File size (e.g. `"1.2 MB"`), `NA` for folders    |
| `modified` | Last modified time (`POSIXct`), `NA` for folders |

### Browse the directory tree

[`fetch_tree()`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)
prints a tree-like view of the remote project structure:

``` r
# Top-level overview
fetch_tree()

# Drill into a subfolder
fetch_tree("results/", max_depth = 2)
```

> **Note**: Each level of recursion triggers one API call per folder.
> Keep `max_depth` at 2–3 for interactive use to avoid long waits on
> large projects.

------------------------------------------------------------------------

## Generating Download URLs

[`fetch_url()`](https://evanbio.github.io/ukbflow/reference/fetch_url.md)
generates temporary pre-authenticated HTTPS URLs for remote files.
Useful for passing to downstream tools or scripting metadata and results
workflows without triggering a full download.

``` r
# Single file
fetch_url("Showcase metadata/field.tsv")

# Entire folder (returns a named character vector)
fetch_url("Showcase metadata/", duration = "7d")
```

URLs are valid for the specified `duration` (default: `"1d"`).

------------------------------------------------------------------------

## Downloading Files

### Single file or folder

[`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md)
downloads a file or an entire folder to the current or a specified
directory within the RAP environment.

> **Note**:
> [`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md),
> [`fetch_metadata()`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md),
> and
> [`fetch_field()`](https://evanbio.github.io/ukbflow/reference/fetch_field.md)
> can only be called from within the RAP environment. Calling them
> locally will produce an error, as individual-level UKB data must
> remain on the platform.

``` r
# Download a single file
fetch_file("Showcase metadata/field.tsv", dest_dir = "data/")

# Download an entire folder
fetch_file("Showcase metadata/", dest_dir = "data/metadata/")

# Resume an interrupted download
fetch_file("results/summary_stats.csv", dest_dir = "data/", resume = TRUE)
```

Folders are downloaded in parallel using
[`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html)
for efficiency.

### Metadata shortcuts

Two convenience wrappers are provided for commonly used UKB files:

``` r
# Download all Showcase metadata files (field.tsv, encoding.tsv, etc.)
fetch_metadata(dest_dir = "data/metadata")

# Download the field dictionary only
fetch_field(dest_dir = "data/metadata")
```

------------------------------------------------------------------------

## Common Options

[`fetch_metadata()`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md)
and
[`fetch_field()`](https://evanbio.github.io/ukbflow/reference/fetch_field.md)
are thin wrappers around
[`fetch_file()`](https://evanbio.github.io/ukbflow/reference/fetch_file.md),
so all three share the same download-control arguments:

| Argument    | Default | Description                                                              |
|-------------|---------|--------------------------------------------------------------------------|
| `dest_dir`  | —       | Destination directory (created if needed). Must be specified explicitly. |
| `overwrite` | `FALSE` | Overwrite existing local files                                           |
| `resume`    | `FALSE` | Resume an interrupted download                                           |
| `verbose`   | `TRUE`  | Show download progress                                                   |

------------------------------------------------------------------------

## Getting Help

- [`?fetch_ls`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md),
  [`?fetch_tree`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md),
  [`?fetch_url`](https://evanbio.github.io/ukbflow/reference/fetch_url.md),
  [`?fetch_file`](https://evanbio.github.io/ukbflow/reference/fetch_file.md),
  [`?fetch_metadata`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md),
  [`?fetch_field`](https://evanbio.github.io/ukbflow/reference/fetch_field.md)
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
