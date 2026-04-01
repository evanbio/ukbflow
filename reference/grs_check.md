# Check and export a GRS weights file

Reads a SNP weights file, validates its content, and writes a
plink2-compatible space-delimited output ready for upload to UKB RAP.

## Usage

``` r
grs_check(file, dest = NULL)
```

## Arguments

- file:

  Character scalar. Path to the input weights file. Read via
  [`data.table::fread`](https://rdrr.io/pkg/data.table/man/fread.html)
  (format auto-detected; handles CSV, TSV, space-delimited, etc.).

- dest:

  Character scalar or `NULL`. Output path for the validated,
  space-delimited weights file. When `NULL` (default), no file is
  written and the validated `data.table` is returned invisibly only.

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
tmp_in <- tempfile(fileext = ".csv")
weights <- data.frame(
  snp           = c("rs1234567", "rs2345678", "rs3456789"),
  effect_allele = c("A", "T", "G"),
  beta          = c(0.12, -0.05, 0.23)
)
write.csv(weights, tmp_in, row.names = FALSE)

w <- grs_check(tmp_in)
#> Read /tmp/Rtmp2AYMzV/file23144f710207.csv: 3 rows, 3 columns.
#> ✔ No NA values.
#> ✔ No duplicate SNPs.
#> ✔ All SNP IDs match rs[0-9]+ format.
#> ✔ All effect alleles are A/T/C/G.
#> Beta summary:
#>   Range : -0.05 to 0.23
#>   Mean |beta|: 0.1333
#>   Positive : 2 (66.7%)
#>   Negative : 1 (33.3%)
#>   Zero : 0
#> ✔ Weights file passed checks: 3 SNPs ready for UKB RAP.
w
#>          snp effect_allele  beta
#>       <char>        <char> <num>
#> 1: rs1234567             A  0.12
#> 2: rs2345678             T -0.05
#> 3: rs3456789             G  0.23

# Save validated weights to a file
tmp_out <- tempfile(fileext = ".txt")
grs_check(tmp_in, dest = tmp_out)
#> Read /tmp/Rtmp2AYMzV/file23144f710207.csv: 3 rows, 3 columns.
#> ✔ No NA values.
#> ✔ No duplicate SNPs.
#> ✔ All SNP IDs match rs[0-9]+ format.
#> ✔ All effect alleles are A/T/C/G.
#> Beta summary:
#>   Range : -0.05 to 0.23
#>   Mean |beta|: 0.1333
#>   Positive : 2 (66.7%)
#>   Negative : 1 (33.3%)
#>   Zero : 0
#> ✔ Weights file passed checks: 3 SNPs ready for UKB RAP.
#> ✔ Saved: /tmp/Rtmp2AYMzV/file231478a1fc51.txt
```
