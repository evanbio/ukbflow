# Authentication and Project Setup

## Overview

`ukbflow` interacts with the UK Biobank Research Analysis Platform (RAP)
via the DNAnexus `dx` toolkit. Authentication is required to access your
UKB project, submit jobs, and retrieve results.

Two working modes are supported:

- **Local → RAP**: Run R locally, authenticate with a DNAnexus API
  token, and interact with RAP remotely.
- **RAP → RAP**: Run R inside the RAP cloud environment (e.g., RStudio
  on DNAnexus), where authentication is handled automatically by the
  platform.

------------------------------------------------------------------------

## Obtaining an API Token

1.  Log in to the [DNAnexus platform](https://platform.dnanexus.com)
2.  Go to **Account Settings \> API Tokens**
3.  Click **New Token**, set an appropriate expiry, and copy the token

> Keep your token private. Treat it like a password — do not share it or
> commit it to version control.

------------------------------------------------------------------------

## Storing Your Token Securely

The recommended approach is to store your token in `~/.Renviron`, a
local file that is never committed to git. This keeps the token out of
your scripts entirely.

``` r
usethis::edit_r_environ()
# Add the following line, then save and restart R:
# DX_API_TOKEN=your_token_here
```

After restarting R, the token is available to
[`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)
automatically.

------------------------------------------------------------------------

## Logging In

### Local → RAP

``` r
library(ukbflow)

auth_login()  # reads DX_API_TOKEN from environment
```

The token is cached locally by the dx toolkit and persists across R
sessions. In most local workflows, **you only need to log in once** —
subsequent R sessions usually do not require re-authentication unless
the token expires, the local dx session is cleared, or you explicitly
log out.

If you prefer to pass the token directly (e.g., in an interactive
session), you can do so:

``` r
auth_login("your_token_here")
```

> **Security note**: Avoid saving `auth_login("token")` calls in script
> files. Prefer the `.Renviron` approach for any workflow you intend to
> save or share.

### RAP → RAP

When running inside the RAP RStudio environment, authentication is
handled automatically by the platform. No login step is required:

``` r
library(ukbflow)

auth_status()  # verify the current session
```

------------------------------------------------------------------------

## Checking Authentication Status

``` r
auth_status()
#> • User:    "user-XXXXXXXXXXXX"
#> • Project: "project-XXXXXXXXXXXX"
```

[`auth_status()`](https://evanbio.github.io/ukbflow/reference/auth_status.md)
returns the current user and active project. Use this to confirm your
session before running any analysis.

------------------------------------------------------------------------

## Listing Available Projects

``` r
auth_list_projects()
#> project-XXXXXXXXXXXX : My UKB Project (CONTRIBUTOR)
#> project-YYYYYYYYYYYY : Shared Analysis Project (VIEW)
```

This returns all RAP projects accessible to your account, along with
their project IDs. Project IDs take the form `project-XXXXXXXXXXXX` and
are required for
[`auth_select_project()`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md).

------------------------------------------------------------------------

## Selecting a Project

``` r
auth_select_project("project-XXXXXXXXXXXX")
#> ✔ Project selected: "project-XXXXXXXXXXXX"
```

`ukbflow` uses project IDs rather than names to avoid ambiguity. Use
[`auth_list_projects()`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md)
to find the correct ID first.

Once selected, the project context is saved by the dx toolkit and
persists across sessions.

------------------------------------------------------------------------

## Logging Out

``` r
auth_logout()
#> ✔ Logged out from DNAnexus.
```

Logging out invalidates the current DNAnexus session on the remote
platform. The local token file is not removed but becomes invalid. A new
token must be generated from the DNAnexus platform before logging in
again.

------------------------------------------------------------------------

## Token Expiry

DNAnexus API tokens have a limited validity period set at creation time.
When a token expires:

- [`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)
  or other dx-dependent functions will fail
- Generate a new token from the DNAnexus platform and log in again:

``` r
auth_login("your_new_token_here")
```

Or update `~/.Renviron` with the new token and call
[`auth_login()`](https://evanbio.github.io/ukbflow/reference/auth_login.md)
without arguments.

------------------------------------------------------------------------

## Full Local → RAP Workflow

``` r
library(ukbflow)

auth_login()                                 # authenticate
auth_status()                                # verify session
auth_list_projects()                         # find your project ID
auth_select_project("project-XXXXXXXXXXXX")  # set active project

# ... run your analysis ...

auth_logout()                                # optional: clear session
```

------------------------------------------------------------------------

## Getting Help

- [`?auth_login`](https://evanbio.github.io/ukbflow/reference/auth_login.md),
  [`?auth_status`](https://evanbio.github.io/ukbflow/reference/auth_status.md),
  [`?auth_list_projects`](https://evanbio.github.io/ukbflow/reference/auth_list_projects.md),
  [`?auth_select_project`](https://evanbio.github.io/ukbflow/reference/auth_select_project.md),
  [`?auth_logout`](https://evanbio.github.io/ukbflow/reference/auth_logout.md)
- [DNAnexus documentation](https://documentation.dnanexus.com)
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
