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

This function requires two metadata files downloaded from the UKB
Research Analysis Platform:

- `field.tsv` - maps field IDs to encoding IDs and value types.

- `esimpint.tsv` - maps encoding ID + integer code to label.

Download them once with:

    fetch_metadata(dest_dir = "data/metadata/")

Both files are cached in the session after the first read.

**Call order**: use `decode_values()` *before*
[`decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md),
so that column names still contain the numeric field ID needed to look
up the encoding.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download metadata once
fetch_metadata(dest_dir = "data/metadata/")

# Recommended call order
df <- extract_pheno(c(31, 54, 20116, 21000))
df <- decode_values(df)                  # 0/1 → "Female"/"Male", etc.
df <- decode_names(df)                   # participant.p31 → sex
} # }
```
