# Check and export a GRS weights file

Reads a SNP weights file, validates its content, and writes a
plink2-compatible space-delimited output ready for upload to UKB RAP.

## Usage

``` r
grs_check(file, dest = "weights.txt")
```

## Arguments

- file:

  Character scalar. Path to the input weights file. Read via
  [`data.table::fread`](https://rdrr.io/pkg/data.table/man/fread.html)
  (format auto-detected; handles CSV, TSV, space-delimited, etc.).

- dest:

  Character scalar. Output path for the validated, space-delimited
  weights file. Default: `"weights.txt"`.

## Value

A `data.table` with columns `snp`, `effect_allele`, and `beta`, returned
invisibly.

## Details

The input file must contain at least the three columns below (additional
columns are ignored):

- `snp`:

  SNP identifier, expected in `rs` + digits format.

- `effect_allele`:

  Effect allele; must be one of A / T / C / G.

- `beta`:

  Effect size (log-OR or beta coefficient); must be numeric.

Checks performed:

- Required columns present.

- No `NA` values in the three required columns.

- No duplicate `snp` identifiers.

- `snp` matches `rs[0-9]+` pattern (warning if not).

- `effect_allele` contains only A / T / C / G (warning if not).

- `beta` is numeric (error if not).

## Examples

``` r
if (FALSE) { # \dontrun{
# Local
w <- grs_check("weights.csv", dest = "weights_clean.txt")

# On RAP (JupyterLab) - files accessed via /mnt/project/
w <- grs_check(
  file = "/mnt/project/weights/weights.csv",
  dest = "/mnt/project/weights/weights_clean.txt"
)
} # }
```
