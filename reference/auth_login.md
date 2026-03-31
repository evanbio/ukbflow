# Login to DNAnexus with a token

Authenticates with the DNAnexus Research Analysis Platform using an API
token. Equivalent to running `dx login --token` on the command line.

## Usage

``` r
auth_login(token = NULL)
```

## Arguments

- token:

  (character) DNAnexus API token. If NULL, reads from the environment
  variable `DX_API_TOKEN`.

## Value

Invisible TRUE on success.

## Examples

``` r
if (FALSE) { # \dontrun{
# Supply token directly
auth_login(token = "your_token_here")

# Or store token in ~/.Renviron (recommended):
# usethis::edit_r_environ()
# Add: DX_API_TOKEN=your_token_here
# Save and restart R, then call:
auth_login()
} # }
```
