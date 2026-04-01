# Logout from DNAnexus

Invalidates the current DNAnexus session on the remote platform. The
local token file is not removed but becomes invalid. A new token must be
generated from the DNAnexus platform before calling
[`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)
again.

## Usage

``` r
auth_logout()
```

## Value

Invisible TRUE on success.

## Examples

``` r
if (FALSE) { # \dontrun{
auth_logout()
} # }
```
