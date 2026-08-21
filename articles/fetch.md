# Exploring and Fetching RAP Files

## Overview

The `fetch_*` functions provide a convenient R interface for
**exploring** the files in your UK Biobank RAP project. Rather than
switching to the terminal and using `dx` commands directly, you can
browse your remote project structure — listing files and printing
directory trees — entirely within your R session.

> **UK Biobank Data Policy (2024+)**: Individual-level phenotype and
> genotype data must remain within the RAP environment and cannot be
> downloaded locally. These functions only **list** remote files; they
> do not move data off the platform.

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

## Getting Help

- [`?fetch_ls`](https://evanbio.github.io/ukbflow/reference/fetch_ls.md),
  [`?fetch_tree`](https://evanbio.github.io/ukbflow/reference/fetch_tree.md)
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
