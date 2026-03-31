# Fine-Gray competing risks association analysis

Fits a Fine-Gray subdistribution hazard model (via
[`survival::finegray()`](https://rdrr.io/pkg/survival/man/finegray.html) +
weighted `coxph()`) for each exposure variable and returns a tidy result
table with subdistribution hazard ratios (SHR).

## Usage

``` r
assoc_competing(
  data,
  outcome_col,
  time_col,
  exposure_col,
  compete_col = NULL,
  event_val = 1L,
  compete_val = 2L,
  covariates = NULL,
  base = TRUE,
  conf_level = 0.95
)

assoc_fg(
  data,
  outcome_col,
  time_col,
  exposure_col,
  compete_col = NULL,
  event_val = 1L,
  compete_val = 2L,
  covariates = NULL,
  base = TRUE,
  conf_level = 0.95
)
```

## Arguments

- data:

  (data.frame or data.table) Analysis dataset.

- outcome_col:

  (character) Primary event column. In Mode A: a multi-value column (any
  integer or character codes). In Mode B: a 0/1 binary column.

- time_col:

  (character) Follow-up time column (numeric, e.g. years).

- exposure_col:

  (character) One or more exposure variable names.

- compete_col:

  (character or NULL) Mode B only: name of the 0/1 competing event
  column. When `NULL` (default), Mode A is used.

- event_val:

  Scalar value in `outcome_col` indicating the primary event (Mode A
  only). Default: `1L`.

- compete_val:

  Scalar value in `outcome_col` indicating the competing event (Mode A
  only). Default: `2L`.

- covariates:

  (character or NULL) Covariate names for the Fully adjusted model. When
  `NULL`, only Unadjusted (and Age/sex adjusted if `base = TRUE`) are
  run.

- base:

  (logical) Whether to auto-detect age and sex columns and include an
  Age and sex adjusted model. Default: `TRUE`.

- conf_level:

  (numeric) Confidence level for SHR intervals. Default: `0.95`.

## Value

A `data.table` with one row per exposure \\\times\\ term \\\times\\
model combination:

- `exposure`:

  Exposure variable name.

- `term`:

  Coefficient name as returned by `coxph`.

- `model`:

  Ordered factor: `Unadjusted` \< `Age and sex adjusted` \<
  `Fully adjusted`.

- `n`:

  Participants in the model (after NA removal).

- `n_events`:

  Primary events in the analysis set.

- `n_compete`:

  Competing events in the analysis set.

- `SHR`:

  Subdistribution hazard ratio.

- `CI_lower`:

  Lower CI bound.

- `CI_upper`:

  Upper CI bound.

- `p_value`:

  Robust z-test p-value from weighted Cox.

- `SHR_label`:

  Formatted string, e.g. `"1.23 (1.05-1.44)"`.

## Details

Two input modes are supported depending on how the outcome is coded in
your dataset:

- **Mode A - single multi-value column**:

  `compete_col = NULL` (default). `outcome_col` contains all event codes
  in one column (e.g. `0`/`1`/`2`/`3`). Use `event_val` and
  `compete_val` to identify the event of interest and the competing
  event; all other values are treated as censored. Example: UKB
  `censoring_type` where 1 = event, 2 = death (competing), 0/3 =
  censored.

- **Mode B - dual binary columns**:

  `compete_col` is the name of a separate 0/1 column for the competing
  event. `outcome_col` is a 0/1 column for the primary event. When both
  are 1 for the same participant, the primary event takes priority.
  Example: `outcome_col = "copd_status"`,
  `compete_col = "death_status"`.

Internally both modes are converted to a three-level factor
`c("censor", "event", "compete")` before being passed to `finegray()`.

Three adjustment models are produced (where data allow):

- **Unadjusted** - always included.

- **Age and sex adjusted** - when `base = TRUE` and age/sex columns are
  detected.

- **Fully adjusted** - when `covariates` is non-NULL.

## Examples

``` r
dt <- ops_toy(scenario = "association")
#> ✔ ops_toy: 2000 participants | 33 columns | scenario = "association" | seed = 42
dt <- dt[dm_timing != 1L & htn_timing != 1L]   # exclude prevalent for both

# Mode B: separate 0/1 columns — dm as primary, htn as competing event
res <- assoc_competing(
  data         = dt,
  outcome_col  = "dm_status",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  compete_col  = "htn_status",
  covariates   = c("bmi_cat", "tdi_cat", paste0("p22009_a", 1:4))
)
#> ℹ Mode B: dm_status (event) + htn_status (compete)
#> ℹ Events: 96, Competing: 199, Censored: 1277
#> ℹ Exposure: p20116_i0
#> ℹ   Model: Unadjusted
#> ℹ   Model: Age and sex adjusted
#> ℹ   Model: Fully adjusted
#> ✔ Done: 6 result rows across 1 exposure and 3 models.

# Mode A: single multi-value column (0 = censored, 1 = dm, 2 = htn)
dt[, event_type := data.table::fcase(
  dm_timing  == 2L, 1L,
  htn_timing == 2L, 2L,
  default          = 0L
)]
#>            eid    p31     p53_i0 p21022 p21001_i0    bmi_cat p20116_i0
#>          <int> <fctr>     <IDat>  <int>     <num>     <fctr>    <fctr>
#>    1: 10000001   Male 2009-10-22     59     29.92 Overweight     Never
#>    2: 10000003 Female 2008-03-23     63     19.40     Normal     Never
#>    3: 10000004   Male 2008-07-11     58     26.62 Overweight      <NA>
#>    4: 10000005   Male 2009-11-20     68     31.00      Obese  Previous
#>    5: 10000006 Female 2008-10-24     56     26.69 Overweight     Never
#>   ---                                                                 
#> 1568: 10001993 Female 2009-03-11     44     20.01     Normal     Never
#> 1569: 10001994   Male 2006-11-12     59     26.83 Overweight      <NA>
#> 1570: 10001995   Male 2009-05-24     66     29.30 Overweight     Never
#> 1571: 10001997 Female 2007-01-15     55     27.35 Overweight  Previous
#> 1572: 10001999 Female 2006-08-06     53     18.91     Normal  Previous
#>                         p1558_i0 p21000_i0 p22189             tdi_cat
#>                           <fctr>    <fctr>  <num>              <fctr>
#>    1:     Special occasions only     White  -3.41                  Q2
#>    2: One to three times a month     White   3.74  Q4 (most deprived)
#>    3: Three or four times a week     White  -2.89                  Q2
#>    4:     Special occasions only     White   3.01  Q4 (most deprived)
#>    5:       Once or twice a week     White  -4.48 Q1 (least deprived)
#>   ---                                                                
#> 1568:       Once or twice a week     White  -4.44 Q1 (least deprived)
#> 1569:                       <NA>     White  -1.98                  Q2
#> 1570: One to three times a month     White  -5.60 Q1 (least deprived)
#> 1571:     Special occasions only     White  -0.10                  Q3
#> 1572:       Once or twice a week     White  -4.88 Q1 (least deprived)
#>           p54_i0 p22009_a1 p22009_a2 p22009_a3 p22009_a4 p22009_a5 p22009_a6
#>           <fctr>     <num>     <num>     <num>     <num>     <num>     <num>
#>    1:  Liverpool  0.621740 -0.033538  0.767350 -0.785157  1.489561  0.012842
#>    2: Manchester  0.607370 -0.763005  0.243056  0.463153 -2.320538 -0.868845
#>    3: Nottingham  0.807036 -1.156481  0.335599  0.141878  2.048786 -0.547001
#>    4:    Bristol -0.573670  0.227728  0.137995 -1.297519  0.352876 -1.458635
#>    5:     Oxford  0.944962  0.932773  1.066530  0.346315  0.099671  1.062593
#>   ---                                                                       
#> 1568:  Liverpool  0.028994  0.458311  1.232060  0.135777 -0.837283 -0.138470
#> 1569:  Edinburgh -1.437429  0.480948  0.293574 -0.653266  0.585326  1.562877
#> 1570:  Liverpool -2.030491  1.115307  0.093622 -2.457391  0.566985  0.075256
#> 1571:     Oxford  1.161648 -2.072066 -0.469584  0.564503 -0.532568 -0.289483
#> 1572:  Edinburgh -1.040655 -1.771625  0.583996 -1.196393 -0.659005  1.069350
#>       p22009_a7 p22009_a8 p22009_a9 p22009_a10   grs_bmi dm_status dm_date
#>           <num>     <num>     <num>      <num>     <num>    <lgcl>  <IDat>
#>    1:  1.455166  0.529780 -1.220117   0.048976  3.922478     FALSE    <NA>
#>    2:  1.626062 -1.522594 -1.085131  -0.049201  1.531582     FALSE    <NA>
#>    3:  1.247015 -1.062169  2.772582  -0.937789 -3.019188     FALSE    <NA>
#>    4: -1.246419 -1.561089  0.004359   0.566357  6.883045     FALSE    <NA>
#>    5: -1.503327 -0.640098  0.343004   0.081488  0.745111     FALSE    <NA>
#>   ---                                                                     
#> 1568:  0.971321 -0.507438 -2.272432   0.507471 -1.864669     FALSE    <NA>
#> 1569: -0.180339 -0.020269  0.845419   0.146726  2.873347     FALSE    <NA>
#> 1570: -0.354080  1.217505 -1.628469  -1.782278  2.452643     FALSE    <NA>
#> 1571:  0.410814  0.932132 -1.736088  -0.191632 -1.069658     FALSE    <NA>
#> 1572:  0.193874  0.463562 -0.499771   0.218048  4.583697     FALSE    <NA>
#>       dm_timing dm_followup_end dm_followup_years htn_status   htn_date
#>           <int>          <IDat>             <num>     <lgcl>     <IDat>
#>    1:         0      2022-10-31           13.0240      FALSE       <NA>
#>    2:         0      2022-10-31           14.6064      FALSE       <NA>
#>    3:         0      2022-10-31           14.3053      FALSE       <NA>
#>    4:         0      2022-10-31           12.9446      FALSE       <NA>
#>    5:         0      2022-10-31           14.0178      FALSE       <NA>
#>   ---                                                                  
#> 1568:         0      2022-10-31           13.6400      FALSE       <NA>
#> 1569:         0      2022-10-31           15.9671       TRUE 2014-03-01
#> 1570:         0      2022-10-31           13.4374      FALSE       <NA>
#> 1571:         0      2022-10-31           15.7919       TRUE 2010-10-20
#> 1572:         0      2022-10-31           16.2355      FALSE       <NA>
#>       htn_timing htn_followup_end htn_followup_years event_type
#>            <int>           <IDat>              <num>      <int>
#>    1:          0       2022-10-31            13.0240          0
#>    2:          0       2022-10-31            14.6064          0
#>    3:          0       2022-10-31            14.3053          0
#>    4:          0       2022-10-31            12.9446          0
#>    5:          0       2022-10-31            14.0178          0
#>   ---                                                          
#> 1568:          0       2022-10-31            13.6400          0
#> 1569:          2       2014-03-01             7.2991          2
#> 1570:          0       2022-10-31            13.4374          0
#> 1571:          2       2010-10-20             3.7618          2
#> 1572:          0       2022-10-31            16.2355          0
res <- assoc_competing(
  data         = dt,
  outcome_col  = "event_type",
  time_col     = "dm_followup_years",
  exposure_col = "p20116_i0",
  event_val    = 1L,
  compete_val  = 2L,
  covariates   = c("bmi_cat", "tdi_cat", paste0("p22009_a", 1:4))
)
#> ℹ Mode A: event_type -> event=1, compete=2, rest=censor
#> ℹ Events: 96, Competing: 199, Censored: 1277
#> ℹ Exposure: p20116_i0
#> ℹ   Model: Unadjusted
#> ℹ   Model: Age and sex adjusted
#> ℹ   Model: Fully adjusted
#> ✔ Done: 6 result rows across 1 exposure and 3 models.
```
