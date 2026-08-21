# Decode UKB categorical column values using Showcase metadata

Converts raw integer codes produced by
[`extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
into human-readable labels for all categorical fields (`value_type` 21
and 22), using the UKB Showcase encoding tables. Continuous, text, date,
and already-decoded columns are left unchanged.

## Usage

``` r
decode_values(data, metadata_dir = "data/metadata/")
```

## Arguments

- data:

  (data.frame or data.table) Data from
  [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md),
  with column names in `participant.pXXXX` or `pXXXX_iX` format.

- metadata_dir:

  (character) Directory containing `field.tsv` and `esimpint.tsv`.
  Default: `"data/metadata/"`.

## Value

The input `data` with categorical columns replaced by character labels.
Returns a `data.table` if the input is a `data.table`.

## Details

This function requires two UKB Showcase encoding tables:

- `field.tsv` - maps field IDs to encoding IDs and value types.

- `esimpint.tsv` - maps encoding ID + integer code to label.

Both are UKB Showcase metadata files, available on the Research Analysis
Platform alongside your project data. Point `metadata_dir` at the
directory that holds them; the files are cached in the session after the
first read.

**Call order**: use `decode_values()` *before*
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md),
so that column names still contain the numeric field ID needed to look
up the encoding.

## Examples

``` r
if (FALSE) { # \dontrun{
# field.tsv / esimpint.tsv live in the Showcase metadata directory on RAP;
# point metadata_dir there (default "data/metadata/").

# Recommended call order
df <- extract_pheno(c(31, 54, 20116, 21000))
df <- decode_values(df)                  # 0/1 -> "Female"/"Male", etc.
df <- decode_names(df)                   # participant.p31 -> sex
} # }
```
