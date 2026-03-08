# Rename UKB field ID columns to human-readable snake_case names

Renames columns from the raw UKB field ID format used by
[`extract_pheno`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
(e.g. `participant.p31`) and
[`job_result`](https://evanbio.github.io/ukbflow/reference/job_result.md)
(e.g. `p53_i0`) to human-readable snake_case identifiers (e.g. `sex`,
`date_of_attending_assessment_centre_i0`).

## Usage

``` r
decode_names(data, max_nchar = 60L)
```

## Arguments

- data:

  (data.frame or data.table) Data extracted from UKB-RAP via
  [`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
  or
  [`job_result()`](https://evanbio.github.io/ukbflow/reference/job_result.md).

- max_nchar:

  (integer) Column names longer than this value are flagged. Default:
  `60`.

## Value

The input `data` with column names replaced by snake_case labels.
Returns a `data.table` if the input is a `data.table`.

## Details

Column labels are taken from the UKB field title dictionary cached by
[`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md).
The cache is populated automatically when
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)
or
[`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
is called; if it is empty, `decode_names()` calls
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
itself.

When an auto-generated name exceeds `max_nchar` characters it is flagged
with a warning so you can decide whether to shorten it manually with
`names(data)[...] <- ...`. The function never truncates names
automatically, because the right short name depends on scientific
context that only you know.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- extract_pheno(c(31, 53, 21022))
df <- decode_names(df)
# participant.eid    → eid
# participant.p31    → sex
# participant.p21022 → age_at_recruitment
# participant.p53_i0 → date_of_attending_assessment_centre_i0  (warned if > 30)

# Shorten a long name afterwards
names(df)[names(df) == "date_of_attending_assessment_centre_i0"] <- "date_baseline"
} # }
```
