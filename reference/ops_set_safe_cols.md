# Register additional safe columns protected from snapshot-based drops

Adds column names to the session-level safe list. Columns in this list
are automatically excluded when
[`ops_snapshot_cols`](https://evanbio.github.io/ukbflow/reference/ops_snapshot_cols.md)
is used to build a drop vector, in addition to the built-in protected
columns (`"eid"`, `"sex"`, `"age"`, `"age_at_recruitment"`).

## Usage

``` r
ops_set_safe_cols(cols = NULL, reset = FALSE)
```

## Arguments

- cols:

  (character) One or more column names to protect.

- reset:

  (logical) If `TRUE`, clear the current user-registered safe list
  before adding. Default `FALSE`.

## Value

Invisibly returns the updated safe cols vector.

## Examples

``` r
if (FALSE) { # \dontrun{
ops_set_safe_cols(c("date_baseline", "townsend_index"))
ops_set_safe_cols(reset = TRUE)  # clear user-registered safe cols
} # }
```
