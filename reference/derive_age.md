# Compute age at event for one or more UKB outcomes

For each name in `name`, adds one column `age_at_{name}` (numeric,
years) computed as: \$\$age\\at\\event = age\\col + (event\\date -
baseline\\date) / 365.25\$\$

## Usage

``` r
derive_age(
  data,
  name,
  baseline_col,
  age_col,
  date_cols = NULL,
  status_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) One or more output prefixes, e.g.
  `c("disease", "disease_icd10", "outcome")`. Each produces
  `age_at_{name}`.

- baseline_col:

  (character) Name of the baseline date column (e.g. `"date_baseline"`).

- age_col:

  (character) Name of the age-at-baseline column (e.g.
  `"age_recruitment"`).

- date_cols:

  (character or NULL) Named character vector mapping each name to its
  event date column, e.g.
  `c(disease = "disease_date", outcome = "outcome_date")`. `NULL`
  (default) triggers auto-detection as `{name}_date`.

- status_cols:

  (character or NULL) Named character vector mapping each name to its
  status column. `NULL` (default) triggers auto-detection.

## Value

The input `data` with one new `age_at_{name}` column per entry in
`name`, added in-place.

## Details

The value is `NA` for participants who did not experience the event
(status is `FALSE` / `0`) or who lack an event date.

**Auto-detection per name** (when `date_cols` / `status_cols` are
`NULL`):

- `date_col` - looked up as `{name}_date`.

- `status_col` - looked up first as `{name}_status`, then as `{name}`
  (logical column); if neither exists all rows with a non-`NA` date are
  treated as cases.

**data.table pass-by-reference**: new columns are added in-place.

## Examples

``` r
dt <- ops_toy(scenario = "association", n = 100)
#> ✔ ops_toy: 100 participants | 33 columns | scenario = "association" | seed = 42
derive_age(dt, name = "dm", baseline_col = "p53_i0", age_col = "p21022")
#> ℹ   age_at_dm: n=9, median=60.2, range=[38.4, 76.6]
#> ✔ derive_age: 1 event processed.
#>           eid    p31     p53_i0 p21022 p21001_i0     bmi_cat p20116_i0
#>         <int> <fctr>     <IDat>  <int>     <num>      <fctr>    <fctr>
#>   1: 10000001   Male 2006-03-23     66     21.80      Normal     Never
#>   2: 10000002   Male 2008-07-02     49     23.27      Normal     Never
#>   3: 10000003 Female 2006-11-21     64     33.28       Obese     Never
#>   4: 10000004   Male 2010-07-04     67     25.23  Overweight     Never
#>   5: 10000005   Male 2009-10-15     61     20.31      Normal     Never
#>   6: 10000006 Female 2008-08-08     44     27.10  Overweight  Previous
#>   7: 10000007   Male 2006-10-23     49     24.20      Normal  Previous
#>   8: 10000008 Female 2006-05-29     56     29.45  Overweight   Current
#>   9: 10000009   Male 2008-09-22     56     34.08       Obese   Current
#>  10: 10000010   Male 2010-05-12     44     20.74      Normal     Never
#>  11: 10000011 Female 2006-04-10     42     28.70  Overweight  Previous
#>  12: 10000012   Male 2008-09-25     53     26.67  Overweight  Previous
#>  13: 10000013   Male 2006-10-25     53     31.13       Obese     Never
#>  14: 10000014 Female 2007-02-06     67     24.94      Normal   Current
#>  15: 10000015 Female 2006-04-01     65     30.80       Obese     Never
#>  16: 10000016   Male 2008-02-20     40     16.60 Underweight     Never
#>  17: 10000017   Male 2009-04-19     44     35.49       Obese   Current
#>  18: 10000018 Female 2008-12-13     42     30.96       Obese     Never
#>  19: 10000019 Female 2008-04-30     61     25.37  Overweight  Previous
#>  20: 10000020   Male 2006-10-15     65     18.23 Underweight  Previous
#>  21: 10000021   Male 2007-12-21     70     29.74  Overweight     Never
#>  22: 10000022 Female 2010-11-17     70     28.86  Overweight     Never
#>  23: 10000023   Male 2006-03-01     52     26.17  Overweight     Never
#>  24: 10000024   Male 2009-08-01     50     27.03  Overweight  Previous
#>  25: 10000025 Female 2008-04-28     59     22.99      Normal  Previous
#>  26: 10000026 Female 2010-07-02     65     28.23  Overweight     Never
#>  27: 10000027 Female 2008-08-26     56     27.82  Overweight  Previous
#>  28: 10000028   Male 2007-01-12     66     24.66      Normal   Current
#>  29: 10000029 Female 2007-09-30     66     18.85      Normal     Never
#>  30: 10000030   Male 2007-03-03     69     30.05       Obese     Never
#>  31: 10000031   Male 2007-03-18     59     29.25  Overweight  Previous
#>  32: 10000032   Male 2009-02-09     43     21.60      Normal  Previous
#>  33: 10000033 Female 2007-08-07     59     17.43 Underweight  Previous
#>  34: 10000034   Male 2009-08-01     50     27.33  Overweight     Never
#>  35: 10000035 Female 2008-08-08     56     24.30      Normal     Never
#>  36: 10000036   Male 2010-03-17     48     27.59  Overweight     Never
#>  37: 10000037 Female 2009-03-10     56     19.08      Normal   Current
#>  38: 10000038 Female 2010-10-08     69     20.92      Normal     Never
#>  39: 10000039   Male 2008-08-26     52     32.17       Obese  Previous
#>  40: 10000040   Male 2006-11-07     70     28.42  Overweight     Never
#>  41: 10000041 Female 2008-06-30     69     29.43  Overweight     Never
#>  42: 10000042 Female 2007-04-19     67     36.18       Obese     Never
#>  43: 10000043 Female 2008-03-21     70     26.91  Overweight   Current
#>  44: 10000044   Male 2010-04-27     56     15.19 Underweight     Never
#>  45: 10000045 Female 2006-02-11     68     28.04  Overweight   Current
#>  46: 10000046   Male 2008-01-30     59     32.64       Obese  Previous
#>  47: 10000047   Male 2009-06-28     40     37.53       Obese  Previous
#>  48: 10000048   Male 2010-01-04     56     18.63      Normal     Never
#>  49: 10000049   Male 2010-08-20     40     19.87      Normal     Never
#>  50: 10000050   Male 2006-01-25     67     22.32      Normal     Never
#>  51: 10000051 Female 2007-12-04     41     20.40      Normal     Never
#>  52: 10000052 Female 2010-04-17     70     22.65      Normal     Never
#>  53: 10000053 Female 2009-06-15     47     25.18  Overweight  Previous
#>  54: 10000054   Male 2007-06-10     70     19.59      Normal     Never
#>  55: 10000055 Female 2007-09-15     55     37.40       Obese     Never
#>  56: 10000056   Male 2006-09-19     42     26.79  Overweight  Previous
#>  57: 10000057   Male 2010-03-08     44     25.74  Overweight  Previous
#>  58: 10000058 Female 2008-07-31     52     28.93  Overweight     Never
#>  59: 10000059 Female 2006-10-26     51     26.41  Overweight      <NA>
#>  60: 10000060 Female 2010-01-09     40     25.47  Overweight     Never
#>  61: 10000061   Male 2007-12-21     69     34.32       Obese     Never
#>  62: 10000062   Male 2007-01-04     58     25.01  Overweight  Previous
#>  63: 10000063   Male 2007-05-27     67     19.14      Normal     Never
#>  64: 10000064   Male 2008-01-28     70     28.32  Overweight     Never
#>  65: 10000065   Male 2009-10-24     44     24.27      Normal  Previous
#>  66: 10000066 Female 2008-01-24     54     23.33      Normal  Previous
#>  67: 10000067 Female 2008-03-09     63     20.33      Normal     Never
#>  68: 10000068   Male 2008-05-11     45     28.56  Overweight   Current
#>  69: 10000069   Male 2009-06-01     62     25.24  Overweight  Previous
#>  70: 10000070 Female 2008-02-13     55     29.04  Overweight  Previous
#>  71: 10000071 Female 2009-05-22     49     24.91      Normal     Never
#>  72: 10000072 Female 2006-10-21     46     22.58      Normal     Never
#>  73: 10000073 Female 2007-08-30     70     33.08       Obese      <NA>
#>  74: 10000074 Female 2010-03-22     48     24.71      Normal      <NA>
#>  75: 10000075 Female 2008-02-03     48     31.41       Obese     Never
#>  76: 10000076   Male 2008-02-22     64     19.59      Normal  Previous
#>  77: 10000077 Female 2007-06-30     42     23.64      Normal     Never
#>  78: 10000078 Female 2007-03-02     57     24.72      Normal   Current
#>  79: 10000079 Female 2007-04-16     60     24.05      Normal     Never
#>  80: 10000080 Female 2006-07-07     54     33.62       Obese      <NA>
#>  81: 10000081   Male 2006-09-11     67     26.07  Overweight  Previous
#>  82: 10000082 Female 2006-09-25     67     27.54  Overweight     Never
#>  83: 10000083 Female 2007-10-02     54     21.02      Normal  Previous
#>  84: 10000084   Male 2009-12-04     68     22.19      Normal     Never
#>  85: 10000085   Male 2006-02-10     64     31.69       Obese     Never
#>  86: 10000086   Male 2009-05-01     59     33.12       Obese     Never
#>  87: 10000087 Female 2010-05-21     64     33.07       Obese     Never
#>  88: 10000088 Female 2008-04-03     55     18.61      Normal     Never
#>  89: 10000089 Female 2007-10-26     61     37.47       Obese  Previous
#>  90: 10000090 Female 2009-01-26     63     31.79       Obese     Never
#>  91: 10000091   Male 2007-06-21     40     26.05  Overweight     Never
#>  92: 10000092 Female 2006-12-14     68     30.07       Obese     Never
#>  93: 10000093 Female 2006-04-17     45     20.86      Normal  Previous
#>  94: 10000094   Male 2006-11-13     50     20.17      Normal     Never
#>  95: 10000095   Male 2008-11-03     48     26.47  Overweight     Never
#>  96: 10000096   Male 2006-06-11     61     19.61      Normal  Previous
#>  97: 10000097 Female 2007-09-28     65     27.25  Overweight     Never
#>  98: 10000098 Female 2007-12-07     61     33.34       Obese  Previous
#>  99: 10000099   Male 2010-06-19     61     20.51      Normal  Previous
#> 100: 10000100   Male 2010-04-17     59     22.14      Normal     Never
#>           eid    p31     p53_i0 p21022 p21001_i0     bmi_cat p20116_i0
#>         <int> <fctr>     <IDat>  <int>     <num>      <fctr>    <fctr>
#>                        p1558_i0 p21000_i0 p22189             tdi_cat     p54_i0
#>                          <fctr>    <fctr>  <num>              <fctr>     <fctr>
#>   1:                      Never     White   0.80  Q4 (most deprived)  Edinburgh
#>   2:      Daily or almost daily     White   3.43  Q4 (most deprived)  Sheffield
#>   3:       Once or twice a week     White  -7.00 Q1 (least deprived)      Leeds
#>   4:       Once or twice a week     White  -3.55                  Q2  Sheffield
#>   5: Three or four times a week     White  -2.30                  Q2  Newcastle
#>   6: Three or four times a week     White  -6.62 Q1 (least deprived)  Liverpool
#>   7: Three or four times a week     White  -3.70 Q1 (least deprived) Nottingham
#>   8: One to three times a month     White  -3.79 Q1 (least deprived) Manchester
#>   9:       Once or twice a week     White  -3.61 Q1 (least deprived)    Bristol
#>  10:     Special occasions only     White  -7.00 Q1 (least deprived)    Bristol
#>  11:       Once or twice a week     White  -0.62                  Q3 Nottingham
#>  12:     Special occasions only     White  -3.32                  Q2      Leeds
#>  13:       Once or twice a week     White   3.57  Q4 (most deprived)  Sheffield
#>  14: Three or four times a week     White   1.25  Q4 (most deprived) Birmingham
#>  15:     Special occasions only     White  -5.95 Q1 (least deprived)      Leeds
#>  16: Three or four times a week     White  -0.99                  Q3      Leeds
#>  17: Three or four times a week     White  -3.20                  Q2  Sheffield
#>  18:       Once or twice a week     Other   1.54  Q4 (most deprived)    Bristol
#>  19:       Once or twice a week     Black  -1.13                  Q3  Liverpool
#>  20:       Once or twice a week     Asian  -3.08                  Q2     Oxford
#>  21: One to three times a month     White   0.10                  Q3  Edinburgh
#>  22:     Special occasions only     White  -0.81                  Q3  Liverpool
#>  23:       Once or twice a week     White  -1.83                  Q2 Nottingham
#>  24: One to three times a month     White   5.16  Q4 (most deprived)  Newcastle
#>  25:                      Never     White  -2.99                  Q2  Liverpool
#>  26:     Special occasions only     White  -2.81                  Q2 Nottingham
#>  27: Three or four times a week     Other  -6.25 Q1 (least deprived)  Edinburgh
#>  28:       Once or twice a week     White  -1.43                  Q3    Bristol
#>  29: One to three times a month     White   1.55  Q4 (most deprived)  Edinburgh
#>  30:                      Never     Other  -7.00 Q1 (least deprived)  Newcastle
#>  31: One to three times a month     Asian  -2.10                  Q2      Leeds
#>  32:     Special occasions only     White  -5.08 Q1 (least deprived) Nottingham
#>  33: One to three times a month     White   3.31  Q4 (most deprived) Birmingham
#>  34: Three or four times a week     White   3.05  Q4 (most deprived)     Oxford
#>  35:      Daily or almost daily     Asian  -0.23                  Q3    Bristol
#>  36:      Daily or almost daily     White   3.27  Q4 (most deprived) Nottingham
#>  37:       Once or twice a week     White  -4.08 Q1 (least deprived)  Liverpool
#>  38:      Daily or almost daily     White   1.74  Q4 (most deprived) Nottingham
#>  39:                      Never     White  -3.17                  Q2  Edinburgh
#>  40:     Special occasions only     White  -0.27                  Q3  Edinburgh
#>  41: One to three times a month     White  -2.26                  Q2  Sheffield
#>  42: Three or four times a week     White  -2.19                  Q2  Liverpool
#>  43:       Once or twice a week     White   0.45                  Q3  Newcastle
#>  44:       Once or twice a week     White  -5.47 Q1 (least deprived)  Newcastle
#>  45: Three or four times a week     Black  -2.10                  Q2      Leeds
#>  46: Three or four times a week     Other  -0.75                  Q3    Bristol
#>  47:     Special occasions only     Mixed  -2.59                  Q2  Edinburgh
#>  48:      Daily or almost daily     White  -0.97                  Q3  Edinburgh
#>  49: Three or four times a week     White  -2.32                  Q2 Manchester
#>  50:                      Never     White   3.88  Q4 (most deprived)     Oxford
#>  51:       Once or twice a week     White   0.99  Q4 (most deprived) Birmingham
#>  52:     Special occasions only     White   8.19  Q4 (most deprived)  Liverpool
#>  53: One to three times a month     Asian  -3.84 Q1 (least deprived) Manchester
#>  54: Three or four times a week     White   1.31  Q4 (most deprived)      Leeds
#>  55:                      Never     White   5.41  Q4 (most deprived)    Bristol
#>  56: Three or four times a week     White  -0.34                  Q3 Manchester
#>  57: Three or four times a week     White  -4.77 Q1 (least deprived) Birmingham
#>  58:     Special occasions only     White  -4.52 Q1 (least deprived)  Edinburgh
#>  59:       Once or twice a week     White  -1.41                  Q3  Sheffield
#>  60: Three or four times a week     White   2.89  Q4 (most deprived) Nottingham
#>  61:       Once or twice a week     White   1.10  Q4 (most deprived)  Liverpool
#>  62:       Once or twice a week     White  -7.00 Q1 (least deprived)  Newcastle
#>  63:       Once or twice a week     Asian  -3.54                  Q2  Sheffield
#>  64:       Once or twice a week     Asian  -1.33                  Q3  Newcastle
#>  65: Three or four times a week     White  -5.97 Q1 (least deprived)  Sheffield
#>  66: Three or four times a week     Other   0.92  Q4 (most deprived) Birmingham
#>  67: One to three times a month     White  -7.00 Q1 (least deprived)  Liverpool
#>  68:                      Never     White  -0.84                  Q3  Newcastle
#>  69:     Special occasions only     White  -2.55                  Q2     Oxford
#>  70:      Daily or almost daily     White  -2.87                  Q2    Bristol
#>  71: Three or four times a week     White  -2.21                  Q2 Nottingham
#>  72:                      Never     White  -0.29                  Q3  Sheffield
#>  73:       Once or twice a week     White  -0.03                  Q3 Nottingham
#>  74:       Once or twice a week     White  -2.02                  Q2 Birmingham
#>  75:     Special occasions only     White  -7.00 Q1 (least deprived)  Sheffield
#>  76: One to three times a month     White  -5.91 Q1 (least deprived)  Edinburgh
#>  77: One to three times a month     White  -6.00 Q1 (least deprived)    Bristol
#>  78:       Once or twice a week     White   1.14  Q4 (most deprived)      Leeds
#>  79:                      Never     White  -2.08                  Q2  Newcastle
#>  80:                      Never     White  -0.44                  Q3 Nottingham
#>  81:       Once or twice a week     White  -6.29 Q1 (least deprived)  Sheffield
#>  82:     Special occasions only     White  -3.01                  Q2     Oxford
#>  83: One to three times a month     White   0.50                  Q3    Bristol
#>  84:      Daily or almost daily     White  -1.87                  Q2    Bristol
#>  85:      Daily or almost daily     White  -1.67                  Q3  Edinburgh
#>  86: Three or four times a week     White  -1.53                  Q3      Leeds
#>  87:     Special occasions only     Asian   2.57  Q4 (most deprived)  Sheffield
#>  88: One to three times a month     Asian  -3.27                  Q2 Birmingham
#>  89:       Once or twice a week     White   0.86  Q4 (most deprived)  Edinburgh
#>  90:     Special occasions only     White   1.58  Q4 (most deprived)      Leeds
#>  91:     Special occasions only     White  -5.11 Q1 (least deprived)      Leeds
#>  92:     Special occasions only     White  -0.91                  Q3 Nottingham
#>  93:       Once or twice a week     White  -1.34                  Q3      Leeds
#>  94: Three or four times a week     White   1.99  Q4 (most deprived) Manchester
#>  95: Three or four times a week     White   1.63  Q4 (most deprived)  Edinburgh
#>  96: One to three times a month     White  -1.31                  Q3 Birmingham
#>  97:                      Never     White  -0.86                  Q3  Newcastle
#>  98:                      Never     Asian  -3.60 Q1 (least deprived)     Oxford
#>  99: Three or four times a week     White  -1.93                  Q2      Leeds
#> 100:     Special occasions only     White  -4.59 Q1 (least deprived) Nottingham
#>                        p1558_i0 p21000_i0 p22189             tdi_cat     p54_i0
#>                          <fctr>    <fctr>  <num>              <fctr>     <fctr>
#>      p22009_a1 p22009_a2 p22009_a3 p22009_a4 p22009_a5 p22009_a6 p22009_a7
#>          <num>     <num>     <num>     <num>     <num>     <num>     <num>
#>   1: -0.167301  0.933511  2.897550 -0.757824 -0.543123  2.264042 -0.103786
#>   2: -0.130656 -0.074242 -0.883626 -0.866477  0.382939  0.892482 -1.832869
#>   3: -0.695522 -0.161808  0.655151  1.481191 -1.482718 -0.056449 -0.884601
#>   4: -0.350102 -1.579292  2.850919 -0.360459  0.554321  0.662341 -0.839361
#>   5: -0.189017 -1.045546 -0.232221  1.113754 -0.424829 -0.786348  1.260438
#>   6:  0.487763  0.469422  1.713567  0.181759 -0.745351 -1.574422 -0.224634
#>   7:  1.113334 -0.189777 -1.174456  0.525355 -0.874051  0.310874 -0.174565
#>   8: -2.225075 -0.701756  0.449677 -0.981061  0.004636 -2.518291 -0.711998
#>   9:  1.931000 -1.482116 -1.048883 -0.001996  0.350714 -0.877872 -0.023321
#>  10:  2.552516  2.119578 -1.481499 -0.119282  0.487663 -0.259697 -1.888016
#>  11: -1.159945  1.135382 -0.860095 -1.425225 -1.050909  1.225714  0.932839
#>  12: -0.708580 -0.862927 -1.046773 -0.487112 -0.642048  0.938000  0.728238
#>  13:  0.792713 -0.612063 -0.441223 -0.266867 -0.640479  0.766055  1.390336
#>  14: -0.077583  0.208381 -0.878694  0.233189  0.627576 -0.748508 -0.200386
#>  15:  1.295207 -0.070480 -0.012304 -0.405856  0.625887  1.238896  0.833432
#>  16:  0.498677  1.230273  0.684850  0.706107  2.128189 -0.169632 -1.209094
#>  17: -1.311384  0.052728 -0.923160  0.639357  0.726324  1.603320  0.742694
#>  18:  0.442729  0.067270  0.092131 -2.044178 -0.625239 -1.385054  0.322781
#>  19: -1.210134 -2.960872 -2.035076 -1.150163 -0.742389 -0.354183  1.110548
#>  20: -0.133701 -0.131156  0.141690 -1.517083  1.662553 -0.001632  1.022367
#>  21: -0.170740 -1.642790  0.416128 -0.369165 -0.154790  0.596080 -1.111288
#>  22: -0.906373 -0.459291 -1.067637  1.839604  1.221634 -0.480439  0.475287
#>  23:  1.387616 -0.799935  0.545423  0.333075  0.626241  0.466225  1.912456
#>  24:  0.007661  0.450120  2.361409 -1.265078  1.006358 -2.066581 -0.545649
#>  25:  0.432320 -0.243610  0.123427  0.438279 -0.348570 -0.448025  0.756541
#>  26:  2.069727 -0.386402 -0.285265 -0.342766 -1.151348 -0.371689  0.143223
#>  27: -0.299172 -0.543567  2.692738  0.139121  0.448878  0.214664 -0.087507
#>  28:  0.120326 -0.104971  0.771484  0.125064  0.844916 -0.646570  0.721604
#>  29: -0.247386 -1.608625  0.430888 -1.532547  0.430944 -1.178652  0.979477
#>  30:  1.032127  1.000861  1.607881  1.266611  1.666383  0.181938 -0.494343
#>  31:  0.391515 -0.109583  1.650372  0.934360  0.066167  0.186619  0.242835
#>  32: -0.488463  0.758399 -1.354097 -0.425153 -1.118262 -1.265316  0.750022
#>  33:  0.949933  2.158866  0.697077 -1.484392  0.485248 -1.209753 -1.244037
#>  34: -1.088838 -0.910272 -0.510066 -1.600966 -0.202024 -0.256062  1.458202
#>  35:  0.194449  1.129814 -0.458790  0.926501  1.035667 -0.036373 -0.921121
#>  36: -1.907991  1.367496 -0.776384  0.899950 -0.571400  0.988561  1.938695
#>  37:  0.695940  0.868715 -2.407559 -0.668240 -0.765660  0.422093  0.086772
#>  38:  0.059473  0.455355  0.811362  0.477883 -1.547452  1.682402 -0.577265
#>  39: -0.030321  1.724934 -0.864614  0.447563 -1.291301  0.214723  1.460351
#>  40: -1.279446 -0.459397  1.300186  1.673892 -1.171313  1.352227  0.106569
#>  41: -0.246897 -0.700109  0.594137  0.523136 -2.340479 -1.494254  1.700074
#>  42:  1.659156  0.234757 -1.996892  1.932536  0.697402 -0.964946 -0.412815
#>  43:  0.951393  0.275043 -0.924795  0.250014  0.763674 -0.960835 -0.521562
#>  44:  0.836329  1.180017  1.363546  0.747652 -0.985942 -1.768034 -0.217890
#>  45:  0.689379  1.107090 -0.525076  1.001080 -0.151333  0.286674 -1.394531
#>  46:  0.680120  0.173266 -2.188498 -0.078138  0.497549 -1.994878  0.441582
#>  47: -1.575690 -0.274206  3.197166  2.119135  0.840360  0.888606 -0.181488
#>  48: -1.732749  1.599261  0.576559  0.726264  0.410687  0.074206 -1.680047
#>  49: -0.525538 -2.009432 -0.275499  1.255804  0.435147  0.444397  0.535166
#>  50:  1.429044 -0.717711  2.323594  0.330100  0.196470  0.155193  0.137362
#>  51:  0.575568  0.419859  1.989531  1.291995 -1.033330  1.499038  0.182607
#>  52: -0.744880 -1.197410  0.480334 -0.002671  0.180129  0.329162 -0.113193
#>  53:  0.179211  0.324316 -1.602547  0.775425  1.000050  0.479179 -0.232366
#>  54:  0.239595 -0.720025 -0.395356  0.566818 -0.688364 -1.827809 -0.733823
#>  55: -0.381587 -0.503789  0.312776  1.234527  1.020051  0.858410  0.810055
#>  56:  0.565436 -0.744124 -0.915944  0.464898  0.516926 -0.267368  0.764403
#>  57: -0.142441  0.986380 -0.959187  0.179023  0.184234 -2.015487  1.062917
#>  58:  0.449610 -0.099491 -0.769075 -0.539391 -0.006873  0.189082 -1.050795
#>  59:  0.618100 -0.439168 -2.683505 -0.957746  1.735772  0.234917 -0.994984
#>  60: -0.378783  0.744348  1.531720 -1.202093  0.082428  0.681543  0.806601
#>  61: -0.346357  2.444763  0.921607  0.861231 -0.704033  0.610251  0.997658
#>  62: -0.641436  0.043339 -1.187295 -1.339344  0.413983  0.560116 -0.461048
#>  63:  0.402366  0.158722 -0.203531  0.624485 -0.582102  1.985917 -0.892021
#>  64:  0.334889  1.685726 -1.059116 -0.592947 -0.753884  1.619047  0.311166
#>  65:  0.068446  0.193289  0.661301  1.023763 -1.903373  0.186894 -1.231792
#>  66: -0.611944 -0.882818 -0.332906  0.860530  0.308242 -0.141437  0.502593
#>  67:  0.543230 -0.133278  1.264496 -0.663122 -0.405181 -0.746803  1.684135
#>  68: -1.106325  0.404407  0.990355 -0.435484  0.718920  0.965741 -2.053853
#>  69: -0.360561  0.609211 -1.928178 -0.934663 -0.756139 -0.879028 -0.629417
#>  70: -0.342652 -1.061653 -0.598284 -1.914276 -0.008274 -0.098032  0.710796
#>  71:  2.227117  1.696409 -1.289007  0.998890 -0.169303  1.019345  1.498547
#>  72: -1.413860  1.410223 -0.109967  0.294895  0.316556 -0.121652 -0.222923
#>  73:  1.249920  0.519783  0.294869  1.442109 -0.529953  0.456449  0.077967
#>  74:  1.146313 -0.570967 -1.400769  0.141037  1.010218  1.741749  0.333853
#>  75: -0.056931 -0.198385  0.818769  2.266482  0.011785  2.061114  1.267259
#>  76:  0.582482 -2.593127  0.837653 -0.659794  1.971097  1.378662  0.875927
#>  77: -0.449376 -1.197001  1.101297 -0.320500  2.608759  1.791927 -0.306598
#>  78: -0.437955 -1.275881 -1.305436 -1.096012  0.711149 -0.855787 -0.396869
#>  79:  0.204910 -0.669991 -0.557275  1.295048 -0.933696 -0.233608  0.270180
#>  80:  0.042636  1.669832  0.900621  0.080041 -0.050675  2.301381 -0.817080
#>  81: -0.139272 -0.241529  0.419947  1.514879 -0.452631  0.857142 -1.917899
#>  82:  1.413752  0.445831 -0.744557 -0.267573  1.483337  0.907279 -0.517595
#>  83:  0.725290 -0.536687 -0.034238  1.192664  1.382043  1.253812  0.269575
#>  84:  0.987208  0.628084  0.887786  1.592171 -0.512487  0.723844  0.150112
#>  85: -0.194773  0.894203 -1.391524 -0.996382 -0.043814  1.678971 -0.106967
#>  86: -0.771525  1.233174  0.249135 -1.013929 -1.091040 -0.677469 -1.541558
#>  87:  1.458821  0.520863 -1.664315  0.391663  0.853451 -0.381682  0.117164
#>  88:  0.409313  1.990056 -1.355402 -0.194529  0.563230 -0.484124  0.266182
#>  89: -0.691749 -0.952480  1.025397  0.305606  1.256291 -0.541260  2.029844
#>  90:  0.037466  0.625552 -1.391470  0.193761 -1.103960 -0.199618 -2.410035
#>  91: -0.619324  0.733247 -1.719858 -0.344900  0.366664  1.646931 -1.020434
#>  92:  0.145205 -0.581965 -0.885423 -1.197448 -0.516070 -0.879529  0.331663
#>  93:  1.084440  0.983395 -1.508749 -0.961515  0.914284  0.449303 -1.248321
#>  94: -0.478056  0.428493  0.133504 -1.550929  1.307789  1.834468  1.811659
#>  95:  0.117106  0.449927 -0.660418 -0.019580 -0.838963 -1.788062  1.262700
#>  96:  0.472257  1.196945  0.606116  0.594261  0.402567  0.902497  0.419379
#>  97: -0.557529 -0.075401  0.218462  1.172127 -1.090599 -1.008859 -0.683376
#>  98: -1.691285  0.645190 -0.816992 -0.690283  0.548400  1.432515  0.182231
#>  99: -0.207965 -0.236807 -0.498946  0.698759 -1.377343  0.801679  0.088018
#> 100: -0.851645  0.146521  0.047505 -1.379739  2.178992  0.372175  0.721259
#>      p22009_a1 p22009_a2 p22009_a3 p22009_a4 p22009_a5 p22009_a6 p22009_a7
#>          <num>     <num>     <num>     <num>     <num>     <num>     <num>
#>      p22009_a8 p22009_a9 p22009_a10   grs_bmi dm_status    dm_date dm_timing
#>          <num>     <num>      <num>     <num>    <lgcl>     <IDat>     <int>
#>   1: -0.513748  0.046552   0.787167  1.112519     FALSE       <NA>         0
#>   2: -0.145144 -1.121485  -0.837124 -2.007132      TRUE 1998-09-15         1
#>   3:  0.390236 -0.781560   0.168652  3.795837     FALSE       <NA>         0
#>   4:  0.587041  0.849904  -1.370266 -0.810869      TRUE 2008-11-13         1
#>   5: -0.286372  1.763791  -0.125879 -1.209738     FALSE       <NA>         0
#>   6: -0.495943  0.845642   1.117461 -1.299356     FALSE       <NA>         0
#>   7:  0.924200 -0.544836   0.703672  2.098385     FALSE       <NA>         0
#>   8: -0.072024  0.255268  -0.768516  0.060629     FALSE       <NA>         0
#>   9: -1.055995  0.299373   0.855199 -0.628283     FALSE       <NA>         0
#>  10: -1.390912  0.320643   2.165224 -2.814081     FALSE       <NA>         0
#>  11:  0.909071 -0.039317  -0.142555  4.319070     FALSE       <NA>         0
#>  12:  0.323011 -1.144893   1.208135  2.432015     FALSE       <NA>         0
#>  13:  0.341688  0.560505   0.651923  1.679245     FALSE       <NA>         0
#>  14:  1.220941 -0.593338  -0.236288 -0.262025     FALSE       <NA>         0
#>  15:  1.336775 -1.180515   1.317811 -4.272808     FALSE       <NA>         0
#>  16:  0.700212  0.307627  -2.395244 -0.471017     FALSE       <NA>         0
#>  17: -1.811648 -0.145087  -0.113747  1.552933     FALSE       <NA>         0
#>  18: -0.413141 -0.421328   1.278114 -1.141379     FALSE       <NA>         0
#>  19: -1.779408 -1.176677   0.728602 -2.045139     FALSE       <NA>         0
#>  20:  1.146526 -0.473557   0.726265  4.007615     FALSE       <NA>         0
#>  21: -0.685340  0.935616   1.591013 -3.268891     FALSE       <NA>         0
#>  22: -2.398492  0.912726   0.104937 -1.686300     FALSE       <NA>         0
#>  23: -0.224778 -0.750590   0.504524 -1.712540     FALSE       <NA>         0
#>  24: -0.470312 -1.067609   0.750711 -1.356506     FALSE       <NA>         0
#>  25:  0.868934 -1.393820  -0.828815  2.930402     FALSE       <NA>         0
#>  26: -0.414759  0.102401   0.709549 -3.341034     FALSE       <NA>         0
#>  27:  1.976477  1.193254   0.949915  0.320075     FALSE       <NA>         0
#>  28:  0.460253 -1.152602  -0.578856 -0.175955     FALSE       <NA>         0
#>  29: -1.133249  1.448074  -1.234602  4.131925     FALSE       <NA>         0
#>  30: -1.784115  1.147506  -0.218770  2.916791     FALSE       <NA>         0
#>  31: -0.393233  0.317042   0.040909 -0.687064     FALSE       <NA>         0
#>  32: -0.766540  0.059312  -0.641766  3.139010     FALSE       <NA>         0
#>  33: -0.380048  1.083632  -0.961509 -1.826761     FALSE       <NA>         0
#>  34:  0.369668 -0.552428   0.674827 -2.582297     FALSE       <NA>         0
#>  35: -0.624760 -0.500888  -0.916078  3.194869     FALSE       <NA>         0
#>  36: -1.484233 -0.183452   0.285324  1.119072     FALSE       <NA>         0
#>  37:  1.619381 -0.235934   0.357701 -3.707059     FALSE       <NA>         0
#>  38:  1.738407  0.183452   1.114078  2.044085     FALSE       <NA>         0
#>  39:  2.400472  0.972897  -0.011303 -0.378932     FALSE       <NA>         0
#>  40:  0.778690  0.109329  -2.020795 -0.143612     FALSE       <NA>         0
#>  41: -0.313916 -1.670299   0.617905  3.930156     FALSE       <NA>         0
#>  42:  0.014044  0.851406  -0.112820 -0.293229     FALSE       <NA>         0
#>  43: -1.114417  1.893908   1.595115  0.117318     FALSE       <NA>         0
#>  44:  0.910697 -2.493136   0.543894 -0.710083      TRUE 1992-09-04         1
#>  45: -1.713390  1.438513  -1.656857  1.646235     FALSE       <NA>         0
#>  46: -1.305510  0.500697   0.102100  2.050548     FALSE       <NA>         0
#>  47:  1.507239  0.692184  -1.054246  2.585712     FALSE       <NA>         0
#>  48:  3.133248 -0.566944  -2.054017  0.800476     FALSE       <NA>         0
#>  49:  0.113771  0.944947   0.827422 -0.345213     FALSE       <NA>         0
#>  50:  1.857904  0.818692  -1.941544 -5.237289     FALSE       <NA>         0
#>  51: -1.006754  0.015412   1.628972  3.376442     FALSE       <NA>         0
#>  52:  0.963567  1.054929  -0.361928  3.324530     FALSE       <NA>         0
#>  53: -0.296041  0.702285  -0.627071  2.386326      TRUE 2022-09-14         2
#>  54: -1.570503 -0.066376  -0.913173 -0.304495     FALSE       <NA>         0
#>  55: -0.300049  1.407734  -1.665463  3.023763     FALSE       <NA>         0
#>  56: -0.209713  0.561766   0.416811  3.605354     FALSE       <NA>         0
#>  57: -1.135752 -0.203529  -1.711356  1.395993     FALSE       <NA>         0
#>  58:  0.243609 -1.510867   0.320175  0.708307     FALSE       <NA>         0
#>  59:  0.098203  0.596490  -1.038427 -3.976459     FALSE       <NA>         0
#>  60:  1.521948 -1.278926   0.522365  4.620757     FALSE       <NA>         0
#>  61:  1.129567 -1.163182   0.745140  1.455922     FALSE       <NA>         0
#>  62:  0.522403 -0.834386   0.233473  1.807813     FALSE       <NA>         0
#>  63:  0.721989 -2.020874  -2.053818  3.331116      TRUE 2008-09-22         2
#>  64: -1.186532 -0.033770  -1.488432  0.534639     FALSE       <NA>         0
#>  65:  2.117013 -0.901183   2.125311 -1.445652      TRUE 2022-09-19         2
#>  66: -1.362718 -1.184255   1.626202  0.183381     FALSE       <NA>         0
#>  67: -0.151830 -0.448417  -0.019244 -1.733684     FALSE       <NA>         0
#>  68: -1.571536  0.558629   0.938659  2.451179     FALSE       <NA>         0
#>  69: -0.488841  0.093082  -1.198031  0.222814     FALSE       <NA>         0
#>  70:  2.181226  0.596114   0.647176  0.506829     FALSE       <NA>         0
#>  71:  0.508018 -0.684097  -0.795558  0.010229     FALSE       <NA>         0
#>  72: -0.348058  0.362708  -0.871621  3.583781     FALSE       <NA>         0
#>  73:  0.757766  1.534152   0.066684 -2.293654      TRUE 2014-04-04         2
#>  74: -0.642032 -1.054193   0.648037  0.384359     FALSE       <NA>         0
#>  75:  0.596727 -0.033242  -0.569110 -2.999100     FALSE       <NA>         0
#>  76: -0.157263  0.945490  -0.597577  0.751620      TRUE 2008-09-11         2
#>  77: -1.238714  0.239258   1.026813  0.795372     FALSE       <NA>         0
#>  78:  1.478998  1.559877   1.680177  1.735415     FALSE       <NA>         0
#>  79: -0.116865  1.346588   0.056694  0.865389     FALSE       <NA>         0
#>  80: -0.213269 -0.592909  -1.279846  2.458429     FALSE       <NA>         0
#>  81: -1.259517  0.541914  -0.125757  0.790624     FALSE       <NA>         0
#>  82:  1.547862 -0.927617   0.613150  1.072206     FALSE       <NA>         0
#>  83: -1.060049 -0.416424  -1.241282  4.260138     FALSE       <NA>         0
#>  84:  0.417718  1.007493  -0.705653  2.923568     FALSE       <NA>         0
#>  85:  0.979285 -0.046593   1.196560  4.501097     FALSE       <NA>         0
#>  86:  1.625200  0.407063   1.969152  2.616720     FALSE       <NA>         0
#>  87:  1.092664  0.834942  -1.303630 -0.435218     FALSE       <NA>         0
#>  88:  1.181383 -1.083633  -0.477963  1.027267     FALSE       <NA>         0
#>  89:  0.351038 -0.583397   0.140972 -3.391506     FALSE       <NA>         0
#>  90: -0.229348  0.779649   0.347427  1.341631     FALSE       <NA>         0
#>  91: -1.079871 -0.114588  -0.049849  0.500136     FALSE       <NA>         0
#>  92:  0.163908 -0.602883  -0.711819  3.363004     FALSE       <NA>         0
#>  93:  0.551015 -0.071739   0.887205  2.162489     FALSE       <NA>         0
#>  94: -1.030558 -1.962338   0.611096  3.617868     FALSE       <NA>         0
#>  95:  0.817969 -1.081126   0.026018  6.621269     FALSE       <NA>         0
#>  96: -0.479302  0.151172   0.197983 -1.286283     FALSE       <NA>         0
#>  97:  0.382433 -1.752126  -0.799891  0.559932     FALSE       <NA>         0
#>  98:  0.005772 -0.008797  -0.020903  0.675616     FALSE       <NA>         0
#>  99: -0.350911  0.177058   0.553070 -0.637142     FALSE       <NA>         0
#> 100: -1.736724 -1.393123  -1.224651  5.190728      TRUE 1992-04-25         1
#>      p22009_a8 p22009_a9 p22009_a10   grs_bmi dm_status    dm_date dm_timing
#>          <num>     <num>      <num>     <num>    <lgcl>     <IDat>     <int>
#>      dm_followup_end dm_followup_years htn_status   htn_date htn_timing
#>               <IDat>             <num>     <lgcl>     <IDat>      <int>
#>   1:      2022-10-31           16.6078      FALSE       <NA>          0
#>   2:      2022-10-31                NA      FALSE       <NA>          0
#>   3:      2022-10-31           15.9425      FALSE       <NA>          0
#>   4:      2022-10-31                NA      FALSE       <NA>          0
#>   5:      2022-10-31           13.0431      FALSE       <NA>          0
#>   6:      2022-10-31           14.2286       TRUE 2010-04-08          2
#>   7:      2022-10-31           16.0219       TRUE 2011-01-07          2
#>   8:      2022-10-31           16.4244      FALSE       <NA>          0
#>   9:      2022-10-31           14.1054      FALSE       <NA>          0
#>  10:      2022-10-31           12.4709       TRUE 2020-12-31          2
#>  11:      2022-10-31           16.5585      FALSE       <NA>          0
#>  12:      2022-10-31           14.0972       TRUE 2009-09-10          2
#>  13:      2022-10-31           16.0164      FALSE       <NA>          0
#>  14:      2022-10-31           15.7317      FALSE       <NA>          0
#>  15:      2022-10-31           16.5832      FALSE       <NA>          0
#>  16:      2022-10-31           14.6940       TRUE 2004-02-19          1
#>  17:      2022-10-31           13.5332      FALSE       <NA>          0
#>  18:      2022-10-31           13.8809      FALSE       <NA>          0
#>  19:      2022-10-31           14.5024      FALSE       <NA>          0
#>  20:      2022-10-31           16.0438       TRUE 2016-10-01          2
#>  21:      2022-10-31           14.8611      FALSE       <NA>          0
#>  22:      2022-10-31           11.9535      FALSE       <NA>          0
#>  23:      2022-10-31           16.6680      FALSE       <NA>          0
#>  24:      2022-10-31           13.2485       TRUE 2008-03-09          1
#>  25:      2022-10-31           14.5079      FALSE       <NA>          0
#>  26:      2022-10-31           12.3313       TRUE 2010-12-23          2
#>  27:      2022-10-31           14.1793      FALSE       <NA>          0
#>  28:      2022-10-31           15.8001       TRUE 1995-04-11          1
#>  29:      2022-10-31           15.0856      FALSE       <NA>          0
#>  30:      2022-10-31           15.6632      FALSE       <NA>          0
#>  31:      2022-10-31           15.6222       TRUE 2004-02-21          1
#>  32:      2022-10-31           13.7221      FALSE       <NA>          0
#>  33:      2022-10-31           15.2334       TRUE 1992-04-04          1
#>  34:      2022-10-31           13.2485       TRUE 1996-10-03          1
#>  35:      2022-10-31           14.2286      FALSE       <NA>          0
#>  36:      2022-10-31           12.6242      FALSE       <NA>          0
#>  37:      2022-10-31           13.6427      FALSE       <NA>          0
#>  38:      2022-10-31           12.0630       TRUE 1995-02-05          1
#>  39:      2022-10-31           14.1793      FALSE       <NA>          0
#>  40:      2022-10-31           15.9808       TRUE 2000-10-26          1
#>  41:      2022-10-31           14.3354       TRUE 2005-08-29          1
#>  42:      2022-10-31           15.5346      FALSE       <NA>          0
#>  43:      2022-10-31           14.6119      FALSE       <NA>          0
#>  44:      2022-10-31                NA      FALSE       <NA>          0
#>  45:      2022-10-31           16.7173      FALSE       <NA>          0
#>  46:      2022-10-31           14.7515      FALSE       <NA>          0
#>  47:      2022-10-31           13.3415      FALSE       <NA>          0
#>  48:      2022-10-31           12.8214       TRUE 1990-01-09          1
#>  49:      2022-10-31           12.1971      FALSE       <NA>          0
#>  50:      2022-10-31           16.7639      FALSE       <NA>          0
#>  51:      2022-10-31           14.9076       TRUE 2017-07-22          2
#>  52:      2022-10-31           12.5394      FALSE       <NA>          0
#>  53:      2022-09-14           13.2485      FALSE       <NA>          0
#>  54:      2022-10-31           15.3922      FALSE       <NA>          0
#>  55:      2022-10-31           15.1266       TRUE 2009-11-30          2
#>  56:      2022-10-31           16.1150       TRUE 2009-01-07          2
#>  57:      2022-10-31           12.6489      FALSE       <NA>          0
#>  58:      2022-10-31           14.2505      FALSE       <NA>          0
#>  59:      2022-10-31           16.0137       TRUE 2003-07-05          1
#>  60:      2022-10-31           12.8077      FALSE       <NA>          0
#>  61:      2022-10-31           14.8611      FALSE       <NA>          0
#>  62:      2022-10-31           15.8220      FALSE       <NA>          0
#>  63:      2008-09-22            1.3251      FALSE       <NA>          0
#>  64:      2022-10-31           14.7570      FALSE       <NA>          0
#>  65:      2022-09-19           12.9035      FALSE       <NA>          0
#>  66:      2022-10-31           14.7680      FALSE       <NA>          0
#>  67:      2022-10-31           14.6448      FALSE       <NA>          0
#>  68:      2022-10-31           14.4723       TRUE 2009-12-18          2
#>  69:      2022-10-31           13.4155       TRUE 1998-12-30          1
#>  70:      2022-10-31           14.7132       TRUE 1990-01-03          1
#>  71:      2022-10-31           13.4428       TRUE 1991-11-29          1
#>  72:      2022-10-31           16.0274      FALSE       <NA>          0
#>  73:      2014-04-04            6.5955       TRUE 2021-08-17          2
#>  74:      2022-10-31           12.6105      FALSE       <NA>          0
#>  75:      2022-10-31           14.7406      FALSE       <NA>          0
#>  76:      2008-09-11            0.5530      FALSE       <NA>          0
#>  77:      2022-10-31           15.3374       TRUE 2016-10-05          2
#>  78:      2022-10-31           15.6660       TRUE 2004-02-08          1
#>  79:      2022-10-31           15.5428      FALSE       <NA>          0
#>  80:      2022-10-31           16.3176      FALSE       <NA>          0
#>  81:      2022-10-31           16.1369      FALSE       <NA>          0
#>  82:      2022-10-31           16.0986      FALSE       <NA>          0
#>  83:      2022-10-31           15.0801       TRUE 2004-10-01          1
#>  84:      2022-10-31           12.9062      FALSE       <NA>          0
#>  85:      2022-10-31           16.7201      FALSE       <NA>          0
#>  86:      2022-10-31           13.5003      FALSE       <NA>          0
#>  87:      2022-10-31           12.4463      FALSE       <NA>          0
#>  88:      2022-10-31           14.5763      FALSE       <NA>          0
#>  89:      2022-10-31           15.0144       TRUE 2012-08-25          2
#>  90:      2022-10-31           13.7604      FALSE       <NA>          0
#>  91:      2022-10-31           15.3621       TRUE 1996-02-12          1
#>  92:      2022-10-31           15.8795      FALSE       <NA>          0
#>  93:      2022-10-31           16.5394      FALSE       <NA>          0
#>  94:      2022-10-31           15.9644       TRUE 1997-07-21          1
#>  95:      2022-10-31           13.9904      FALSE       <NA>          0
#>  96:      2022-10-31           16.3888       TRUE 2008-10-08          2
#>  97:      2022-10-31           15.0910      FALSE       <NA>          0
#>  98:      2022-10-31           14.8994      FALSE       <NA>          0
#>  99:      2022-10-31           12.3669       TRUE 2001-01-30          1
#> 100:      2022-10-31                NA      FALSE       <NA>          0
#>      dm_followup_end dm_followup_years htn_status   htn_date htn_timing
#>               <IDat>             <num>     <lgcl>     <IDat>      <int>
#>      htn_followup_end htn_followup_years age_at_dm
#>                <IDat>              <num>     <num>
#>   1:       2022-10-31            16.6078        NA
#>   2:       2022-10-31            14.3299  39.20397
#>   3:       2022-10-31            15.9425        NA
#>   4:       2022-10-31            12.3258  65.36277
#>   5:       2022-10-31            13.0431        NA
#>   6:       2010-04-08             1.6646        NA
#>   7:       2011-01-07             4.2081        NA
#>   8:       2022-10-31            16.4244        NA
#>   9:       2022-10-31            14.1054        NA
#>  10:       2020-12-31            10.6393        NA
#>  11:       2022-10-31            16.5585        NA
#>  12:       2009-09-10             0.9582        NA
#>  13:       2022-10-31            16.0164        NA
#>  14:       2022-10-31            15.7317        NA
#>  15:       2022-10-31            16.5832        NA
#>  16:       2022-10-31                 NA        NA
#>  17:       2022-10-31            13.5332        NA
#>  18:       2022-10-31            13.8809        NA
#>  19:       2022-10-31            14.5024        NA
#>  20:       2016-10-01             9.9630        NA
#>  21:       2022-10-31            14.8611        NA
#>  22:       2022-10-31            11.9535        NA
#>  23:       2022-10-31            16.6680        NA
#>  24:       2022-10-31                 NA        NA
#>  25:       2022-10-31            14.5079        NA
#>  26:       2010-12-23             0.4764        NA
#>  27:       2022-10-31            14.1793        NA
#>  28:       2022-10-31                 NA        NA
#>  29:       2022-10-31            15.0856        NA
#>  30:       2022-10-31            15.6632        NA
#>  31:       2022-10-31                 NA        NA
#>  32:       2022-10-31            13.7221        NA
#>  33:       2022-10-31                 NA        NA
#>  34:       2022-10-31                 NA        NA
#>  35:       2022-10-31            14.2286        NA
#>  36:       2022-10-31            12.6242        NA
#>  37:       2022-10-31            13.6427        NA
#>  38:       2022-10-31                 NA        NA
#>  39:       2022-10-31            14.1793        NA
#>  40:       2022-10-31                 NA        NA
#>  41:       2022-10-31                 NA        NA
#>  42:       2022-10-31            15.5346        NA
#>  43:       2022-10-31            14.6119        NA
#>  44:       2022-10-31            12.5120  38.35729
#>  45:       2022-10-31            16.7173        NA
#>  46:       2022-10-31            14.7515        NA
#>  47:       2022-10-31            13.3415        NA
#>  48:       2022-10-31                 NA        NA
#>  49:       2022-10-31            12.1971        NA
#>  50:       2022-10-31            16.7639        NA
#>  51:       2017-07-22             9.6318        NA
#>  52:       2022-10-31            12.5394        NA
#>  53:       2022-10-31            13.3771  60.24846
#>  54:       2022-10-31            15.3922        NA
#>  55:       2009-11-30             2.2094        NA
#>  56:       2009-01-07             2.3025        NA
#>  57:       2022-10-31            12.6489        NA
#>  58:       2022-10-31            14.2505        NA
#>  59:       2022-10-31                 NA        NA
#>  60:       2022-10-31            12.8077        NA
#>  61:       2022-10-31            14.8611        NA
#>  62:       2022-10-31            15.8220        NA
#>  63:       2022-10-31            15.4305  68.32512
#>  64:       2022-10-31            14.7570        NA
#>  65:       2022-10-31            13.0185  56.90349
#>  66:       2022-10-31            14.7680        NA
#>  67:       2022-10-31            14.6448        NA
#>  68:       2009-12-18             1.6044        NA
#>  69:       2022-10-31                 NA        NA
#>  70:       2022-10-31                 NA        NA
#>  71:       2022-10-31                 NA        NA
#>  72:       2022-10-31            16.0274        NA
#>  73:       2021-08-17            13.9658  76.59548
#>  74:       2022-10-31            12.6105        NA
#>  75:       2022-10-31            14.7406        NA
#>  76:       2022-10-31            14.6886  64.55305
#>  77:       2016-10-05             9.2676        NA
#>  78:       2022-10-31                 NA        NA
#>  79:       2022-10-31            15.5428        NA
#>  80:       2022-10-31            16.3176        NA
#>  81:       2022-10-31            16.1369        NA
#>  82:       2022-10-31            16.0986        NA
#>  83:       2022-10-31                 NA        NA
#>  84:       2022-10-31            12.9062        NA
#>  85:       2022-10-31            16.7201        NA
#>  86:       2022-10-31            13.5003        NA
#>  87:       2022-10-31            12.4463        NA
#>  88:       2022-10-31            14.5763        NA
#>  89:       2012-08-25             4.8323        NA
#>  90:       2022-10-31            13.7604        NA
#>  91:       2022-10-31                 NA        NA
#>  92:       2022-10-31            15.8795        NA
#>  93:       2022-10-31            16.5394        NA
#>  94:       2022-10-31                 NA        NA
#>  95:       2022-10-31            13.9904        NA
#>  96:       2008-10-08             2.3272        NA
#>  97:       2022-10-31            15.0910        NA
#>  98:       2022-10-31            14.8994        NA
#>  99:       2022-10-31                 NA        NA
#> 100:       2022-10-31            12.5394  41.02327
#>      htn_followup_end htn_followup_years age_at_dm
#>                <IDat>              <num>     <num>
```
