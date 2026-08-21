# List available DNAnexus projects

Returns a list of all projects accessible to the current user.

## Usage

``` r
auth_list_projects()
```

## Value

Invisibly, a character vector of project names and IDs, one entry per
project. The same list is printed to the console. Returns an empty
character vector when no projects are accessible.

## Examples

``` r
if (FALSE) { # \dontrun{
auth_list_projects()
} # }
```
