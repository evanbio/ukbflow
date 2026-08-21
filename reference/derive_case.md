# Combine per-source flags into a unified case definition

Merges the per-source status and date columns produced by the `derive_*`
functions into a single logical case status and earliest date.
Self-report
([`derive_selfreport`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md))
and ICD-10
([`derive_icd10`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md))
are the two required sources; ICD-9
([`derive_icd9`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)),
OPCS-4
([`derive_opcs`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md))
and primary care
([`derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
/
[`derive_gp_ctv3`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md))
are folded in automatically whenever their columns are present, so up to
six sources can contribute. Any logical status column paired with an
`IDate` column works, whatever produced it.

## Usage

``` r
derive_case(
  data,
  name,
  icd10_col = NULL,
  selfreport_col = NULL,
  icd9_col = NULL,
  opcs_col = NULL,
  read2_col = NULL,
  ctv3_col = NULL,
  icd10_date_col = NULL,
  selfreport_date_col = NULL,
  icd9_date_col = NULL,
  opcs_date_col = NULL,
  read2_date_col = NULL,
  ctv3_date_col = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Column prefix used both to locate the default input
  columns and to name the output columns. Defaults: `{name}_icd10`,
  `{name}_selfreport`, `{name}_icd10_date`, `{name}_selfreport_date`.
  `{name}_icd9` / `{name}_icd9_date` (from
  [`derive_icd9`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md)),
  `{name}_opcs` / `{name}_opcs_date` (from
  [`derive_opcs`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md)),
  and `{name}_gp_read2` / `{name}_gp_ctv3` plus their dates (from
  [`derive_gp_read2`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md)
  /
  [`derive_gp_ctv3`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md))
  are folded in as optional extra sources when present – there is no
  warning or error if they are absent, since most phenotypes have no
  ICD-9, OPCS-4 or primary-care arm.

- icd10_col:

  (character or NULL) Name of the ICD-10 status column. `NULL` =
  `paste0(name, "_icd10")`.

- selfreport_col:

  (character or NULL) Name of the self-report status column. `NULL` =
  `paste0(name, "_selfreport")`.

- icd9_col:

  (character or NULL) Name of the ICD-9 status column. `NULL` =
  `paste0(name, "_icd9")`. Optional: only folded into the combination
  when the column is actually present in `data`.

- opcs_col:

  (character or NULL) Name of the OPCS-4 status column. `NULL` =
  `paste0(name, "_opcs")`. Optional: only folded into the combination
  when the column is actually present in `data`.

- read2_col:

  (character or NULL) Name of the GP Read v2 status column. `NULL` =
  `paste0(name, "_gp_read2")`. Optional: only folded into the
  combination when the column is actually present in `data`.

- ctv3_col:

  (character or NULL) Name of the GP CTV3 status column. `NULL` =
  `paste0(name, "_gp_ctv3")`. Optional: only folded into the combination
  when the column is actually present in `data`.

- icd10_date_col:

  (character or NULL) Name of the ICD-10 date column. `NULL` =
  `paste0(name, "_icd10_date")`.

- selfreport_date_col:

  (character or NULL) Name of the self-report date column. `NULL` =
  `paste0(name, "_selfreport_date")`.

- icd9_date_col:

  (character or NULL) Name of the ICD-9 date column. `NULL` =
  `paste0(name, "_icd9_date")`.

- opcs_date_col:

  (character or NULL) Name of the OPCS-4 date column. `NULL` =
  `paste0(name, "_opcs_date")`.

- read2_date_col:

  (character or NULL) Name of the GP Read v2 date column. `NULL` =
  `paste0(name, "_gp_read2_date")`.

- ctv3_date_col:

  (character or NULL) Name of the GP CTV3 date column. `NULL` =
  `paste0(name, "_gp_ctv3_date")`.

## Value

The input `data` (invisibly) with two new columns added in-place:
`{name}_status` (logical) and `{name}_date` (IDate). Always returns a
`data.table`.

## Details

- `{name}_status`:

  Logical: `TRUE` if positive in at least one contributing source (OR).

- `{name}_date`:

  Earliest diagnosis/report date across every contributing source
  (`IDate`).

## Examples

``` r
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
derive_selfreport(dt, name = "htn", regex = "hypertension",
                  field        = "noncancer",
                  disease_cols = paste0("p20002_i0_a", 0:4),
                  date_cols    = paste0("p20008_i0_a", 0:4),
                  visit_cols   = "p53_i0")
#> ✔ derive_selfreport (htn): 6 cases, 6 with dates.
derive_icd10(dt, name = "htn", icd10 = "I10", source = c("hes", "death"))
#> ✔ derive_hes (htn): 8 cases, 8 with date.
#> ! derive_death_registry (htn): 0 cases found.
#> ✔ derive_icd10 (htn): 8 cases across 2 sources, 8 with date.
derive_case(dt, name = "htn")
#> ✔ derive_case (htn): 13 cases, 13 with date.
#> ℹ   Both sources (htn_icd10 & htn_selfreport): 1
```
