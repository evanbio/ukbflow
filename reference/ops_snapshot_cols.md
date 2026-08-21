# Retrieve column names recorded at a snapshot

Returns the column names stored by a previous
[`ops_snapshot`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md)
call, optionally excluding columns you wish to keep.

## Usage

``` r
ops_snapshot_cols(label, keep = NULL)
```

## Arguments

- label:

  (character) Snapshot label passed to
  [`ops_snapshot()`](https://evanbio.github.io/ukbflow/reference/ops_snapshot.md).

- keep:

  (character or NULL) Column names to exclude from the returned vector
  (i.e. columns to retain in the data even if they were present at that
  snapshot). Default `NULL`.

## Value

A character vector of column names.

## Examples

``` r
ops_snapshot(reset = TRUE, verbose = FALSE)

dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 107 columns | scenario = "cohort" | seed = 42
ops_snapshot(dt, label = "raw")
#> ── snapshot: raw ───────────────────────────────────────────────────────────────
#> rows 100
#> cols 107
#> NA cols 83
#> size 0.14 MB
#> ────────────────────────────────────────────────────────────────────────────────
ops_snapshot_cols("raw")
#>   [1] "p31"          "p34"          "p53_i0"       "p21022"       "p21001_i0"   
#>   [6] "p20116_i0"    "p1558_i0"     "p21000_i0"    "p22189"       "p54_i0"      
#>  [11] "p22009_a1"    "p22009_a2"    "p22009_a3"    "p22009_a4"    "p22009_a5"   
#>  [16] "p22009_a6"    "p22009_a7"    "p22009_a8"    "p22009_a9"    "p22009_a10"  
#>  [21] "p20002_i0_a0" "p20002_i0_a1" "p20002_i0_a2" "p20002_i0_a3" "p20002_i0_a4"
#>  [26] "p20008_i0_a0" "p20008_i0_a1" "p20008_i0_a2" "p20008_i0_a3" "p20008_i0_a4"
#>  [31] "p20001_i0_a0" "p20001_i0_a1" "p20001_i0_a2" "p20001_i0_a3" "p20001_i0_a4"
#>  [36] "p20006_i0_a0" "p20006_i0_a1" "p20006_i0_a2" "p20006_i0_a3" "p20006_i0_a4"
#>  [41] "p41270"       "p41280_a0"    "p41280_a1"    "p41280_a2"    "p41280_a3"   
#>  [46] "p41280_a4"    "p41280_a5"    "p41280_a6"    "p41280_a7"    "p41280_a8"   
#>  [51] "p41271"       "p41281_a0"    "p41281_a1"    "p41281_a2"    "p41272"      
#>  [56] "p41282_a0"    "p41282_a1"    "p41282_a2"    "p41202"       "p41262_a0"   
#>  [61] "p41262_a1"    "p41262_a2"    "p41262_a3"    "p41262_a4"    "p41262_a5"   
#>  [66] "p41262_a6"    "p41262_a7"    "p41262_a8"    "p41203"       "p41263_a0"   
#>  [71] "p41263_a1"    "p41263_a2"    "p41200"       "p41260_a0"    "p41260_a1"   
#>  [76] "p41260_a2"    "p40006_i0"    "p40011_i0"    "p40012_i0"    "p40005_i0"   
#>  [81] "p40006_i1"    "p40011_i1"    "p40012_i1"    "p40005_i1"    "p40006_i2"   
#>  [86] "p40011_i2"    "p40012_i2"    "p40005_i2"    "p40013_i3"    "p40011_i3"   
#>  [91] "p40012_i3"    "p40005_i3"    "p40001_i0"    "p40002_i0_a0" "p40002_i0_a1"
#>  [96] "p40002_i0_a2" "p40000_i0"    "p191"         "p131742"      "p42018"      
#> [101] "grs_bmi"      "grs_raw"      "grs_finngen"  "messy_allna"  "messy_empty" 
#> [106] "messy_label" 
ops_snapshot_cols("raw", keep = "eid")
#>   [1] "p31"          "p34"          "p53_i0"       "p21022"       "p21001_i0"   
#>   [6] "p20116_i0"    "p1558_i0"     "p21000_i0"    "p22189"       "p54_i0"      
#>  [11] "p22009_a1"    "p22009_a2"    "p22009_a3"    "p22009_a4"    "p22009_a5"   
#>  [16] "p22009_a6"    "p22009_a7"    "p22009_a8"    "p22009_a9"    "p22009_a10"  
#>  [21] "p20002_i0_a0" "p20002_i0_a1" "p20002_i0_a2" "p20002_i0_a3" "p20002_i0_a4"
#>  [26] "p20008_i0_a0" "p20008_i0_a1" "p20008_i0_a2" "p20008_i0_a3" "p20008_i0_a4"
#>  [31] "p20001_i0_a0" "p20001_i0_a1" "p20001_i0_a2" "p20001_i0_a3" "p20001_i0_a4"
#>  [36] "p20006_i0_a0" "p20006_i0_a1" "p20006_i0_a2" "p20006_i0_a3" "p20006_i0_a4"
#>  [41] "p41270"       "p41280_a0"    "p41280_a1"    "p41280_a2"    "p41280_a3"   
#>  [46] "p41280_a4"    "p41280_a5"    "p41280_a6"    "p41280_a7"    "p41280_a8"   
#>  [51] "p41271"       "p41281_a0"    "p41281_a1"    "p41281_a2"    "p41272"      
#>  [56] "p41282_a0"    "p41282_a1"    "p41282_a2"    "p41202"       "p41262_a0"   
#>  [61] "p41262_a1"    "p41262_a2"    "p41262_a3"    "p41262_a4"    "p41262_a5"   
#>  [66] "p41262_a6"    "p41262_a7"    "p41262_a8"    "p41203"       "p41263_a0"   
#>  [71] "p41263_a1"    "p41263_a2"    "p41200"       "p41260_a0"    "p41260_a1"   
#>  [76] "p41260_a2"    "p40006_i0"    "p40011_i0"    "p40012_i0"    "p40005_i0"   
#>  [81] "p40006_i1"    "p40011_i1"    "p40012_i1"    "p40005_i1"    "p40006_i2"   
#>  [86] "p40011_i2"    "p40012_i2"    "p40005_i2"    "p40013_i3"    "p40011_i3"   
#>  [91] "p40012_i3"    "p40005_i3"    "p40001_i0"    "p40002_i0_a0" "p40002_i0_a1"
#>  [96] "p40002_i0_a2" "p40000_i0"    "p191"         "p131742"      "p42018"      
#> [101] "grs_bmi"      "grs_raw"      "grs_finngen"  "messy_allna"  "messy_empty" 
#> [106] "messy_label" 

ops_snapshot(reset = TRUE, verbose = FALSE)
```
