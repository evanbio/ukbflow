# Extracting Phenotype Data

## Overview

UKB phenotype data is stored in a proprietary `.dataset` format on the
RAP and cannot be read directly. The `extract_*` functions provide R
interfaces for discovering approved fields and extracting phenotype data
via the DNAnexus `dx extract_dataset` and `table-exporter` tools.

Two workflows are available:

| Function                                                                          | Mode        | Scale                                     | Output                    |
|-----------------------------------------------------------------------------------|-------------|-------------------------------------------|---------------------------|
| [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md) | Async job   | Large / production (typically 50+ fields) | job ID → CSV on RAP cloud |
| [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md) | Synchronous | Small (quick checks)                      | data.table in memory      |

**[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
is the recommended approach** for any serious analysis.
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
is provided for quick interactive inspection inside the RAP environment
only.

------------------------------------------------------------------------

## Prerequisites

Ensure you are authenticated and have selected your project:

``` r
library(ukbflow)

auth_login()
auth_select_project("project-XXXXXXXXXXXX")
```

------------------------------------------------------------------------

## Step 1: Browse Available Fields

Before extracting, use
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
to explore what fields are approved for your project:

``` r
# List all approved fields (cached after first call)
extract_ls()

# Search by keyword
extract_ls(pattern = "cancer")
extract_ls(pattern = "p31|p53|p21022")

# Force refresh after switching projects or datasets
extract_ls(refresh = TRUE)
```

The result is a data.frame with two columns:

| Column       | Example                                             |
|--------------|-----------------------------------------------------|
| `field_name` | `participant.p53_i0`                                |
| `title`      | `Date of attending assessment centre \| Instance 0` |

> Fields reflect your project’s approved data only — not all UKB fields
> are present.

------------------------------------------------------------------------

## Step 2: Extract Data

### Recommended: `extract_batch()`

For large-scale or production extractions, submit an asynchronous
table-exporter job on the RAP cloud:

``` r
# Submit extraction job
job_id <- extract_batch(c(31, 53, 21022, 22189))

# Custom output name
job_id <- extract_batch(
  field_id = c(31, 53, 21022, 22189),
  file     = "ukb_demographics"
)

# High priority (faster queue, higher cost)
job_id <- extract_batch(
  field_id = c(31, 53, 21022, 22189),
  priority = "high"
)
```

The job runs asynchronously on the RAP cloud. The output CSV is saved to
your RAP project and can be monitored with the `job_` series:

``` r
job_status(job_id)        # check progress
job_path(job_id)          # get cloud file path once complete
job_result(job_id)        # read result as data.table (inside RAP only)
```

#### Instance type

[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
automatically selects an appropriate instance based on the number of
columns:

| Columns | Instance           |
|---------|--------------------|
| ≤ 20    | `mem1_ssd1_v2_x4`  |
| ≤ 100   | `mem1_ssd1_v2_x8`  |
| ≤ 500   | `mem1_ssd1_v2_x16` |
| \> 500  | `mem1_ssd1_v2_x36` |

You can override this with the `instance_type` argument if needed.

------------------------------------------------------------------------

### Quick inspection: `extract_pheno()`

For small-scale interactive checks **inside the RAP RStudio
environment**:

``` r
df <- extract_pheno(c(31, 53, 21022))
```

> [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
> is restricted to the RAP environment and returns data in memory only.
> For any analysis intended to be saved or reproduced, use
> [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md).

Note:
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
returns **raw coded values** (e.g. `1`/`0` for Sex, numeric codes for
diseases). Use the `decode_*` series to convert codes to human-readable
labels.

------------------------------------------------------------------------

## A Note on Column Names

Column naming differs between the two extraction methods:

**[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)**
— no prefix:

| Column         | Meaning                          |
|----------------|----------------------------------|
| `eid`          | Participant ID                   |
| `p31`          | Field 31 (Sex)                   |
| `p53_i0`       | Field 53, Instance 0             |
| `p20002_i0_a0` | Field 20002, Instance 0, Array 0 |

**[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)**
— `participant.` prefix:

| Column                     | Meaning                          |
|----------------------------|----------------------------------|
| `participant.eid`          | Participant ID                   |
| `participant.p31`          | Field 31 (Sex)                   |
| `participant.p53_i0`       | Field 53, Instance 0             |
| `participant.p20002_i0_a0` | Field 20002, Instance 0, Array 0 |

------------------------------------------------------------------------

## Getting Help

- [`?extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md),
  [`?extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md),
  [`?extract_batch`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
- [`vignette("auth")`](https://evanbio.github.io/ukbflow/articles/auth.md)
  — authentication setup
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
