# Installation Guide

## Overview

`ukbflow` is an R package for UK Biobank data analysis and
visualization, designed to work natively with the [UK Biobank Research
Analysis Platform (RAP)](https://ukbiobank.dnanexus.com). It supports
two working modes:

- **Local → RAP**: Run R locally, authenticate with DNAnexus, submit
  jobs, and download summary results.
- **RAP → RAP**: Run R directly inside the RAP cloud environment, where
  authentication is handled automatically.

> **UK Biobank Data Policy (2024+)**: Individual-level phenotype and
> genotype data must remain within the RAP environment and cannot be
> downloaded locally. Only summary-level outputs (aggregated statistics,
> plots, reports) may be exported.

------------------------------------------------------------------------

## Quick Install

### From GitHub

``` r
# Using remotes
install.packages("remotes")
remotes::install_github("evanbio/ukbflow")

# Using pak (faster, recommended)
install.packages("pak")
pak::pkg_install("evanbio/ukbflow")
```

### From CRAN *(coming soon)*

``` r
# CRAN submission planned after GitHub MVP is stable
# install.packages("ukbflow")
```

------------------------------------------------------------------------

## System Requirements

- **R Version**: \>= 4.1.0
- **Operating Systems**: Windows, macOS, Linux
- **dxpy**: Required for local → RAP authentication and job submission
  (see below)
- **RAP Account**: A valid UK Biobank RAP account and API token

------------------------------------------------------------------------

## Dependencies

`ukbflow` dependencies are installed automatically with the package.

### Core Dependencies

- **data.table** — Fast in-memory data processing
- **cli** — Progress messages and user feedback
- **processx** — Reliable system command execution with robust error
  handling (used by auth and job functions)
- **jsonlite** — JSON parsing for RAP API responses
- **curl** — File downloads

### Analysis Dependencies

- **gtsummary** — Table 1 generation
- **gt** — Publication-quality table rendering
- **survival** — Survival analysis
- **dplyr** / **tidyselect** / **rlang** — Data manipulation

### Visualization Dependencies

- **forestploter** — Forest plot generation

------------------------------------------------------------------------

## Install dxpy (Local Mode Only)

The `auth_*` and `job_*` functions rely on the `dx` command-line tool
from [dxpy](https://documentation.dnanexus.com/downloads). Required only
when running locally.

``` bash
pip install dxpy
```

Verify:

``` bash
dx --version
```

> Skip this step if you are running entirely within the RAP RStudio
> environment.

------------------------------------------------------------------------

## Authentication Setup

### Local → RAP

Obtain your API token from the DNAnexus platform under **Account
Settings \> API Tokens**. Store it in your `.Renviron` file (never in
your script):

``` r
usethis::edit_r_environ()
# Add the following line, then save and restart R:
# DX_API_TOKEN=your_token_here
```

Then authenticate:

``` r
library(ukbflow)

auth_login()                                 # reads DX_API_TOKEN automatically
auth_status()                                # confirm user and active project
auth_list_projects()                         # find your project ID
auth_select_project("project-XXXXXXXXXXXX")  # switch to your UKB project
```

> For full details on token management, project selection, and both
> authentication modes, see
> [`vignette("auth")`](https://evanbio.github.io/ukbflow/articles/auth.md).

### RAP → RAP

Authentication is automatic inside the RAP environment. Verify the
session with:

``` r
library(ukbflow)

auth_status()  # confirms user and active project
```

------------------------------------------------------------------------

## Verify Installation

``` r
library(ukbflow)

packageVersion("ukbflow")
#> [1] '0.3.0'
```

------------------------------------------------------------------------

## Update ukbflow

### From GitHub

``` r
remotes::install_github("evanbio/ukbflow", force = TRUE)
```

### From CRAN *(once available)*

``` r
update.packages("ukbflow")
```

------------------------------------------------------------------------

## Troubleshooting

### `dx` not found

**Solution**: Ensure dxpy is installed and on your PATH:

``` bash
pip install dxpy
which dx   # macOS/Linux
where dx   # Windows
```

### Token expired or session lost

DNAnexus API tokens have a limited validity period. If authentication
fails, generate a new token from the DNAnexus platform and log in again:

``` r
auth_login("your_new_token_here")
```

### Installation fails on Windows

**Solution**: Install
[Rtools](https://cran.r-project.org/bin/windows/Rtools/) for packages
that require compilation.

### Network / Firewall issues

**Solution**: Configure a proxy before installing:

``` r
Sys.setenv(http_proxy  = "http://your-proxy:port")
Sys.setenv(https_proxy = "https://your-proxy:port")
```

------------------------------------------------------------------------

## Uninstall

``` r
remove.packages("ukbflow")
```

------------------------------------------------------------------------

## Getting Help

- **Documentation**: <https://evanbio.github.io/ukbflow/>
- **Issues**: [GitHub Issues](https://github.com/evanbio/ukbflow/issues)

------------------------------------------------------------------------

## Next Steps

After installation:

1.  Read the [Getting
    Started](https://evanbio.github.io/ukbflow/articles/get-started.md)
    guide
2.  Browse the [Function
    Reference](https://evanbio.github.io/ukbflow/reference/)
