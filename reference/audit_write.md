# Write a ukbflow audit manifest

Writes a `ukbflow_audit` object to a JSON manifest. The object is
validated against the audit schema before writing, so a structurally
broken or non-serialisable audit fails loudly rather than producing a
corrupt manifest. The manifest is a plain-list representation of the
audit object: session information is converted to character lines, and
record layers such as `fields` and `snapshots` are written as JSON
arrays.

## Usage

``` r
audit_write(audit, file = "ukbflow-audit.json", overwrite = FALSE)
```

## Arguments

- audit:

  A `ukbflow_audit` object created by
  [`audit_start`](https://evanbio.github.io/ukbflow/reference/audit_start.md).

- file:

  (character) Output JSON file path. Default: `"ukbflow-audit.json"`.

- overwrite:

  (logical) Overwrite `file` if it already exists. Default: `FALSE`.

## Value

Invisibly returns the normalized output path.

## Details

Numbers are written at full double precision, so effect estimates and
p-values read back exactly as the model produced them. Reading a
manifest with
[`audit_read`](https://evanbio.github.io/ukbflow/reference/audit_read.md)
and diffing it against the audit it came from reports no differences.

## Examples

``` r
aud <- audit_start("example_analysis", check_dx = FALSE)
outfile <- tempfile(fileext = ".json")
audit_write(aud, outfile)
#> ✔ audit manifest written: /tmp/RtmpLXmOSW/file20cd6eefc775.json
```
