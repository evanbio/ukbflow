# Record UKB field IDs used for extraction

Appends one extraction record to a
[`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md)
object. The function records the declared UKB field IDs, optional
dataset name, optional label, number of fields, and timestamp. It does
not validate field availability against RAP; use
[`ops_fields`](https://evanbio.github.io/ukbflow/reference/ops_fields.md)
or
[`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
separately for project-specific field discovery.

## Usage

``` r
audit_fields(audit, field_id, dataset = NULL, label = NULL)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- field_id:

  (integer) UKB field IDs used for extraction.

- dataset:

  (character or NULL) Optional RAP dataset file name. Default: `NULL`.

- label:

  (character or NULL) Optional label for this extraction record.
  Default: `NULL`.

## Value

The updated `ukbflow_audit` object.

## Examples

``` r
aud <- audit_start("example_analysis")
aud <- audit_fields(aud, c(31, 53, 21022), label = "core_fields")
```
