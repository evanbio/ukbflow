# Write a ukbflow audit manifest

Writes a `ukbflow_audit` object to a JSON manifest. The manifest is a
plain-list representation of the audit object: session information is
converted to character lines, and record layers such as `extraction` and
`snapshots` are written as JSON arrays.

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

## Examples

``` r
aud <- audit_start("example_analysis")
outfile <- tempfile(fileext = ".json")
audit_write(aud, outfile)
#> ✔ audit manifest written: /tmp/Rtmp0MkjCT/file21e621b7d006.json
```
