# Decoding UKB Column Names and Values

## Overview

Raw UKB phenotype data contains encoded column names and values that
need to be converted before analysis.

| Source                                                                            | Column names      | Column values                                                                                                                    |
|-----------------------------------------------------------------------------------|-------------------|----------------------------------------------------------------------------------------------------------------------------------|
| [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md) | `participant.p31` | Raw integer codes — needs [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)                      |
| [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md) | `p31`, `p53_i0`   | Usually already decoded — [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md) typically not needed |

Both outputs need
[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
to convert field ID column names to human-readable snake_case.

> **Call order matters**: when using
> [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
> output, always run
> [`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
> before
> [`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md),
> because value decoding relies on the numeric field ID still being
> present in the column name.

------------------------------------------------------------------------

## Recommended Workflow

``` r
library(ukbflow)

df <- extract_pheno(c(31, 54, 20116, 21022))
df <- decode_values(df)   # 0/1 → "Female"/"Male", etc.
df <- decode_names(df)    # participant.p31 → sex
```

------------------------------------------------------------------------

## Step 1: Decode Values

[`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
converts raw integer codes to human-readable labels for categorical
fields that have UKB encoding mappings. Continuous, date, text, and
already-decoded fields are left unchanged.

``` r
df <- decode_values(df)
#> ✔ Decoded 3 categorical columns; 2 non-categorical columns unchanged.
```

It requires two metadata files from the UKB Showcase. Download them once
with:

``` r
fetch_metadata(dest_dir = "data/metadata")
```

Then point
[`decode_values()`](https://evanbio.github.io/ukbflow/reference/decode_values.md)
to the same directory (default matches
[`fetch_metadata()`](https://evanbio.github.io/ukbflow/reference/fetch_metadata.md)):

``` r
df <- decode_values(df, metadata_dir = "data/metadata")
```

### What gets decoded

| Column      | Raw value       | Decoded value                          |
|-------------|-----------------|----------------------------------------|
| `p31`       | `0` / `1`       | `"Female"` / `"Male"`                  |
| `p54`       | `11012`         | `"Leeds"`                              |
| `p20116_i0` | `0` / `1` / `2` | `"Never"` / `"Previous"` / `"Current"` |

Codes absent from the encoding table (including UKB missing codes `-1`,
`-3`, `-7`) are returned as `NA`.

------------------------------------------------------------------------

## Step 2: Decode Names

[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
renames columns from field ID format to snake_case labels using the
approved UKB field dictionary available to your project.

``` r
df <- decode_names(df)
#> ✔ Renamed 5 columns.
```

### Name conversion examples

| Raw name             | Decoded name                             |
|----------------------|------------------------------------------|
| `participant.eid`    | `eid`                                    |
| `participant.p31`    | `sex`                                    |
| `participant.p21022` | `age_at_recruitment`                     |
| `participant.p53_i0` | `date_of_attending_assessment_centre_i0` |
| `p31`                | `sex`                                    |
| `p53_i0`             | `date_of_attending_assessment_centre_i0` |

Both
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
format (`participant.p31`) and
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
format (`p31`) are handled automatically.

### Long names

Some UKB field titles are verbose. Names exceeding `max_nchar`
characters are flagged with a warning (default: 60). Lower the threshold
to catch more aggressively:

``` r
df <- decode_names(df, max_nchar = 30)
#> ! 1 column name longer than 30 characters - consider renaming manually:
#> • date_of_attending_assessment_centre_i0
```

Rename manually to something concise:

``` r
names(df)[names(df) == "date_of_attending_assessment_centre_i0"] <- "date_baseline"
```

------------------------------------------------------------------------

## Getting Help

- [`?decode_values`](https://evanbio.github.io/ukbflow/reference/decode_values.md),
  [`?decode_names`](https://evanbio.github.io/ukbflow/reference/decode_names.md)
- [`vignette("extract")`](https://evanbio.github.io/ukbflow/articles/extract.md)
  — extracting phenotype data
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
