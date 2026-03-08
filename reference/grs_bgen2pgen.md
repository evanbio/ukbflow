# Convert UKB imputed BGEN files to PGEN on RAP

Submits one Swiss Army Knife job per chromosome to the DNAnexus Research
Analysis Platform, each converting a UKB imputed BGEN file to PGEN
format with a MAF \> 0.01 filter applied via plink2. Jobs run in
parallel across chromosomes.

## Usage

``` r
grs_bgen2pgen(
  chr = 1:22,
  dest = "/pgen/",
  maf = 0.01,
  instance = "standard",
  priority = "low"
)
```

## Arguments

- chr:

  Integer vector. Chromosomes to process. Default: `1:22`.

- dest:

  Character scalar. RAP destination path for output PGEN files. Default:
  `"/pgen/"`.

- maf:

  Numeric scalar. Minor allele frequency filter passed to plink2
  `--maf`. Variants with MAF below this threshold are excluded. Default:
  `0.01`. Must be in `(0, 0.5)`.

- instance:

  Character scalar. Instance type preset: `"standard"` or `"large"`. See
  Details. Default: `"standard"`.

- priority:

  Character scalar. Job priority: `"low"` or `"high"`. Default: `"low"`.

## Value

A character vector of job IDs (one per chromosome), returned invisibly.
Failed submissions are `NA`. Use
[`job_ls`](https://evanbio.github.io/ukbflow/reference/job_ls.md),
[`job_status`](https://evanbio.github.io/ukbflow/reference/job_status.md),
or [`job_wait`](https://evanbio.github.io/ukbflow/reference/job_wait.md)
to monitor progress.

## Details

The function auto-generates the plink2 driver script, uploads it once to
the RAP project root (`/`) on RAP, then loops over `chr` submitting one
job per chromosome. A 500 ms pause between submissions prevents API
rate-limiting.

**Output path is critical.** The driver script writes plink2 output to
`/home/dnanexus/out/out/` - the fixed path that Swiss Army Knife
auto-uploads to `dest` on completion. Output files per chromosome:
`chr{N}_maf001.pgen/.pvar/.psam/.log`.

**Instance types:**

- `"standard"`:

  `mem2_ssd1_v2_x4`: 4 cores, 12 GB RAM. Suitable for smaller
  chromosomes (roughly chr 15–22).

- `"large"`:

  `mem2_ssd2_v2_x8`: 8 cores, 28 GB RAM, 640 GB SSD. Required for large
  chromosomes (roughly chr 1–14) where standard storage is insufficient.

## Examples

``` r
if (FALSE) { # \dontrun{
# Test with chr22 first (smallest chromosome)
ids <- grs_bgen2pgen(chr = 22, priority = "high")

# Small chromosomes - standard instance
ids_small <- grs_bgen2pgen(chr = 15:22)

# Large chromosomes - upgrade instance to handle storage
ids_large <- grs_bgen2pgen(chr = 1:14, instance = "large")

# Monitor
job_ls()
} # }
```
