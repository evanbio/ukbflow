# Calculate genetic risk scores from PGEN files on RAP

Uploads local SNP weight files to the RAP project root, then submits one
Swiss Army Knife job per GRS. Each job runs plink2 `--score` across all
22 chromosomes and saves a single CSV to `dest` on completion. Jobs run
in parallel; use
[`job_ls`](https://evanbio.github.io/ukbflow/reference/job_ls.md) to
monitor progress.

## Usage

``` r
grs_score(
  file,
  pgen_dir = NULL,
  dest = NULL,
  maf = 0.01,
  instance = "standard",
  priority = "low"
)
```

## Arguments

- file:

  Named character vector of local weight file paths. Names become the
  GRS identifiers (output column = `GRS_<name>`). Example:
  `c(grs_a = "weights_a.txt")`.

- pgen_dir:

  Character scalar. Path to PGEN files on RAP (e.g.
  `"/mnt/project/pgen"`). Must be specified explicitly.

- dest:

  Character scalar. RAP destination path for output CSV files (e.g.
  `"/grs/"`). Must be specified explicitly.

- maf:

  Numeric scalar. MAF filter threshold used when locating PGEN files.
  Must match the value used in
  [`grs_bgen2pgen`](https://evanbio.github.io/ukbflow/reference/grs_bgen2pgen.md).
  Default: `0.01`.

- instance:

  Character scalar. Instance type preset: `"standard"` or `"large"`.
  Default: `"standard"`.

- priority:

  Character scalar. Job priority: `"low"` or `"high"`. Default: `"low"`.

## Value

A named character vector of job IDs (one per GRS), returned invisibly.
Failed submissions are `NA`. Use
[`job_ls`](https://evanbio.github.io/ukbflow/reference/job_ls.md) to
monitor progress.

## Details

Weight files should have three columns (any delimiter, header required):

- Column 1:

  Variant ID (e.g. `rs` IDs).

- Column 2:

  Effect allele (A1).

- Column 3:

  Effect weight (beta / log-OR).

This matches the output format of
[`grs_check`](https://evanbio.github.io/ukbflow/reference/grs_check.md).

**Output per job:** `dest/<score_name>_scores.csv` with columns `IID`
and the GRS score (named `GRS_<name>`).

**Instance types:**

- `"standard"`:

  `mem2_ssd1_v2_x4`: 4 cores, 12 GB RAM.

- `"large"`:

  `mem2_ssd2_v2_x8`: 8 cores, 28 GB RAM.

## Examples

``` r
if (FALSE) { # \dontrun{
ids <- grs_score(
  file = c(
    grs_a = "weights/grs_a_weights.txt",
    grs_b = "weights/grs_b_weights.txt"
  ),
  pgen_dir = "/mnt/project/pgen",
  dest     = "/grs/",
  priority = "high"
)

job_ls()
} # }
```
