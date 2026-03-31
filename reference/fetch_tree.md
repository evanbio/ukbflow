# Print a remote RAP directory tree

Displays the remote directory structure in a tree-like format by
recursively listing sub-folders up to `max_depth`. Analogous to
`file_tree()` but for remote project storage.

## Usage

``` r
fetch_tree(path = ".", max_depth = 2, verbose = TRUE)
```

## Arguments

- path:

  (character) Remote root path. Default: `"."` (project root). Both
  `"Bulk/"` and `"/Bulk/"` are accepted.

- max_depth:

  (integer) Maximum recursion depth. Default: `2`.

- verbose:

  (logical) Whether to print the tree to the console. Default: `TRUE`.

## Value

Invisibly returns a character vector of tree lines.

## Warning

Each level of recursion triggers one HTTPS API call per folder. Deep
trees (e.g. `max_depth > 3`) on large UKB projects may issue 100+
network requests, causing the console to hang for tens of seconds or
time out. Keep `max_depth` at 2-3 for interactive use.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_tree()
fetch_tree("Bulk/", max_depth = 3)
fetch_tree(verbose = FALSE)
} # }
```
