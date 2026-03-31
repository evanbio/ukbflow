# Define a self-reported phenotype from UKB touchscreen data

Searches UKB self-reported illness fields across all instances and
arrays, matches records against a user-supplied regex, parses the
associated year-month date, and appends two columns to the data:
`{name}_selfreport` (logical) and `{name}_selfreport_date` (`IDate`,
earliest matching instance).

## Usage

``` r
derive_selfreport(
  data,
  name,
  regex,
  field = c("noncancer", "cancer"),
  ignore_case = TRUE,
  disease_cols = NULL,
  date_cols = NULL,
  visit_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB data containing self-report fields.

- name:

  (character) Output column name prefix, e.g. `"disease"` or
  `"outcome"`.

- regex:

  (character) Regular expression matched against disease text values
  (after [`tolower()`](https://rdrr.io/r/base/chartr.html)), e.g.
  `"^diabetes$"`.

- field:

  (character) Self-report field type: `"noncancer"` (p20002 / p20008) or
  `"cancer"` (p20001 / p20006).

- ignore_case:

  (logical) Should regex matching ignore case? Default: `TRUE`.

- disease_cols:

  (character or NULL) Column name(s) containing disease text (p20002 or
  p20001). `NULL` = auto-detect via
  [`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
  cache.

- date_cols:

  (character or NULL) Column name(s) containing the self-report
  year-month date (p20008 or p20006). `NULL` = auto-detect.

- visit_cols:

  (character or NULL) Column name(s) containing the baseline assessment
  date (p53). `NULL` = auto-detect.

## Value

The input `data` with two new columns appended in-place:
`{name}_selfreport` (logical) and `{name}_selfreport_date` (IDate).
Always returns a `data.table`.

## Details

The function auto-detects the relevant columns using the
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
field dictionary cache (populated by
[`extract_ls()`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
or
[`extract_pheno()`](https://evanbio.github.io/ukbflow/reference/extract_pheno.md)).
The three `_cols` parameters let you override auto-detection when column
names have been customised (e.g. after
[`decode_names()`](https://evanbio.github.io/ukbflow/reference/decode_names.md)).

**Field mapping by `field`:**

- `"noncancer"`: disease text = p20002, date = p20008.

- `"cancer"`: disease text = p20001, date = p20006.

Baseline visit date (p53) is used as a fallback when no specific
diagnosis date is recorded.

**data.table pass-by-reference**: new columns are added in-place. Pass
`data.table::copy(data)` to preserve the original.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- extract_pheno(c(20002, 20008, 53)) |>
  derive_selfreport(name = "disease", regex = "your disease label",
                    field = "noncancer")

df <- derive_selfreport(df, name = "outcome",
                        regex = "your cancer label",
                        field = "cancer")
} # }
```
