# Derive a unified ICD-10 disease flag across multiple UKB data sources

A high-level wrapper that calls one or more of
[`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md),
[`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md),
[`derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md),
and
[`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md)
according to the `source` argument, then combines their results into a
single status flag and earliest-date column.

## Usage

``` r
derive_icd10(
  data,
  name,
  icd10,
  source = c("hes", "death", "first_occurrence", "cancer_registry"),
  match = c("prefix", "exact", "regex"),
  fo_field = NULL,
  fo_col = NULL,
  histology = NULL,
  behaviour = NULL,
  hes_code_col = NULL,
  hes_date_cols = NULL,
  primary_cols = NULL,
  secondary_cols = NULL,
  death_date_cols = NULL,
  cr_code_cols = NULL,
  cr_hist_cols = NULL,
  cr_behv_cols = NULL,
  cr_date_cols = NULL
)
```

## Arguments

- data:

  (data.frame or data.table) UKB phenotype data.

- name:

  (character) Output column prefix, e.g. `"disease"` produces
  `disease_icd10` and `disease_icd10_date`, plus intermediate columns
  such as `disease_hes`, `disease_hes_date`, etc.

- icd10:

  (character) ICD-10 code(s) to match. For `"prefix"` and `"exact"`,
  supply a vector such as `c("L20", "L21")`. For `"regex"`, supply a
  single regex string. When `"cancer_registry"` is included in `source`,
  `icd10` and `match` are automatically converted to a regex and passed
  to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- source:

  (character) One or more of `"hes"`, `"death"`, `"first_occurrence"`,
  `"cancer_registry"`. Defaults to all four.

- match:

  (character) Matching strategy passed to `derive_hes` and
  `derive_death_registry`: `"prefix"` (default), `"exact"`, or
  `"regex"`.

- fo_field:

  (integer or character or NULL) UKB field ID for the First Occurrence
  column (e.g. `131666L` for E11). Required when `"first_occurrence"` is
  in `source` and `fo_col` is `NULL`.

- fo_col:

  (character or NULL) Column name of the First Occurrence field in
  `data`. Alternative to `fo_field`.

- histology:

  (integer vector or NULL) Passed to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).
  Ignored for other sources.

- behaviour:

  (integer vector or NULL) Passed to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).
  Ignored for other sources.

- hes_code_col:

  (character or NULL) Passed as `disease_cols` to
  [`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md).

- hes_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_hes`](https://evanbio.github.io/ukbflow/reference/derive_hes.md).

- primary_cols:

  (character or NULL) Passed to
  [`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md).

- secondary_cols:

  (character or NULL) Passed to
  [`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md).

- death_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_death_registry`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md).

- cr_code_cols:

  (character or NULL) Passed as `code_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- cr_hist_cols:

  (character or NULL) Passed as `hist_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- cr_behv_cols:

  (character or NULL) Passed as `behv_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

- cr_date_cols:

  (character or NULL) Passed as `date_cols` to
  [`derive_cancer_registry`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md).

## Value

The input `data` with `{name}_icd10` (logical) and `{name}_icd10_date`
(IDate) added in-place, plus all intermediate source columns. Always
returns a `data.table`.

## Details

All intermediate source columns (`{name}_hes`, `{name}_death`,
`{name}_fo`, `{name}_cancer` and their `_date` counterparts) are
retained in `data` so that per-source contributions remain traceable.

- `{name}_icd10`:

  Logical flag: `TRUE` if any selected source contains a matching
  record.

- `{name}_icd10_date`:

  Earliest matching date across all selected sources (`IDate`).

## Examples

``` r
# \donttest{
dt <- ops_toy(n = 100)
#> ✔ ops_toy: 100 participants | 75 columns | scenario = "cohort" | seed = 42
derive_icd10(dt, name = "htn",
             icd10  = "I10",
             source = c("hes", "death"))
#> ✔ derive_hes (htn): 7 cases, 7 with date.
#> ! derive_death_registry (htn): 0 cases found.
#> ✔ derive_icd10 (htn): 7 cases across 2 sources, 7 with date.
#> Index: <eid>
#>           eid    p31   p34     p53_i0 p21022 p21001_i0            p20116_i0
#>         <int> <char> <int>     <char>  <int>     <num>               <char>
#>   1: 10000001   Male  1947 2006-07-01     70   32.1921                Never
#>   2: 10000002   Male  1953 2010-02-06     40   12.0000                Never
#>   3: 10000003 Female  1978 2009-02-24     57   35.3399             Previous
#>   4: 10000004   Male  1947 2010-12-28     67   25.6982                Never
#>   5: 10000005   Male  1934 2010-02-25     71   33.4425                Never
#>   6: 10000006 Female  1975 2010-04-28     38   30.5572                Never
#>   7: 10000007   Male  1969 2010-09-12     52   27.2689                Never
#>   8: 10000008 Female  1969 2010-03-10     55   20.0618                Never
#>   9: 10000009   Male  1950 2008-09-18     80   25.5108                Never
#>  10: 10000010   Male  1965 2006-12-03     70   22.4651                Never
#>  11: 10000011 Female  1965 2007-06-23     40   17.0800                Never
#>  12: 10000012   Male  1968 2010-04-15     48   25.9817                Never
#>  13: 10000013   Male  1971 2009-04-18     57   25.0374              Current
#>  14: 10000014 Female  1947 2008-05-17     50   21.2340             Previous
#>  15: 10000015 Female  1956 2006-07-31     65   23.3968              Current
#>  16: 10000016   Male  1942 2010-05-30     71   16.0744                Never
#>  17: 10000017   Male  1948 2006-07-20     51   21.1052             Previous
#>  18: 10000018 Female  1961 2009-11-25     54   31.0512                Never
#>  19: 10000019 Female  1945 2006-03-03     78   33.0471                Never
#>  20: 10000020   Male  1958 2009-07-16     59   20.4181             Previous
#>  21: 10000021   Male  1946 2009-11-06     50   22.5421             Previous
#>  22: 10000022 Female  1973 2009-02-21     73   30.2374             Previous
#>  23: 10000023   Male  1938 2008-12-22     50   23.4009                Never
#>  24: 10000024   Male  1950 2007-07-15     35   23.8501              Current
#>  25: 10000025 Female  1972 2007-07-27     76   22.7689              Current
#>  26: 10000026 Female  1977 2010-07-10     70   27.2887                Never
#>  27: 10000027 Female  1937 2010-11-28     39   34.4533             Previous
#>  28: 10000028   Male  1958 2007-06-24     53   19.9263             Previous
#>  29: 10000029 Female  1967 2006-01-02     79   28.9327              Current
#>  30: 10000030   Male  1930 2007-11-02     36   33.9460              Current
#>  31: 10000031   Male  1942 2010-07-30     43   22.7715                Never
#>  32: 10000032   Male  1943 2009-02-24     41   22.1209             Previous
#>  33: 10000033 Female  1934 2009-05-16     80   28.2715                Never
#>  34: 10000034   Male  1938 2008-02-10     39   18.9940                Never
#>  35: 10000035 Female  1945 2008-01-11     54   26.6297             Previous
#>  36: 10000036   Male  1955 2006-09-26     66   21.8252             Previous
#>  37: 10000037 Female  1972 2008-11-01     31   35.9157             Previous
#>  38: 10000038 Female  1971 2007-12-06     64   21.0497                Never
#>  39: 10000039   Male  1971 2007-11-01     63   30.0716                Never
#>  40: 10000040   Male  1962 2010-05-06     56   22.0429                Never
#>  41: 10000041 Female  1958 2007-03-20     75   23.6251             Previous
#>  42: 10000042 Female  1954 2007-11-08     60   21.5553              Current
#>  43: 10000043 Female  1980 2010-05-02     56   20.1965              Current
#>  44: 10000044   Male  1961 2009-05-06     45   18.9216                Never
#>  45: 10000045 Female  1946 2008-06-30     65   22.9462             Previous
#>  46: 10000046   Male  1975 2008-10-30     53   30.3157             Previous
#>  47: 10000047   Male  1943 2008-08-24     67   21.6816             Previous
#>  48: 10000048   Male  1976 2009-07-02     50   16.4947                Never
#>  49: 10000049   Male  1935 2009-05-09     49   24.0631                Never
#>  50: 10000050   Male  1976 2010-11-04     40   22.5190                Never
#>  51: 10000051 Female  1972 2010-03-19     62   30.0748             Previous
#>  52: 10000052 Female  1966 2008-04-29     43   21.6480                Never
#>  53: 10000053 Female  1945 2006-06-30     57   12.0000             Previous
#>  54: 10000054   Male  1978 2008-01-21     62   28.0840                Never
#>  55: 10000055 Female  1978 2009-07-31     58   15.5790                Never
#>  56: 10000056   Male  1979 2010-11-23     65   27.1776                Never
#>  57: 10000057   Male  1960 2007-04-08     74   33.9104             Previous
#>  58: 10000058 Female  1963 2007-08-28     61   28.2519                Never
#>  59: 10000059 Female  1959 2009-08-29     67   25.9327                Never
#>  60: 10000060 Female  1961 2006-03-25     51   39.7490                Never
#>  61: 10000061   Male  1935 2008-09-11     73   29.3218             Previous
#>  62: 10000062   Male  1951 2007-04-09     36   31.5286                Never
#>  63: 10000063   Male  1967 2008-09-10     73   40.7828              Current
#>  64: 10000064   Male  1960 2006-08-13     34   26.0103 Prefer not to answer
#>  65: 10000065   Male  1935 2010-05-16     60   23.9471              Current
#>  66: 10000066 Female  1949 2009-01-30     61   25.6299                Never
#>  67: 10000067 Female  1944 2006-06-20     47   23.0394                Never
#>  68: 10000068   Male  1963 2007-05-04     68   23.3766                Never
#>  69: 10000069   Male  1971 2010-08-13     42   25.8959             Previous
#>  70: 10000070 Female  1952 2008-07-10     59   20.8186             Previous
#>  71: 10000071 Female  1941 2007-11-25     31   26.5229              Current
#>  72: 10000072 Female  1955 2010-05-10     57   26.5400              Current
#>  73: 10000073 Female  1970 2010-05-09     32   24.1073             Previous
#>  74: 10000074 Female  1930 2008-10-19     62   33.9993             Previous
#>  75: 10000075 Female  1931 2010-09-05     76   21.6981              Current
#>  76: 10000076   Male  1953 2009-12-15     58   23.6863              Current
#>  77: 10000077 Female  1963 2010-04-28     49   27.3962                Never
#>  78: 10000078 Female  1954 2009-05-15     72   29.6378                Never
#>  79: 10000079 Female  1957 2009-01-13     38   29.0456             Previous
#>  80: 10000080 Female  1972 2006-06-02     39   25.1804              Current
#>  81: 10000081   Male  1943 2008-08-18     36   25.8478                Never
#>  82: 10000082 Female  1963 2006-08-28     80   22.3258                Never
#>  83: 10000083 Female  1931 2006-02-18     57   22.3517                Never
#>  84: 10000084   Male  1960 2009-03-08     47   29.2850                Never
#>  85: 10000085   Male  1961 2006-06-05     54   26.4631                Never
#>  86: 10000086   Male  1956 2006-10-01     73   29.3183                Never
#>  87: 10000087 Female  1939 2010-05-10     39   19.6211                Never
#>  88: 10000088 Female  1957 2009-06-03     38   31.4778             Previous
#>  89: 10000089 Female  1966 2008-02-01     48   28.9899                Never
#>  90: 10000090 Female  1939 2006-06-19     44   24.1424              Current
#>  91: 10000091   Male  1978 2006-10-19     75   34.0125              Current
#>  92: 10000092 Female  1978 2006-05-28     32   35.5191 Prefer not to answer
#>  93: 10000093 Female  1934 2007-12-20     51   29.0423             Previous
#>  94: 10000094   Male  1964 2006-07-08     49   25.9354                Never
#>  95: 10000095   Male  1943 2009-02-10     71   19.1586                Never
#>  96: 10000096   Male  1943 2008-11-16     63   23.5068             Previous
#>  97: 10000097 Female  1957 2007-08-29     52   33.2823             Previous
#>  98: 10000098 Female  1962 2007-10-07     46   31.3178              Current
#>  99: 10000099   Male  1966 2009-01-14     47   30.1938                Never
#> 100: 10000100   Male  1964 2010-07-08     48   25.1382                Never
#>           eid    p31   p34     p53_i0 p21022 p21001_i0            p20116_i0
#>         <int> <char> <int>     <char>  <int>     <num>               <char>
#>                        p1558_i0 p21000_i0 p22189     p54_i0 p22009_a1 p22009_a2
#>                          <char>    <char>  <num>     <char>     <num>     <num>
#>   1: One to three times a month     White  -3.96  Liverpool  1.303365 -2.277778
#>   2: Three or four times a week     White  -1.73      Leeds -1.500221  0.290524
#>   3:       Once or twice a week     Asian  -0.68 Manchester -0.606989  0.422306
#>   4: Three or four times a week     White  -4.20  Newcastle -0.292245  1.294737
#>   5:       Once or twice a week     White  -2.31 Nottingham -1.289683  0.164714
#>   6:     Special occasions only     White  -4.98  Edinburgh  0.694106  0.204954
#>   7:       Once or twice a week     White  -7.00 Manchester -0.599182  0.604604
#>   8:      Daily or almost daily     White   1.33      Leeds  1.256907 -0.019141
#>   9:      Daily or almost daily     White  -3.60     Oxford  0.053508 -0.079714
#>  10:     Special occasions only     Asian  -4.97  Edinburgh  0.728093  0.115984
#>  11:      Daily or almost daily     White   2.50  Sheffield  1.561098  0.744173
#>  12: One to three times a month     Asian  -5.44 Birmingham  0.265625 -0.431291
#>  13: One to three times a month     White   2.13     Oxford  1.076726 -0.499529
#>  14: Three or four times a week     White  -4.79      Leeds  0.210698 -0.865162
#>  15:       Once or twice a week     White  -6.30  Edinburgh -1.511674 -0.957757
#>  16:     Special occasions only     Asian  -7.00     Oxford  0.022402  0.326800
#>  17:       Once or twice a week     White  -6.20  Sheffield  0.718136  1.547372
#>  18: Three or four times a week     White  -0.98 Nottingham  0.489457 -0.968860
#>  19: One to three times a month     White  -7.00  Newcastle -0.173888 -0.188440
#>  20: Three or four times a week     White   0.56     Oxford -1.217699 -1.030001
#>  21:       Once or twice a week     White   1.53  Liverpool  0.646398  0.908086
#>  22:                      Never     White  -0.78  Edinburgh -0.916456 -0.317382
#>  23: Three or four times a week     White  -4.05 Manchester -1.251823  0.179004
#>  24:     Special occasions only     White   1.82     Oxford  0.594928  0.348028
#>  25:       Once or twice a week     White  -3.28 Manchester -1.232811 -1.054279
#>  26: One to three times a month     White  -2.99  Liverpool  0.244364 -0.104744
#>  27:       Once or twice a week     Asian  -6.92  Liverpool  0.002772 -0.228343
#>  28: Three or four times a week     White  -2.89 Birmingham -1.328210  0.675356
#>  29:       Once or twice a week     White  -2.33      Leeds  1.179696 -1.233245
#>  30:                      Never     White  -6.67    Bristol -0.592805 -1.199962
#>  31:       Once or twice a week     White   2.96    Bristol  1.199978  0.765867
#>  32:      Daily or almost daily     White  -4.35     Oxford -0.475034 -0.588098
#>  33:      Daily or almost daily     White  -4.72 Manchester -0.575057 -0.660296
#>  34:       Once or twice a week     White  -0.94  Edinburgh -0.031226  0.113014
#>  35: One to three times a month     White  -0.19 Manchester -0.358057 -0.320399
#>  36: One to three times a month     White  -5.67      Leeds -0.356601  1.866381
#>  37:       Once or twice a week     Other  -2.56 Nottingham -0.877664  0.259531
#>  38: One to three times a month     White  -0.29 Manchester -1.212897  0.161560
#>  39:       Once or twice a week     White  -4.02 Nottingham  0.613287  0.931075
#>  40: Three or four times a week     White   1.92  Newcastle -0.806203 -0.059947
#>  41: One to three times a month     White  -7.00 Birmingham -1.376457  0.048740
#>  42:       Once or twice a week     White  -3.93    Bristol -0.507848 -1.072875
#>  43:      Daily or almost daily     White   0.27     Oxford -0.800935 -2.292971
#>  44: One to three times a month     Other   1.67  Newcastle -2.192786 -1.207207
#>  45: One to three times a month     Asian  -1.08 Nottingham -0.290937  0.114109
#>  46:     Special occasions only     White  -3.10      Leeds  0.167174 -1.033297
#>  47: One to three times a month     White   2.76 Nottingham  0.294692  0.688808
#>  48:      Daily or almost daily     Mixed  -6.52  Edinburgh  0.392741  0.725083
#>  49:       Once or twice a week     White   0.34 Nottingham -1.000844  0.217380
#>  50:       Once or twice a week     White  -3.52    Bristol -0.325727 -0.201657
#>  51: One to three times a month     White  -0.32 Manchester -1.008349 -1.365690
#>  52:       Once or twice a week     White  -6.85 Birmingham -0.635431 -0.308938
#>  53: One to three times a month     Mixed   3.94  Sheffield -1.209841 -0.452903
#>  54: Three or four times a week     Mixed   0.18  Sheffield -1.116464  0.663229
#>  55:       Once or twice a week     White  -6.71  Edinburgh  0.629881  1.308630
#>  56:       Once or twice a week     White  -5.39     Oxford -0.272522  0.501040
#>  57:      Daily or almost daily     White   4.72  Newcastle -0.258841 -1.128289
#>  58:       Once or twice a week     White   0.61 Nottingham  1.729558  1.670997
#>  59:       Once or twice a week     White  -7.00 Birmingham -0.058392  1.010353
#>  60:       Once or twice a week     White  -1.03     Oxford -0.537064  0.223521
#>  61:       Once or twice a week     White  -6.72     Oxford  0.747287 -2.206485
#>  62:       Once or twice a week     White  -7.00  Newcastle -0.487258 -0.954586
#>  63: Three or four times a week     Other  -1.09  Newcastle  1.372908 -0.068573
#>  64:       Once or twice a week     Asian  -1.26 Birmingham -0.377672  0.761306
#>  65: Three or four times a week     Other  -5.65      Leeds -0.616153 -1.179904
#>  66: One to three times a month     White  -0.78  Edinburgh -1.168125  3.211199
#>  67: One to three times a month     White   0.13 Nottingham  0.328640 -2.553825
#>  68:       Once or twice a week     White  -5.96 Manchester  1.466511 -0.235934
#>  69:     Special occasions only     White  -0.14 Manchester -0.356010 -0.259563
#>  70:      Daily or almost daily     White  -2.18  Newcastle  0.261468 -0.663367
#>  71:       Once or twice a week     White   2.36  Sheffield  0.333329 -0.318991
#>  72:     Special occasions only     White  -2.47     Oxford  1.422193  0.742395
#>  73:                      Never     White   0.81 Birmingham  0.663877 -0.874293
#>  74:       Once or twice a week     White  -5.26    Bristol -1.073655 -2.082814
#>  75: One to three times a month     White   1.31 Birmingham -0.696902  0.093768
#>  76: One to three times a month     White   2.94     Oxford -0.746130 -0.001820
#>  77:       Once or twice a week     White   2.85      Leeds  0.141573 -0.013101
#>  78:       Once or twice a week     White  -2.55      Leeds -0.003947  0.667968
#>  79: Three or four times a week     White   1.28 Nottingham  0.367938 -0.013168
#>  80:                      Never     White   1.16    Bristol -0.657343  0.776047
#>  81:       Once or twice a week     White  -1.64  Sheffield -0.376347 -2.010735
#>  82: One to three times a month     White   0.76  Liverpool  0.741360 -1.128180
#>  83:     Special occasions only     White  -7.00  Edinburgh -0.099607  0.348800
#>  84: Three or four times a week     White  -0.52 Nottingham -0.654290 -0.352898
#>  85: Three or four times a week     White  -6.41 Birmingham  0.971164  0.944775
#>  86:     Special occasions only     White  -1.06  Edinburgh  0.013496 -1.004720
#>  87:       Once or twice a week     White   3.79  Edinburgh -0.916535  0.723903
#>  88: One to three times a month     White   0.39 Birmingham  1.709689 -0.668833
#>  89:      Daily or almost daily     White  -3.54  Liverpool -1.168101 -1.113040
#>  90: Three or four times a week     White  -2.72 Manchester -1.781036 -0.342805
#>  91:      Daily or almost daily     White  -5.25    Bristol -2.253132  0.049779
#>  92:       Prefer not to answer     White  -7.00 Manchester  0.651126 -1.227682
#>  93:     Special occasions only     White   1.45      Leeds -0.532833 -0.764006
#>  94: Three or four times a week     White   3.52     Oxford -0.275559 -1.246182
#>  95:       Once or twice a week     White  -1.21     Oxford  0.289627  1.016774
#>  96: Three or four times a week     White  -4.47  Newcastle -0.466484  0.723613
#>  97:                      Never     Asian  -1.84  Newcastle -1.608060 -1.032527
#>  98:       Once or twice a week     White  -1.72     Oxford -1.949784  0.557346
#>  99:       Once or twice a week     White  -3.53    Bristol -0.340700 -0.255581
#> 100: Three or four times a week     White  -2.42  Sheffield  0.174726 -1.113392
#>                        p1558_i0 p21000_i0 p22189     p54_i0 p22009_a1 p22009_a2
#>                          <char>    <char>  <num>     <char>     <num>     <num>
#>      p22009_a3 p22009_a4 p22009_a5 p22009_a6 p22009_a7 p22009_a8 p22009_a9
#>          <num>     <num>     <num>     <num>     <num>     <num>     <num>
#>   1:  0.421197 -0.914455  0.431134  2.633710 -1.166339  0.475958  0.610679
#>   2: -0.322950  0.528728  0.558312  0.166114  0.041895  0.573154 -0.666510
#>   3:  0.880180  0.835079  0.495961  1.905176  1.246489 -1.018860 -1.059883
#>   4: -0.194864  1.209137  1.661886  0.253718 -1.577971 -0.061872 -0.605839
#>   5:  1.188055  1.299473 -1.055035 -1.459022 -0.253820 -0.538305 -1.056841
#>   6: -0.509765  1.075732  1.508325 -2.227248  0.467831  0.416955  0.533106
#>   7:  0.219548  0.939801 -0.334209  0.649684  1.977530 -1.508277 -1.552093
#>   8:  0.370294  0.163375 -0.064981 -0.999250 -0.615606  1.539170 -0.978489
#>   9:  0.279108 -0.888139  0.081082  0.041972  1.519422  1.346018  0.027218
#>  10:  0.201942 -0.726161 -0.448215  1.777044 -0.432895 -0.842856 -1.715572
#>  11: -0.012997  0.407597 -2.553807  0.347183 -1.031018 -0.669874 -0.504888
#>  12: -0.090865  1.683536 -0.312933 -0.287097 -1.134334 -0.908487 -0.304923
#>  13:  1.365031  1.705980  0.041383 -1.924577 -0.221098 -0.136541  1.346078
#>  14:  0.908131 -1.926167 -1.737728 -0.800649 -0.022415 -0.501038 -0.257537
#>  15: -0.609888 -0.833998  0.549940 -0.575618 -0.322902  0.112638 -0.523287
#>  16:  1.396437  1.419133 -0.597274  0.684206  1.052223 -1.875218 -0.663218
#>  17:  0.144798 -1.064110  1.447742  0.483457  0.189541  0.158547  0.447221
#>  18: -0.640607 -1.613577  0.264868  0.013963 -0.105828  0.015563 -0.319451
#>  19:  0.169802  0.599811 -0.788783  0.180244 -0.602554 -1.600603 -0.543779
#>  20: -0.157187  1.732965  0.167732 -0.288123 -1.296016  0.275973 -0.279673
#>  21:  0.100940  1.934505  0.257583  0.030227 -1.959327  0.054953  1.065233
#>  22: -0.973394  0.532821  0.912047  0.271674  0.213412 -0.230573  1.567829
#>  23: -0.819825  0.719666 -0.156872  0.449158  0.025336 -0.013216 -0.643112
#>  24:  1.362919  0.560093 -2.033376  1.827628  1.365023  0.384949  0.020522
#>  25:  0.961371 -0.018087 -1.299666 -1.112024  0.291094  0.346724 -0.324184
#>  26: -0.883724 -3.371739 -0.857251  1.474807  0.797218 -0.431613  1.857396
#>  27: -0.900092  0.760703  0.426265  0.671512  0.040986  1.150178  0.590764
#>  28:  1.723333 -0.391227 -0.284836 -1.545329 -0.818324 -0.036532 -1.780627
#>  29:  1.909042  1.009901 -0.614369 -0.277047  0.289641 -0.135801 -0.434109
#>  30: -0.777141 -0.626973 -0.844891 -0.629343  0.339787  0.944618 -2.292750
#>  31: -1.302305 -1.634577  0.153695 -0.933000 -0.817393  0.992041 -0.092965
#>  32:  2.623495  1.245243 -0.851432 -1.537886 -0.028749 -0.700670  0.703964
#>  33:  0.229629  0.181377 -0.397921 -0.494102  2.000782 -0.991059 -0.894490
#>  34:  0.186750  3.495304 -0.939977 -0.435360 -1.129266 -0.705618 -1.282507
#>  35:  0.076137  0.915592 -1.388254 -0.323545  1.472179 -1.175776  1.255784
#>  36:  1.404860  1.048507  0.955185 -2.061114 -0.227069 -1.781197 -0.964630
#>  37: -0.191722  0.763825 -1.317495  0.441503  1.482311  0.310608  0.907784
#>  38:  1.459392 -0.603387  0.073029  0.746351 -0.843053 -0.145110  0.214074
#>  39: -0.220655 -0.370430 -0.568186  0.789643 -0.066195  0.642550  0.881023
#>  40:  0.505146  1.059826 -1.058451  0.770741  0.311233 -0.001659  1.002545
#>  41: -1.033497  1.055111  0.259314  0.200506 -0.112590  0.409163  1.139911
#>  42:  0.170473  0.582972  0.373135  1.468350  0.658739 -0.496058  1.236036
#>  43:  1.200668 -0.986567  1.264667 -0.876455 -0.166862 -0.960108  0.295402
#>  44: -0.163406  1.684622  0.325225 -1.226605  1.208873  0.778132  0.171761
#>  45:  1.282476 -1.366841 -0.138467  0.337838  0.170419  0.761121 -0.955389
#>  46:  2.727196 -0.433214  2.602469  0.440824  0.692420 -1.733712 -1.210409
#>  47:  0.941924  2.325058 -0.650284 -0.746516 -1.185547  0.877295 -0.601383
#>  48: -0.248614  0.524122 -1.003183  0.036606 -0.658389 -1.773371 -0.135816
#>  49:  0.096479  0.970733 -0.535114  0.323310  1.089508 -0.045687 -0.987273
#>  50: -0.433931  0.376973 -0.110415  0.379676  0.508786 -0.394872  0.831925
#>  51:  2.178668 -0.995933  0.600430  0.876556 -0.135907 -0.128056 -0.795060
#>  52: -2.958780 -0.597483  0.415845  0.933388 -0.108783  1.096238  0.340465
#>  53:  0.080888  0.165251 -0.105751 -2.428808  0.754900 -1.255218  0.870430
#>  54:  0.110138 -2.928477 -0.856563  1.727994 -0.223811 -0.265484 -1.182161
#>  55:  0.213448 -0.847914  1.127327  0.456003  0.074955  2.553302  1.022894
#>  56: -1.557820  0.798585  0.916282 -0.570360 -1.645955 -1.478306 -2.108435
#>  57:  0.216212 -0.298456 -0.724380 -1.114624  1.774009 -0.626588  0.229763
#>  58:  0.187664 -0.283611  0.686779  0.905064  0.765968 -0.041052  1.511711
#>  59:  1.258622  0.869519  0.450086  0.328096  0.832288  0.199953  0.555438
#>  60:  0.523518 -0.544355  1.045222  1.078090 -1.905458 -0.533306  0.914879
#>  61:  1.115454  0.628803  0.149629 -0.060316 -0.020837 -0.266032 -0.553397
#>  62: -0.957502 -1.422334 -1.141067 -0.243519 -0.408934  1.084148  0.298376
#>  63: -0.124406 -1.227513  0.802499  2.241423 -1.376386 -0.180745  1.106380
#>  64:  0.191738 -1.674106 -0.728717 -2.035993  0.727430  0.251555 -1.329150
#>  65:  0.272217  0.084398  0.527209  0.390914  1.234131  0.369542  1.001694
#>  66: -0.693814 -0.206126  1.673479  0.384813 -0.553224  0.407034 -1.409304
#>  67:  1.479172  1.441872 -1.418828  0.438696 -0.229190  0.492505 -0.498781
#>  68: -0.611767 -0.041782  1.561911  0.558141  1.711462  0.054633  2.622757
#>  69: -1.614310  1.353754  1.353161 -0.276406 -1.649808 -0.708674  0.510666
#>  70:  0.402490  1.945225 -0.528697  1.166288  0.744221 -0.058271 -0.090843
#>  71:  0.664555 -0.490938 -0.251273 -2.454277 -0.314021 -0.963422  0.978766
#>  72:  0.944127  0.388439 -0.685848 -0.805566 -0.115311  0.093393 -0.243809
#>  73: -0.946261 -0.844893 -0.570368 -0.119145 -0.610974 -0.347901  0.621809
#>  74: -0.248288  0.737990  0.579631  0.163216  1.096695 -0.118334 -0.344595
#>  75: -1.328436 -1.079760 -0.898959  0.406480 -1.127168 -1.099091 -2.355225
#>  76:  0.844764 -1.026474 -0.190330  0.639340  0.962609 -0.283076  0.472388
#>  77:  0.347697  0.288793 -0.143903 -1.508518  1.406464 -1.089735 -0.511480
#>  78:  0.913763  0.090811 -0.096573  0.007671 -1.641650 -0.405666 -0.573602
#>  79:  0.608275  0.262623  0.181447  0.524168 -1.126904  0.526907  0.003797
#>  80: -0.607548  0.069335  1.596574  1.326336  0.591545  0.240420  1.342551
#>  81:  0.179658 -0.528644 -0.451332 -0.113568 -0.956309  0.898362  0.295462
#>  82: -1.908409 -0.130202 -0.794880  1.599149 -0.691530  0.487968  0.841787
#>  83:  0.502946  1.620159  0.792284 -0.281528 -0.445353  0.111991  0.629064
#>  84:  0.968899 -0.017895  0.380472 -0.049898 -0.344484  0.998313  0.101598
#>  85: -0.875737 -1.318489  0.235788  0.160214  0.703698  1.191717  0.671121
#>  86: -2.136025 -0.844560  0.590988 -0.502381 -0.603006 -1.399388 -0.138316
#>  87: -1.522828 -1.101815 -1.411930  0.715938  0.089350  0.892148 -1.249312
#>  88: -1.113118 -0.900090  1.063296 -1.345787  0.737495  0.777959  0.347635
#>  89:  1.240984 -1.261084  0.453918 -0.005644 -1.540379  0.941915 -2.277814
#>  90:  0.003482 -2.625849  0.951313 -0.540543 -0.689632 -0.908803 -0.986209
#>  91: -1.237795  0.669066 -0.598518 -0.547074  0.859793  2.408931 -0.059541
#>  92:  0.555699  0.660042 -1.841940  1.151445 -0.376520 -2.594250 -0.160759
#>  93: -2.183149 -0.250600 -0.484590  1.052220 -2.535083  0.006863 -0.420362
#>  94: -0.247024 -0.723797 -0.906847  1.598027 -0.857809  0.118107  0.988591
#>  95:  1.112857 -0.812182  2.222762 -0.263797  0.816026 -0.149697 -1.069614
#>  96: -0.341673  0.398734 -0.413467  0.032401 -0.426589  0.747873 -2.613643
#>  97:  1.305438  0.226564 -0.215674 -1.551583 -0.404637  0.124035  0.780452
#>  98:  1.795324  0.421644  1.062979 -0.388179 -0.145769 -0.778055  0.045105
#>  99: -1.167835  0.004838  0.620347  1.764148  0.719466  1.410033 -0.108489
#> 100: -1.152288  0.618984  0.673067 -0.416528 -0.491091 -0.293912 -0.391224
#>      p22009_a3 p22009_a4 p22009_a5 p22009_a6 p22009_a7 p22009_a8 p22009_a9
#>          <num>     <num>     <num>     <num>     <num>     <num>     <num>
#>      p22009_a10                       p20002_i0_a0
#>           <num>                             <char>
#>   1:  -1.687000                               <NA>
#>   2:  -0.952704                     joint disorder
#>   3:   0.507414 heart attack/myocardial infarction
#>   4:   0.018816                               <NA>
#>   5:  -1.418910                               <NA>
#>   6:   0.598172                               <NA>
#>   7:   0.786380                               <NA>
#>   8:  -0.134633                               <NA>
#>   9:  -0.016387                               <NA>
#>  10:   1.409140                               <NA>
#>  11:   0.394839                               <NA>
#>  12:   1.219875                               <NA>
#>  13:  -0.045077                               <NA>
#>  14:   1.479488                               <NA>
#>  15:  -0.075684                               <NA>
#>  16:   0.917748                               <NA>
#>  17:  -0.344779                               <NA>
#>  18:  -1.077003                               <NA>
#>  19:   1.001605                               <NA>
#>  20:   2.296004                               <NA>
#>  21:  -0.325878       thyroid problem (not cancer)
#>  22:   1.468856                               <NA>
#>  23:  -0.236909                               <NA>
#>  24:   0.923493                               <NA>
#>  25:  -0.989192                               <NA>
#>  26:   0.275646                               <NA>
#>  27:  -0.763661                               <NA>
#>  28:  -1.352112                               <NA>
#>  29:   0.655024                       back problem
#>  30:   1.609647                       back problem
#>  31:  -0.788507                               <NA>
#>  32:  -0.883876                               <NA>
#>  33:  -1.072515                               <NA>
#>  34:  -0.458141                               <NA>
#>  35:   0.665647                       hypertension
#>  36:   0.712228                               <NA>
#>  37:   0.442954                               <NA>
#>  38:   0.759587                               <NA>
#>  39:  -0.468878                               <NA>
#>  40:  -0.172710                               <NA>
#>  41:   0.682050                               <NA>
#>  42:  -0.281577                               <NA>
#>  43:  -0.961623 heart attack/myocardial infarction
#>  44:  -1.377650 heart attack/myocardial infarction
#>  45:   2.697587                               <NA>
#>  46:  -1.699715                               <NA>
#>  47:   0.029317                               <NA>
#>  48:   1.934314                               <NA>
#>  49:   0.837511                       back problem
#>  50:  -0.185346                             asthma
#>  51:   0.533329                               <NA>
#>  52:   1.784956                               <NA>
#>  53:   0.189628                               <NA>
#>  54:  -0.569088                           fracture
#>  55:   1.451893                       back problem
#>  56:   1.868993                               <NA>
#>  57:  -0.984555                     joint disorder
#>  58:   0.718757                               <NA>
#>  59:   0.129347                               <NA>
#>  60:   0.701641                               <NA>
#>  61:   0.526698                               <NA>
#>  62:  -0.020513                               <NA>
#>  63:   0.438251                               <NA>
#>  64:  -1.210529                               <NA>
#>  65:  -1.404420                               <NA>
#>  66:   0.720749                               <NA>
#>  67:   0.086036                               <NA>
#>  68:  -0.131617                       hypertension
#>  69:  -1.676052                               <NA>
#>  70:  -0.569498                               <NA>
#>  71:   0.192205                               <NA>
#>  72:  -0.486323                               <NA>
#>  73:   0.081284                               <NA>
#>  74:   0.384897                               <NA>
#>  75:  -0.137502                               <NA>
#>  76:   0.427593                           fracture
#>  77:  -0.243064                               <NA>
#>  78:  -0.318353                               <NA>
#>  79:  -0.254106                               <NA>
#>  80:   0.638887                               <NA>
#>  81:   0.821065                               <NA>
#>  82:   2.335479                               <NA>
#>  83:  -0.983308                               <NA>
#>  84:  -0.707457                               <NA>
#>  85:   0.644149                               <NA>
#>  86:   1.637665                       hypertension
#>  87:   1.226648                               <NA>
#>  88:  -0.467706                               <NA>
#>  89:  -0.678231                               <NA>
#>  90:   1.696402                               <NA>
#>  91:   1.542847                           fracture
#>  92:   0.214528                               <NA>
#>  93:   1.700688                               <NA>
#>  94:  -0.007987                               <NA>
#>  95:  -0.817900                               <NA>
#>  96:  -0.050610                               <NA>
#>  97:   0.079921                       hypertension
#>  98:  -1.559571                               <NA>
#>  99:  -0.171498                               <NA>
#> 100:  -0.418607                               <NA>
#>      p22009_a10                       p20002_i0_a0
#>           <num>                             <char>
#>                            p20002_i0_a1   p20002_i0_a2
#>                                  <char>         <char>
#>   1:                               <NA>           <NA>
#>   2:                               <NA>           <NA>
#>   3:                               <NA>           <NA>
#>   4:                               <NA>           <NA>
#>   5:                               <NA>           <NA>
#>   6:                               <NA>           <NA>
#>   7:                       hypertension           <NA>
#>   8:                               <NA>           <NA>
#>   9:                               <NA>           <NA>
#>  10:                               <NA>           <NA>
#>  11:                               <NA>           <NA>
#>  12:                               <NA>           <NA>
#>  13:                               <NA>           <NA>
#>  14:                               <NA>           <NA>
#>  15:                               <NA>           <NA>
#>  16:                               <NA>           <NA>
#>  17:                               <NA>           <NA>
#>  18:                     joint disorder           <NA>
#>  19:                               <NA>           <NA>
#>  20:                               <NA>           <NA>
#>  21:                               <NA>           <NA>
#>  22:                             asthma           <NA>
#>  23:                               <NA> joint disorder
#>  24:                               <NA>           <NA>
#>  25:                               <NA>           <NA>
#>  26:                             asthma           <NA>
#>  27:                               <NA>           <NA>
#>  28:                               <NA>           <NA>
#>  29:                               <NA>           <NA>
#>  30:                               <NA>           <NA>
#>  31:                               <NA>           <NA>
#>  32:                               <NA>           <NA>
#>  33:                               <NA>           <NA>
#>  34:                               <NA>           <NA>
#>  35:                           fracture           <NA>
#>  36: heart attack/myocardial infarction           <NA>
#>  37:       thyroid problem (not cancer)           <NA>
#>  38:                               <NA>           <NA>
#>  39:                               <NA>           <NA>
#>  40:                       hypertension           <NA>
#>  41:                               <NA>           <NA>
#>  42:                               <NA>           <NA>
#>  43:                               <NA>           <NA>
#>  44:                     joint disorder           <NA>
#>  45:                       back problem           <NA>
#>  46:                               <NA>           <NA>
#>  47:                               <NA>           <NA>
#>  48:                               <NA>           <NA>
#>  49:                               <NA>           <NA>
#>  50:       thyroid problem (not cancer)           <NA>
#>  51:                               <NA>           <NA>
#>  52:                               <NA>           <NA>
#>  53:                               <NA>           <NA>
#>  54:                               <NA>   back problem
#>  55:                               <NA>           <NA>
#>  56:                               <NA>           <NA>
#>  57:                               <NA>           <NA>
#>  58: heart attack/myocardial infarction           <NA>
#>  59:                               <NA>           <NA>
#>  60:                               <NA>           <NA>
#>  61:                               <NA>           <NA>
#>  62:                               <NA>           <NA>
#>  63:       thyroid problem (not cancer)           <NA>
#>  64:                               <NA>           <NA>
#>  65:                               <NA> joint disorder
#>  66:                               <NA>           <NA>
#>  67:                               <NA>           <NA>
#>  68:                               <NA>           <NA>
#>  69:                           fracture           <NA>
#>  70:                               <NA>           <NA>
#>  71:                               <NA>           <NA>
#>  72:                               <NA>           <NA>
#>  73:                               <NA>           <NA>
#>  74:       thyroid problem (not cancer)           <NA>
#>  75:                               <NA>           <NA>
#>  76:                               <NA>       fracture
#>  77:                       hypertension           <NA>
#>  78:                               <NA>           <NA>
#>  79:                           fracture           <NA>
#>  80:                               <NA>           <NA>
#>  81:                               <NA>           <NA>
#>  82:                               <NA>           <NA>
#>  83:                               <NA>           <NA>
#>  84:                               <NA>           <NA>
#>  85:                       hypertension           <NA>
#>  86:                               <NA>           <NA>
#>  87:                               <NA>           <NA>
#>  88:                             asthma   back problem
#>  89:                               <NA>   hypertension
#>  90:                               <NA>           <NA>
#>  91:                               <NA>           <NA>
#>  92:                               <NA>           <NA>
#>  93:       thyroid problem (not cancer)           <NA>
#>  94:                               <NA>   back problem
#>  95:                               <NA>           <NA>
#>  96:                               <NA>           <NA>
#>  97:                               <NA>           <NA>
#>  98:                               <NA>           <NA>
#>  99:                               <NA>           <NA>
#> 100:                               <NA>           <NA>
#>                            p20002_i0_a1   p20002_i0_a2
#>                                  <char>         <char>
#>                      p20002_i0_a3    p20002_i0_a4 p20008_i0_a0 p20008_i0_a1
#>                            <char>          <char>        <num>        <num>
#>   1:                         <NA>            <NA>           NA           NA
#>   2:                         <NA>            <NA>       2013.5           NA
#>   3:                 back problem            <NA>       2000.5           NA
#>   4:                         <NA>            <NA>           NA           NA
#>   5:                         <NA>            <NA>           NA           NA
#>   6:                         <NA>            <NA>           NA           NA
#>   7:                         <NA>            <NA>           NA       2004.5
#>   8:                         <NA>            <NA>           NA           NA
#>   9:                         <NA>            <NA>           NA           NA
#>  10:                         <NA>            <NA>           NA           NA
#>  11:                         <NA>            <NA>           NA           NA
#>  12:                         <NA>            <NA>           NA           NA
#>  13:                         <NA>            <NA>           NA           NA
#>  14:                         <NA>            <NA>           NA           NA
#>  15:                         <NA>            <NA>           NA           NA
#>  16:                         <NA>            <NA>           NA           NA
#>  17:                         <NA>            <NA>           NA           NA
#>  18:                         <NA>            <NA>           NA       2006.5
#>  19:                         <NA>            <NA>           NA           NA
#>  20:                         <NA>            <NA>           NA           NA
#>  21:                         <NA> type 2 diabetes       2002.5           NA
#>  22:                         <NA>            <NA>           NA       2006.5
#>  23:                         <NA>            <NA>           NA           NA
#>  24:                         <NA>            <NA>           NA           NA
#>  25:                         <NA>            <NA>           NA           NA
#>  26:                         <NA>            <NA>           NA       2014.5
#>  27:                         <NA>            <NA>           NA           NA
#>  28:                         <NA>            <NA>           NA           NA
#>  29:                         <NA>            <NA>       2009.5           NA
#>  30:                         <NA>            <NA>       2001.5           NA
#>  31:                         <NA>            <NA>           NA           NA
#>  32:                         <NA>            <NA>           NA           NA
#>  33:                         <NA> type 2 diabetes           NA           NA
#>  34:                         <NA>            <NA>           NA           NA
#>  35:                         <NA>            <NA>       2003.5       2005.5
#>  36:                         <NA>            <NA>           NA       2014.5
#>  37:                         <NA>            <NA>           NA       2007.5
#>  38:                         <NA>            <NA>           NA           NA
#>  39:                         <NA>            <NA>           NA           NA
#>  40:                         <NA>            <NA>           NA       2009.5
#>  41:                         <NA>            <NA>           NA           NA
#>  42:                         <NA>            <NA>           NA           NA
#>  43:                         <NA>            <NA>       2004.5           NA
#>  44:                         <NA>            <NA>       2005.5       2011.5
#>  45:                         <NA>            <NA>           NA       2005.5
#>  46:               joint disorder            <NA>           NA           NA
#>  47:                         <NA>            <NA>           NA           NA
#>  48:                         <NA>            <NA>           NA           NA
#>  49:                 hypertension            <NA>       2001.5           NA
#>  50:                         <NA>            <NA>       2005.5       2015.5
#>  51:                         <NA>            <NA>           NA           NA
#>  52:                         <NA>            <NA>           NA           NA
#>  53:                 hypertension            <NA>           NA           NA
#>  54:                         <NA>            <NA>       2015.5           NA
#>  55:                         <NA>            <NA>       2009.5           NA
#>  56:                         <NA>            <NA>           NA           NA
#>  57:                         <NA>            <NA>       2004.5           NA
#>  58:                         <NA>            <NA>           NA       2012.5
#>  59:                     fracture            <NA>           NA           NA
#>  60:                         <NA>            <NA>           NA           NA
#>  61:                         <NA>        fracture           NA           NA
#>  62:                         <NA>            <NA>           NA           NA
#>  63:                         <NA>            <NA>           NA       2011.5
#>  64:                         <NA>            <NA>           NA           NA
#>  65:                         <NA>        fracture           NA           NA
#>  66:                         <NA>            <NA>           NA           NA
#>  67:                         <NA>            <NA>           NA           NA
#>  68:                         <NA>            <NA>       2009.5           NA
#>  69:                         <NA>            <NA>           NA       2015.5
#>  70:                         <NA>            <NA>           NA           NA
#>  71:                         <NA>            <NA>           NA           NA
#>  72:                         <NA>            <NA>           NA           NA
#>  73:                         <NA>            <NA>           NA           NA
#>  74:                         <NA>            <NA>           NA       2008.5
#>  75:                         <NA>            <NA>           NA           NA
#>  76:                         <NA>            <NA>       2005.5           NA
#>  77:                         <NA>            <NA>           NA       2001.5
#>  78:                         <NA>            <NA>           NA           NA
#>  79:                         <NA>            <NA>           NA       2005.5
#>  80:                         <NA>            <NA>           NA           NA
#>  81:                         <NA>            <NA>           NA           NA
#>  82:                         <NA>            <NA>           NA           NA
#>  83:                         <NA>            <NA>           NA           NA
#>  84:                         <NA>            <NA>           NA           NA
#>  85:                         <NA>            <NA>           NA       2011.5
#>  86:                         <NA>            <NA>       2010.5           NA
#>  87:                         <NA>            <NA>           NA           NA
#>  88:                         <NA>            <NA>           NA       2009.5
#>  89:                         <NA>            <NA>           NA           NA
#>  90:                         <NA>            <NA>           NA           NA
#>  91:                         <NA>            <NA>       2005.5           NA
#>  92:                         <NA>            <NA>           NA           NA
#>  93:                         <NA>            <NA>           NA       2006.5
#>  94:                         <NA>            <NA>           NA           NA
#>  95:                         <NA>            <NA>           NA           NA
#>  96:                         <NA>            <NA>           NA           NA
#>  97: thyroid problem (not cancer)            <NA>       2005.5           NA
#>  98:                         <NA>            <NA>           NA           NA
#>  99:                 hypertension            <NA>           NA           NA
#> 100:                     fracture            <NA>           NA           NA
#>                      p20002_i0_a3    p20002_i0_a4 p20008_i0_a0 p20008_i0_a1
#>                            <char>          <char>        <num>        <num>
#>      p20008_i0_a2 p20008_i0_a3 p20008_i0_a4 p20001_i0_a0
#>             <num>        <num>        <num>       <char>
#>   1:           NA           NA           NA         <NA>
#>   2:           NA           NA           NA         <NA>
#>   3:           NA       2011.5           NA         <NA>
#>   4:           NA           NA           NA         <NA>
#>   5:           NA           NA           NA         <NA>
#>   6:           NA           NA           NA         <NA>
#>   7:           NA           NA           NA         <NA>
#>   8:           NA           NA           NA         <NA>
#>   9:           NA           NA           NA         <NA>
#>  10:           NA           NA           NA         <NA>
#>  11:           NA           NA           NA         <NA>
#>  12:           NA           NA           NA         <NA>
#>  13:           NA           NA           NA         <NA>
#>  14:           NA           NA           NA         <NA>
#>  15:           NA           NA           NA         <NA>
#>  16:           NA           NA           NA         <NA>
#>  17:           NA           NA           NA         <NA>
#>  18:           NA           NA           NA         <NA>
#>  19:           NA           NA           NA         <NA>
#>  20:           NA           NA           NA         <NA>
#>  21:           NA           NA       2003.5         <NA>
#>  22:           NA           NA           NA         <NA>
#>  23:       2005.5           NA           NA         <NA>
#>  24:           NA           NA           NA         <NA>
#>  25:           NA           NA           NA         <NA>
#>  26:           NA           NA           NA         <NA>
#>  27:           NA           NA           NA         <NA>
#>  28:           NA           NA           NA         <NA>
#>  29:           NA           NA           NA         <NA>
#>  30:           NA           NA           NA         <NA>
#>  31:           NA           NA           NA         <NA>
#>  32:           NA           NA           NA         <NA>
#>  33:           NA           NA       2014.5         <NA>
#>  34:           NA           NA           NA         <NA>
#>  35:           NA           NA           NA         <NA>
#>  36:           NA           NA           NA         <NA>
#>  37:           NA           NA           NA         <NA>
#>  38:           NA           NA           NA         <NA>
#>  39:           NA           NA           NA         <NA>
#>  40:           NA           NA           NA         <NA>
#>  41:           NA           NA           NA         <NA>
#>  42:           NA           NA           NA         <NA>
#>  43:           NA           NA           NA         <NA>
#>  44:           NA           NA           NA         <NA>
#>  45:           NA           NA           NA         <NA>
#>  46:           NA       2011.5           NA         <NA>
#>  47:           NA           NA           NA         <NA>
#>  48:           NA           NA           NA         <NA>
#>  49:           NA       2001.5           NA         <NA>
#>  50:           NA           NA           NA         <NA>
#>  51:           NA           NA           NA         <NA>
#>  52:           NA           NA           NA         <NA>
#>  53:           NA       2003.5           NA         <NA>
#>  54:       2008.5           NA           NA         <NA>
#>  55:           NA           NA           NA         <NA>
#>  56:           NA           NA           NA         <NA>
#>  57:           NA           NA           NA         <NA>
#>  58:           NA           NA           NA         <NA>
#>  59:           NA       2001.5           NA         <NA>
#>  60:           NA           NA           NA         <NA>
#>  61:           NA           NA       2007.5     lymphoma
#>  62:           NA           NA           NA         <NA>
#>  63:           NA           NA           NA         <NA>
#>  64:           NA           NA           NA         <NA>
#>  65:       2008.5           NA       2011.5         <NA>
#>  66:           NA           NA           NA         <NA>
#>  67:           NA           NA           NA         <NA>
#>  68:           NA           NA           NA     lymphoma
#>  69:           NA           NA           NA         <NA>
#>  70:           NA           NA           NA         <NA>
#>  71:           NA           NA           NA         <NA>
#>  72:           NA           NA           NA         <NA>
#>  73:           NA           NA           NA         <NA>
#>  74:           NA           NA           NA         <NA>
#>  75:           NA           NA           NA         <NA>
#>  76:       2001.5           NA           NA         <NA>
#>  77:           NA           NA           NA         <NA>
#>  78:           NA           NA           NA         <NA>
#>  79:           NA           NA           NA         <NA>
#>  80:           NA           NA           NA         <NA>
#>  81:           NA           NA           NA         <NA>
#>  82:           NA           NA           NA         <NA>
#>  83:           NA           NA           NA         <NA>
#>  84:           NA           NA           NA         <NA>
#>  85:           NA           NA           NA         <NA>
#>  86:           NA           NA           NA         <NA>
#>  87:           NA           NA           NA         <NA>
#>  88:       2009.5           NA           NA         <NA>
#>  89:       2006.5           NA           NA         <NA>
#>  90:           NA           NA           NA         <NA>
#>  91:           NA           NA           NA         <NA>
#>  92:           NA           NA           NA         <NA>
#>  93:           NA           NA           NA         <NA>
#>  94:       2009.5           NA           NA         <NA>
#>  95:           NA           NA           NA         <NA>
#>  96:           NA           NA           NA         <NA>
#>  97:           NA       2003.5           NA         <NA>
#>  98:           NA           NA           NA         <NA>
#>  99:           NA       2003.5           NA         <NA>
#> 100:           NA       2013.5           NA         <NA>
#>      p20008_i0_a2 p20008_i0_a3 p20008_i0_a4 p20001_i0_a0
#>             <num>        <num>        <num>       <char>
#>                  p20001_i0_a1             p20001_i0_a2 p20001_i0_a3
#>                        <char>                   <char>       <char>
#>   1:                     <NA>                     <NA>         <NA>
#>   2: non-melanoma skin cancer                     <NA>         <NA>
#>   3:                     <NA>                     <NA>         <NA>
#>   4:                     <NA>                     <NA>         <NA>
#>   5:                     <NA>                     <NA>         <NA>
#>   6:                 lymphoma                     <NA>         <NA>
#>   7:                     <NA>                     <NA>         <NA>
#>   8:           thyroid cancer                     <NA>         <NA>
#>   9:                     <NA>                     <NA>         <NA>
#>  10:                     <NA>                     <NA>         <NA>
#>  11:                     <NA>                     <NA>         <NA>
#>  12:                     <NA>                     <NA>         <NA>
#>  13:              lung cancer                     <NA>         <NA>
#>  14:                     <NA>                     <NA>         <NA>
#>  15:                     <NA>                     <NA>         <NA>
#>  16:                     <NA>                     <NA>         <NA>
#>  17:                     <NA>                     <NA>         <NA>
#>  18:                     <NA>                     <NA>         <NA>
#>  19:                     <NA>                     <NA>         <NA>
#>  20:                     <NA>                     <NA>         <NA>
#>  21:                     <NA>                     <NA>         <NA>
#>  22:                     <NA>                     <NA>         <NA>
#>  23:                     <NA>                     <NA>         <NA>
#>  24:                     <NA>                     <NA>         <NA>
#>  25:                     <NA>                     <NA>         <NA>
#>  26:                     <NA>                     <NA>         <NA>
#>  27:                     <NA>                     <NA>         <NA>
#>  28:                     <NA>                     <NA>         <NA>
#>  29:                     <NA>                     <NA>         <NA>
#>  30:                     <NA>                     <NA>         <NA>
#>  31:                     <NA>                     <NA>         <NA>
#>  32:                     <NA>                     <NA>         <NA>
#>  33:                     <NA>                     <NA>         <NA>
#>  34:                     <NA>                     <NA>         <NA>
#>  35:                     <NA>                     <NA>         <NA>
#>  36:                     <NA>                     <NA>         <NA>
#>  37:                     <NA>                     <NA>         <NA>
#>  38:                     <NA>                     <NA>         <NA>
#>  39:                     <NA>                     <NA>         <NA>
#>  40:                     <NA>                     <NA>         <NA>
#>  41:                     <NA>                     <NA>         <NA>
#>  42:                     <NA>                     <NA>         <NA>
#>  43:                     <NA>                     <NA>         <NA>
#>  44:                     <NA>                     <NA>         <NA>
#>  45:                     <NA>                     <NA>         <NA>
#>  46:                     <NA>                     <NA>         <NA>
#>  47:                     <NA>                     <NA>         <NA>
#>  48:                     <NA>                     <NA>         <NA>
#>  49:                     <NA>                     <NA>         <NA>
#>  50:                     <NA>                     <NA>         <NA>
#>  51:                     <NA>                     <NA>         <NA>
#>  52:                     <NA>                     <NA>         <NA>
#>  53:           bladder cancer                     <NA>         <NA>
#>  54:                     <NA>                     <NA>         <NA>
#>  55:                     <NA>                     <NA>         <NA>
#>  56:                     <NA>                     <NA>         <NA>
#>  57:                     <NA>                     <NA>         <NA>
#>  58:                     <NA>                     <NA>         <NA>
#>  59:                 lymphoma                     <NA>         <NA>
#>  60:                     <NA>                     <NA>         <NA>
#>  61:                     <NA>                     <NA>         <NA>
#>  62:                     <NA>                     <NA>         <NA>
#>  63:                     <NA>                     <NA>         <NA>
#>  64:                     <NA>                     <NA>         <NA>
#>  65:                     <NA>                     <NA>         <NA>
#>  66:                     <NA>                     <NA>         <NA>
#>  67:                     <NA>                     <NA>         <NA>
#>  68:                     <NA>                     <NA>         <NA>
#>  69:                     <NA>                     <NA>         <NA>
#>  70:                     <NA>                     <NA>         <NA>
#>  71:                     <NA>                     <NA>         <NA>
#>  72:                     <NA>                     <NA>         <NA>
#>  73:                     <NA>                     <NA>         <NA>
#>  74:                     <NA>                     <NA>         <NA>
#>  75:                     <NA>                     <NA>         <NA>
#>  76:                     <NA>                     <NA>         <NA>
#>  77:                     <NA>                     <NA>         <NA>
#>  78:                     <NA>                     <NA>         <NA>
#>  79:                     <NA> kidney/renal cell cancer         <NA>
#>  80:                     <NA>                     <NA>         <NA>
#>  81:                     <NA>                     <NA>         <NA>
#>  82:                     <NA>                     <NA>         <NA>
#>  83:                     <NA>                     <NA>         <NA>
#>  84:                     <NA>                     <NA>         <NA>
#>  85:                     <NA>                     <NA>         <NA>
#>  86:                     <NA>                     <NA>         <NA>
#>  87:                     <NA>                     <NA>         <NA>
#>  88:                     <NA>                     <NA>         <NA>
#>  89:                     <NA>                     <NA>         <NA>
#>  90:                     <NA>                     <NA>         <NA>
#>  91:                     <NA>                     <NA>         <NA>
#>  92:                     <NA>                     <NA>         <NA>
#>  93:                     <NA>                     <NA>         <NA>
#>  94:                     <NA>                     <NA>         <NA>
#>  95:                     <NA>                     <NA>         <NA>
#>  96:                     <NA>                     <NA>         <NA>
#>  97:                     <NA>                     <NA>         <NA>
#>  98:                     <NA>                     <NA>         <NA>
#>  99:                     <NA>                     <NA>         <NA>
#> 100:                     <NA>                     <NA>         <NA>
#>                  p20001_i0_a1             p20001_i0_a2 p20001_i0_a3
#>                        <char>                   <char>       <char>
#>      p20001_i0_a4 p20006_i0_a0 p20006_i0_a1 p20006_i0_a2 p20006_i0_a3
#>            <char>        <num>        <num>        <num>        <num>
#>   1:         <NA>           NA           NA           NA           NA
#>   2:         <NA>           NA       2014.5           NA           NA
#>   3:         <NA>           NA           NA           NA           NA
#>   4:         <NA>           NA           NA           NA           NA
#>   5:         <NA>           NA           NA           NA           NA
#>   6:         <NA>           NA       2012.5           NA           NA
#>   7:         <NA>           NA           NA           NA           NA
#>   8:         <NA>           NA       2000.5           NA           NA
#>   9:         <NA>           NA           NA           NA           NA
#>  10:         <NA>           NA           NA           NA           NA
#>  11:         <NA>           NA           NA           NA           NA
#>  12:         <NA>           NA           NA           NA           NA
#>  13:         <NA>           NA       2007.5           NA           NA
#>  14:         <NA>           NA           NA           NA           NA
#>  15:         <NA>           NA           NA           NA           NA
#>  16:         <NA>           NA           NA           NA           NA
#>  17:         <NA>           NA           NA           NA           NA
#>  18:         <NA>           NA           NA           NA           NA
#>  19:         <NA>           NA           NA           NA           NA
#>  20:         <NA>           NA           NA           NA           NA
#>  21:         <NA>           NA           NA           NA           NA
#>  22:         <NA>           NA           NA           NA           NA
#>  23:         <NA>           NA           NA           NA           NA
#>  24:         <NA>           NA           NA           NA           NA
#>  25:         <NA>           NA           NA           NA           NA
#>  26:         <NA>           NA           NA           NA           NA
#>  27:         <NA>           NA           NA           NA           NA
#>  28:         <NA>           NA           NA           NA           NA
#>  29:         <NA>           NA           NA           NA           NA
#>  30:         <NA>           NA           NA           NA           NA
#>  31:         <NA>           NA           NA           NA           NA
#>  32:         <NA>           NA           NA           NA           NA
#>  33:         <NA>           NA           NA           NA           NA
#>  34:         <NA>           NA           NA           NA           NA
#>  35:         <NA>           NA           NA           NA           NA
#>  36:         <NA>           NA           NA           NA           NA
#>  37:         <NA>           NA           NA           NA           NA
#>  38:         <NA>           NA           NA           NA           NA
#>  39:         <NA>           NA           NA           NA           NA
#>  40:         <NA>           NA           NA           NA           NA
#>  41:         <NA>           NA           NA           NA           NA
#>  42:         <NA>           NA           NA           NA           NA
#>  43:         <NA>           NA           NA           NA           NA
#>  44:         <NA>           NA           NA           NA           NA
#>  45:         <NA>           NA           NA           NA           NA
#>  46:         <NA>           NA           NA           NA           NA
#>  47:         <NA>           NA           NA           NA           NA
#>  48:         <NA>           NA           NA           NA           NA
#>  49:         <NA>           NA           NA           NA           NA
#>  50:         <NA>           NA           NA           NA           NA
#>  51:         <NA>           NA           NA           NA           NA
#>  52:         <NA>           NA           NA           NA           NA
#>  53:         <NA>           NA       2006.5           NA           NA
#>  54:         <NA>           NA           NA           NA           NA
#>  55:         <NA>           NA           NA           NA           NA
#>  56:         <NA>           NA           NA           NA           NA
#>  57:         <NA>           NA           NA           NA           NA
#>  58:         <NA>           NA           NA           NA           NA
#>  59:         <NA>           NA       2009.5           NA           NA
#>  60:         <NA>           NA           NA           NA           NA
#>  61:         <NA>       2009.5           NA           NA           NA
#>  62:         <NA>           NA           NA           NA           NA
#>  63:         <NA>           NA           NA           NA           NA
#>  64:         <NA>           NA           NA           NA           NA
#>  65:         <NA>           NA           NA           NA           NA
#>  66:         <NA>           NA           NA           NA           NA
#>  67:         <NA>           NA           NA           NA           NA
#>  68:         <NA>       2012.5           NA           NA           NA
#>  69:         <NA>           NA           NA           NA           NA
#>  70:         <NA>           NA           NA           NA           NA
#>  71:         <NA>           NA           NA           NA           NA
#>  72:         <NA>           NA           NA           NA           NA
#>  73:         <NA>           NA           NA           NA           NA
#>  74:         <NA>           NA           NA           NA           NA
#>  75:         <NA>           NA           NA           NA           NA
#>  76:         <NA>           NA           NA           NA           NA
#>  77:         <NA>           NA           NA           NA           NA
#>  78:         <NA>           NA           NA           NA           NA
#>  79:         <NA>           NA           NA       2014.5           NA
#>  80:         <NA>           NA           NA           NA           NA
#>  81:         <NA>           NA           NA           NA           NA
#>  82:         <NA>           NA           NA           NA           NA
#>  83:         <NA>           NA           NA           NA           NA
#>  84:         <NA>           NA           NA           NA           NA
#>  85:         <NA>           NA           NA           NA           NA
#>  86:         <NA>           NA           NA           NA           NA
#>  87:         <NA>           NA           NA           NA           NA
#>  88:         <NA>           NA           NA           NA           NA
#>  89:         <NA>           NA           NA           NA           NA
#>  90:         <NA>           NA           NA           NA           NA
#>  91:         <NA>           NA           NA           NA           NA
#>  92:         <NA>           NA           NA           NA           NA
#>  93:         <NA>           NA           NA           NA           NA
#>  94:         <NA>           NA           NA           NA           NA
#>  95:         <NA>           NA           NA           NA           NA
#>  96:         <NA>           NA           NA           NA           NA
#>  97:         <NA>           NA           NA           NA           NA
#>  98:         <NA>           NA           NA           NA           NA
#>  99:         <NA>           NA           NA           NA           NA
#> 100:         <NA>           NA           NA           NA           NA
#>      p20001_i0_a4 p20006_i0_a0 p20006_i0_a1 p20006_i0_a2 p20006_i0_a3
#>            <char>        <num>        <num>        <num>        <num>
#>      p20006_i0_a4                    p41270  p41280_a0  p41280_a1  p41280_a2
#>             <num>                    <char>     <char>     <char>     <char>
#>   1:           NA                      <NA>       <NA>       <NA>       <NA>
#>   2:           NA                      <NA>       <NA>       <NA>       <NA>
#>   3:           NA                      <NA>       <NA>       <NA>       <NA>
#>   4:           NA                   ["K57"] 2007-07-25       <NA>       <NA>
#>   5:           NA                      <NA>       <NA>       <NA>       <NA>
#>   6:           NA                   ["C44"] 2013-01-31       <NA>       <NA>
#>   7:           NA ["F32","I25","G35","E11"] 2020-10-25 2016-10-31 2021-12-31
#>   8:           NA                      <NA>       <NA>       <NA>       <NA>
#>   9:           NA                      <NA>       <NA>       <NA>       <NA>
#>  10:           NA                   ["I48"] 2018-04-26       <NA>       <NA>
#>  11:           NA ["G35","I48","E11","L20"] 2011-06-06 2013-12-14 2022-12-28
#>  12:           NA                   ["K57"] 2021-04-07       <NA>       <NA>
#>  13:           NA                      <NA>       <NA>       <NA>       <NA>
#>  14:           NA                      <NA>       <NA>       <NA>       <NA>
#>  15:           NA                      <NA>       <NA>       <NA>       <NA>
#>  16:           NA                      <NA>       <NA>       <NA>       <NA>
#>  17:           NA                   ["I10"] 2006-10-11       <NA>       <NA>
#>  18:           NA                      <NA>       <NA>       <NA>       <NA>
#>  19:           NA       ["C44","M79","E11"] 2013-12-09 2017-02-09 2017-07-21
#>  20:           NA       ["C44","J45","I25"] 2011-09-19 2007-04-19 2006-01-05
#>  21:           NA                      <NA>       <NA>       <NA>       <NA>
#>  22:           NA                      <NA>       <NA>       <NA>       <NA>
#>  23:           NA                      <NA>       <NA>       <NA>       <NA>
#>  24:           NA                      <NA>       <NA>       <NA>       <NA>
#>  25:           NA                      <NA>       <NA>       <NA>       <NA>
#>  26:           NA                      <NA>       <NA>       <NA>       <NA>
#>  27:           NA             ["C44","E11"] 2007-05-12 2000-03-14       <NA>
#>  28:           NA                      <NA>       <NA>       <NA>       <NA>
#>  29:           NA             ["I10","F32"] 2005-10-28 2001-05-07       <NA>
#>  30:           NA                      <NA>       <NA>       <NA>       <NA>
#>  31:           NA                      <NA>       <NA>       <NA>       <NA>
#>  32:           NA                      <NA>       <NA>       <NA>       <NA>
#>  33:           NA                      <NA>       <NA>       <NA>       <NA>
#>  34:           NA                   ["J45"] 2004-02-22       <NA>       <NA>
#>  35:           NA                      <NA>       <NA>       <NA>       <NA>
#>  36:           NA                   ["G35"] 2022-02-27       <NA>       <NA>
#>  37:           NA                      <NA>       <NA>       <NA>       <NA>
#>  38:           NA                      <NA>       <NA>       <NA>       <NA>
#>  39:           NA                      <NA>       <NA>       <NA>       <NA>
#>  40:           NA                      <NA>       <NA>       <NA>       <NA>
#>  41:           NA                      <NA>       <NA>       <NA>       <NA>
#>  42:           NA                      <NA>       <NA>       <NA>       <NA>
#>  43:           NA                      <NA>       <NA>       <NA>       <NA>
#>  44:           NA       ["N18","I48","E11"] 2018-02-15 2012-08-20 2020-02-08
#>  45:           NA ["E11","J45","L20","G35"] 2010-08-23 2008-02-24 2006-06-16
#>  46:           NA                      <NA>       <NA>       <NA>       <NA>
#>  47:           NA                      <NA>       <NA>       <NA>       <NA>
#>  48:           NA                      <NA>       <NA>       <NA>       <NA>
#>  49:           NA                      <NA>       <NA>       <NA>       <NA>
#>  50:           NA             ["E11","I10"] 2001-06-07 2017-02-10       <NA>
#>  51:           NA                      <NA>       <NA>       <NA>       <NA>
#>  52:           NA                      <NA>       <NA>       <NA>       <NA>
#>  53:           NA                      <NA>       <NA>       <NA>       <NA>
#>  54:           NA                      <NA>       <NA>       <NA>       <NA>
#>  55:           NA             ["M79","I48"] 2004-10-31 2013-05-14       <NA>
#>  56:           NA                      <NA>       <NA>       <NA>       <NA>
#>  57:           NA                      <NA>       <NA>       <NA>       <NA>
#>  58:           NA                      <NA>       <NA>       <NA>       <NA>
#>  59:           NA                   ["C44"] 2013-07-08       <NA>       <NA>
#>  60:           NA ["L20","K57","I25","M79"] 2008-03-22 2012-02-20 2016-07-05
#>  61:           NA ["N18","E11","M79","I10"] 2018-06-02 2011-10-29 2018-05-09
#>  62:           NA                      <NA>       <NA>       <NA>       <NA>
#>  63:           NA       ["I25","G35","L20"] 2016-10-18 2003-07-08 2021-03-19
#>  64:           NA                      <NA>       <NA>       <NA>       <NA>
#>  65:           NA                      <NA>       <NA>       <NA>       <NA>
#>  66:           NA                      <NA>       <NA>       <NA>       <NA>
#>  67:           NA                      <NA>       <NA>       <NA>       <NA>
#>  68:           NA                      <NA>       <NA>       <NA>       <NA>
#>  69:           NA                      <NA>       <NA>       <NA>       <NA>
#>  70:           NA                   ["K57"] 2021-05-12       <NA>       <NA>
#>  71:           NA                   ["K57"] 2014-06-14       <NA>       <NA>
#>  72:           NA                      <NA>       <NA>       <NA>       <NA>
#>  73:           NA             ["M79","F32"] 2000-04-13 2014-06-06       <NA>
#>  74:           NA                      <NA>       <NA>       <NA>       <NA>
#>  75:           NA                      <NA>       <NA>       <NA>       <NA>
#>  76:           NA                      <NA>       <NA>       <NA>       <NA>
#>  77:           NA                   ["I10"] 2016-11-12       <NA>       <NA>
#>  78:           NA                      <NA>       <NA>       <NA>       <NA>
#>  79:           NA                      <NA>       <NA>       <NA>       <NA>
#>  80:           NA                      <NA>       <NA>       <NA>       <NA>
#>  81:           NA                   ["E11"] 2015-04-21       <NA>       <NA>
#>  82:           NA ["I10","N18","M79","C44"] 2017-09-11 2013-01-18 2012-05-01
#>  83:           NA             ["C44","I25"] 2019-03-01 2004-10-10       <NA>
#>  84:           NA ["N18","I25","F32","E11"] 2002-02-28 2000-02-06 2009-08-25
#>  85:           NA                      <NA>       <NA>       <NA>       <NA>
#>  86:           NA                      <NA>       <NA>       <NA>       <NA>
#>  87:           NA       ["L20","M79","C44"] 2000-08-31 2020-09-14 2020-07-20
#>  88:           NA                      <NA>       <NA>       <NA>       <NA>
#>  89:           NA                      <NA>       <NA>       <NA>       <NA>
#>  90:           NA                   ["C44"] 2007-12-08       <NA>       <NA>
#>  91:           NA                   ["C44"] 2020-11-11       <NA>       <NA>
#>  92:           NA                   ["L20"] 2021-05-12       <NA>       <NA>
#>  93:           NA       ["I10","L20","K57"] 2011-11-10 2019-06-04 2010-01-09
#>  94:           NA                      <NA>       <NA>       <NA>       <NA>
#>  95:           NA       ["M79","K57","I48"] 2019-03-06 2016-02-19 2021-01-15
#>  96:           NA       ["M79","K57","L20"] 2007-11-21 2019-07-13 2010-05-31
#>  97:           NA       ["M79","I25","I48"] 2020-06-19 2018-08-03 2010-11-14
#>  98:           NA                      <NA>       <NA>       <NA>       <NA>
#>  99:           NA ["J45","E11","G35","I48"] 2007-12-25 2006-08-16 2012-09-24
#> 100:           NA                      <NA>       <NA>       <NA>       <NA>
#>      p20006_i0_a4                    p41270  p41280_a0  p41280_a1  p41280_a2
#>             <num>                    <char>     <char>     <char>     <char>
#>       p41280_a3 p41280_a4 p41280_a5 p41280_a6 p41280_a7 p41280_a8 p40006_i0
#>          <char>    <char>    <char>    <char>    <char>    <char>    <char>
#>   1:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   2:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   3:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   4:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   5:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   6:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   7: 2002-05-17      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   8:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   9:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C34
#>  10:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  11: 2016-04-21      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  12:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  13:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  14:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  15:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  16:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  17:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  18:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  19:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  20:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  21:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  22:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  23:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  24:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  25:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  26:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  27:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  28:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  29:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C43
#>  30:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  31:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  32:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  33:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  34:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  35:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  36:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  37:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C34
#>  38:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  39:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  40:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  41:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  42:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  43:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  44:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  45: 2020-08-24      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  46:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  47:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  48:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  49:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  50:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  51:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  52:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  53:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  54:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  55:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C64
#>  56:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  57:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  58:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  59:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  60: 2013-05-23      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  61: 2016-05-04      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  62:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  63:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  64:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  65:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  66:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C61
#>  67:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  68:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  69:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  70:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  71:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C20
#>  72:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  73:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  74:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  75:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  76:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  77:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  78:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  79:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  80:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  81:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  82: 2001-08-22      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  83:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  84: 2005-07-10      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  85:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  86:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  87:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  88:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  89:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  90:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  91:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  92:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  93:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  94:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  95:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  96:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  97:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  98:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  99: 2021-06-02      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#> 100:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>       p41280_a3 p41280_a4 p41280_a5 p41280_a6 p41280_a7 p41280_a8 p40006_i0
#>          <char>    <char>    <char>    <char>    <char>    <char>    <char>
#>      p40011_i0 p40012_i0  p40005_i0 p40006_i1 p40011_i1 p40012_i1  p40005_i1
#>          <int>     <int>     <char>    <char>     <int>     <int>     <char>
#>   1:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   2:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   3:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   4:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   5:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   6:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   7:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   8:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   9:      8520         6 2014-10-21      <NA>        NA        NA       <NA>
#>  10:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  11:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  12:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  13:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  14:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  15:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  16:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  17:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  18:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  19:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  20:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  21:        NA        NA       <NA>       C18      8130         3 2006-12-19
#>  22:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  23:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  24:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  25:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  26:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  27:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  28:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  29:      8010         3 2009-02-10      <NA>        NA        NA       <NA>
#>  30:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  31:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  32:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  33:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  34:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  35:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  36:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  37:      8000         3 1994-09-27      <NA>        NA        NA       <NA>
#>  38:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  39:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  40:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  41:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  42:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  43:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  44:        NA        NA       <NA>       C34      8090         1 2001-03-26
#>  45:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  46:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  47:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  48:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  49:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  50:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  51:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  52:        NA        NA       <NA>       C43      8090         3 1990-02-27
#>  53:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  54:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  55:      8010         9 2019-03-22      <NA>        NA        NA       <NA>
#>  56:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  57:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  58:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  59:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  60:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  61:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  62:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  63:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  64:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  65:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  66:      8140         0 2005-10-09      <NA>        NA        NA       <NA>
#>  67:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  68:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  69:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  70:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  71:      8090         2 1990-03-22      <NA>        NA        NA       <NA>
#>  72:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  73:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  74:        NA        NA       <NA>       C18      8743         2 2008-07-11
#>  75:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  76:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  77:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  78:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  79:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  80:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  81:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  82:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  83:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  84:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  85:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  86:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  87:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  88:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  89:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  90:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  91:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  92:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  93:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  94:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  95:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  96:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  97:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  98:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  99:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#> 100:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>      p40011_i0 p40012_i0  p40005_i0 p40006_i1 p40011_i1 p40012_i1  p40005_i1
#>          <int>     <int>     <char>    <char>     <int>     <int>     <char>
#>      p40006_i2 p40011_i2 p40012_i2  p40005_i2 p40001_i0 p40002_i0_a0
#>         <char>     <int>     <int>     <char>    <char>       <char>
#>   1:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   2:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   3:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   4:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   5:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   6:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   7:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   8:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   9:      <NA>        NA        NA       <NA>     C50.9        C25.9
#>  10:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  11:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  12:      <NA>        NA        NA       <NA>     I25.9         <NA>
#>  13:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  14:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  15:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  16:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  17:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  18:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  19:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  20:      <NA>        NA        NA       <NA>     C50.9         <NA>
#>  21:      <NA>        NA        NA       <NA>     E11.9         <NA>
#>  22:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  23:      <NA>        NA        NA       <NA>     C34.9         <NA>
#>  24:      <NA>        NA        NA       <NA>       C61          C61
#>  25:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  26:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  27:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  28:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  29:       C43      8500         2 2011-07-25      <NA>         <NA>
#>  30:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  31:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  32:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  33:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  34:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  35:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  36:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  37:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  38:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  39:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  40:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  41:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  42:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  43:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  44:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  45:      <NA>        NA        NA       <NA>       I64          I64
#>  46:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  47:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  48:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  49:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  50:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  51:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  52:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  53:      <NA>        NA        NA       <NA>     I48.0         <NA>
#>  54:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  55:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  56:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  57:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  58:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  59:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  60:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  61:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  62:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  63:      <NA>        NA        NA       <NA>     C18.9         <NA>
#>  64:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  65:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  66:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  67:      <NA>        NA        NA       <NA>     I25.9         <NA>
#>  68:      <NA>        NA        NA       <NA>     I21.9         <NA>
#>  69:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  70:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  71:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  72:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  73:      <NA>        NA        NA       <NA>     C18.9         <NA>
#>  74:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  75:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  76:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  77:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  78:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  79:      <NA>        NA        NA       <NA>       C61         <NA>
#>  80:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  81:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  82:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  83:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  84:      <NA>        NA        NA       <NA>     I48.0         <NA>
#>  85:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  86:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  87:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  88:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  89:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  90:       C20      8010         9 2009-09-24      <NA>         <NA>
#>  91:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  92:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  93:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  94:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  95:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  96:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  97:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  98:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  99:      <NA>        NA        NA       <NA>     I21.9         <NA>
#> 100:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>      p40006_i2 p40011_i2 p40012_i2  p40005_i2 p40001_i0 p40002_i0_a0
#>         <char>     <int>     <int>     <char>    <char>       <char>
#>      p40002_i0_a1 p40002_i0_a2  p40000_i0    p131742   grs_bmi    grs_raw
#>            <char>       <char>     <char>     <char>     <num>      <num>
#>   1:         <NA>         <NA>       <NA>       <NA>  0.021609   4.119301
#>   2:         <NA>         <NA>       <NA>       <NA>  2.847126  -1.068375
#>   3:         <NA>         <NA>       <NA>       <NA>  0.676117  -1.709500
#>   4:         <NA>         <NA>       <NA>       <NA> -0.600684   3.042186
#>   5:         <NA>         <NA>       <NA>       <NA> -0.340030   3.501643
#>   6:         <NA>         <NA>       <NA>       <NA>  7.060673  -3.980057
#>   7:         <NA>         <NA>       <NA>       <NA> -0.883849   6.245520
#>   8:         <NA>         <NA>       <NA>       <NA>  2.417561  -5.542793
#>   9:         <NA>         <NA> 2014-04-16       <NA>  4.028432   5.099845
#>  10:         <NA>         <NA>       <NA>       <NA> -1.852965   1.773366
#>  11:         <NA>         <NA>       <NA>       <NA> -0.095659   5.659451
#>  12:         <NA>          I64 2014-09-16       <NA>  1.857489   3.542727
#>  13:         <NA>         <NA>       <NA>       <NA>  3.857785   6.716829
#>  14:         <NA>         <NA>       <NA>       <NA>  3.662161   1.536181
#>  15:         <NA>         <NA>       <NA>       <NA>  0.653029   4.532348
#>  16:         <NA>         <NA>       <NA>       <NA>  1.730675  -2.326168
#>  17:         <NA>         <NA>       <NA>       <NA>  1.306783   1.161314
#>  18:         <NA>         <NA>       <NA>       <NA>  1.482341   6.471390
#>  19:         <NA>         <NA>       <NA>       <NA>  0.347114   4.018216
#>  20:         <NA>         <NA> 2012-01-10       <NA> -3.823814  -3.674077
#>  21:        C50.9         <NA> 2014-05-17       <NA>  0.138854  -0.562140
#>  22:         <NA>         <NA>       <NA>       <NA>  1.540169   1.987958
#>  23:         <NA>         <NA> 2018-02-04       <NA>  1.773638  -1.501415
#>  24:        C34.9         <NA> 2014-08-13       <NA>  0.745601  -1.156863
#>  25:         <NA>         <NA>       <NA>       <NA>  1.842031   7.467715
#>  26:         <NA>         <NA>       <NA>       <NA>  0.205781  -2.218112
#>  27:         <NA>         <NA>       <NA>       <NA> -3.504630   2.302857
#>  28:         <NA>         <NA>       <NA>       <NA>  0.351665   4.491370
#>  29:         <NA>         <NA>       <NA>       <NA>  0.494700   2.264275
#>  30:         <NA>         <NA>       <NA>       <NA> -5.123789   0.917649
#>  31:         <NA>         <NA>       <NA>       <NA>  3.100736   3.872237
#>  32:         <NA>         <NA>       <NA>       <NA> -1.942790  -0.156689
#>  33:         <NA>         <NA>       <NA>       <NA>  2.351239   7.068708
#>  34:         <NA>         <NA>       <NA>       <NA>  1.425759  -0.503581
#>  35:         <NA>         <NA>       <NA>       <NA> -1.608448  -2.527301
#>  36:         <NA>         <NA>       <NA>       <NA>  1.424656 -10.117574
#>  37:         <NA>         <NA>       <NA>       <NA>  4.009477   2.506912
#>  38:         <NA>         <NA>       <NA>       <NA>  1.279449  -1.996846
#>  39:         <NA>         <NA>       <NA>       <NA>  0.099330   1.722641
#>  40:         <NA>         <NA>       <NA>       <NA>  0.919699  -3.923742
#>  41:         <NA>         <NA>       <NA>       <NA>  0.029150   4.941069
#>  42:         <NA>         <NA>       <NA>       <NA> -3.142930   0.747979
#>  43:         <NA>         <NA>       <NA>       <NA>  1.222075   5.436972
#>  44:         <NA>         <NA>       <NA>       <NA> -1.490589   3.340988
#>  45:         <NA>         <NA> 2022-06-06       <NA> -3.122234   4.821942
#>  46:         <NA>         <NA>       <NA> 2006-03-02 -4.040376   3.492777
#>  47:         <NA>         <NA>       <NA>       <NA> -0.126759   2.278545
#>  48:         <NA>         <NA>       <NA>       <NA>  2.405921   6.848048
#>  49:         <NA>         <NA>       <NA>       <NA> -2.982039   0.023685
#>  50:         <NA>         <NA>       <NA>       <NA> -1.021113  -3.002445
#>  51:         <NA>         <NA>       <NA>       <NA>  1.939797   8.618853
#>  52:         <NA>         <NA>       <NA>       <NA> -2.399704   0.557300
#>  53:        C25.9         <NA> 2015-01-28       <NA>  4.581159   4.876335
#>  54:         <NA>         <NA>       <NA>       <NA> -1.213205   0.467835
#>  55:         <NA>         <NA>       <NA> 2005-10-23 -0.350983   2.443917
#>  56:         <NA>         <NA>       <NA>       <NA>  3.837411   3.382863
#>  57:         <NA>         <NA>       <NA>       <NA>  2.174932  -5.054569
#>  58:         <NA>         <NA>       <NA>       <NA>  2.958808   2.698314
#>  59:         <NA>         <NA>       <NA>       <NA> -2.054506  -1.762573
#>  60:         <NA>         <NA>       <NA>       <NA>  3.478392   8.202791
#>  61:         <NA>         <NA>       <NA>       <NA>  0.800876   3.924331
#>  62:         <NA>         <NA>       <NA>       <NA>  2.027209   5.816133
#>  63:         <NA>         <NA> 2016-07-29 2005-07-05  0.884115   0.568528
#>  64:         <NA>         <NA>       <NA>       <NA>  0.375346   1.832600
#>  65:         <NA>         <NA>       <NA> 2003-06-10  6.108202   2.702922
#>  66:         <NA>         <NA>       <NA>       <NA> -2.535697   2.868933
#>  67:        C18.9         <NA> 2016-07-26       <NA>  4.392914  -1.813727
#>  68:         <NA>         <NA> 2023-12-04       <NA> -0.022262   0.744138
#>  69:         <NA>         <NA>       <NA>       <NA> -1.025169  -2.747311
#>  70:         <NA>         <NA>       <NA>       <NA>  2.550825   6.678603
#>  71:         <NA>         <NA>       <NA>       <NA> -0.211277   0.747080
#>  72:         <NA>         <NA>       <NA>       <NA>  3.101550   4.005463
#>  73:         <NA>         <NA> 2019-09-29       <NA> -1.575432   1.028322
#>  74:         <NA>         <NA>       <NA>       <NA> -1.859912   4.232483
#>  75:         <NA>         <NA>       <NA>       <NA>  4.002564   2.818326
#>  76:         <NA>         <NA>       <NA>       <NA>  2.672228   5.202175
#>  77:         <NA>         <NA>       <NA>       <NA>  0.400722   4.724100
#>  78:         <NA>         <NA>       <NA>       <NA>  2.079422   3.236861
#>  79:         <NA>         <NA> 2014-12-29 2012-06-02  0.956295   0.142627
#>  80:         <NA>         <NA>       <NA>       <NA>  1.012196  -0.017678
#>  81:         <NA>         <NA>       <NA>       <NA> -0.398647   3.505991
#>  82:         <NA>         <NA>       <NA>       <NA>  1.494782  -1.251276
#>  83:         <NA>         <NA>       <NA>       <NA>  0.520495   5.597912
#>  84:         <NA>         <NA> 2019-10-03       <NA>  4.011875   3.742728
#>  85:         <NA>         <NA>       <NA>       <NA> -3.389348   3.268896
#>  86:         <NA>         <NA>       <NA>       <NA>  2.472043   1.789279
#>  87:         <NA>         <NA>       <NA>       <NA> -0.576458   4.936015
#>  88:         <NA>         <NA>       <NA>       <NA> -0.545487   2.625123
#>  89:         <NA>         <NA>       <NA>       <NA>  0.694612   1.051580
#>  90:         <NA>         <NA>       <NA>       <NA>  4.295643   0.397911
#>  91:         <NA>         <NA>       <NA>       <NA> -2.742106   1.124167
#>  92:         <NA>         <NA>       <NA>       <NA> -1.449225   4.667456
#>  93:         <NA>         <NA>       <NA>       <NA>  0.266988   2.278901
#>  94:         <NA>         <NA>       <NA>       <NA>  1.251750  -0.170729
#>  95:         <NA>         <NA>       <NA>       <NA>  1.303593   0.768698
#>  96:         <NA>         <NA>       <NA>       <NA>  5.741759  -6.496860
#>  97:         <NA>         <NA>       <NA>       <NA>  1.384529   2.509193
#>  98:         <NA>         <NA>       <NA>       <NA>  0.647035   4.948357
#>  99:         <NA>         <NA> 2015-03-10       <NA>  1.268670  -2.438080
#> 100:         <NA>         <NA>       <NA>       <NA> -1.427677   1.876287
#>      p40002_i0_a1 p40002_i0_a2  p40000_i0    p131742   grs_bmi    grs_raw
#>            <char>       <char>     <char>     <char>     <num>      <num>
#>      grs_finngen messy_allna messy_empty messy_label htn_hes htn_hes_date
#>            <num>      <char>      <char>      <char>  <lgcl>       <IDat>
#>   1:   -0.463630        <NA>                    <NA>   FALSE         <NA>
#>   2:   -1.009118        <NA>        <NA>        <NA>   FALSE         <NA>
#>   3:    0.568112        <NA>        <NA>        <NA>   FALSE         <NA>
#>   4:   -0.926223        <NA>        <NA>        <NA>   FALSE         <NA>
#>   5:    0.270758        <NA>                    <NA>   FALSE         <NA>
#>   6:    2.791891        <NA>        <NA>        <NA>   FALSE         <NA>
#>   7:   -2.652631        <NA>        <NA>        <NA>   FALSE         <NA>
#>   8:   -0.802261        <NA>        <NA>        <NA>   FALSE         <NA>
#>   9:   -0.363472        <NA>        <NA>         999   FALSE         <NA>
#>  10:    2.656164        <NA>        <NA>        <NA>   FALSE         <NA>
#>  11:    2.000984        <NA>                    <NA>   FALSE         <NA>
#>  12:    0.305794        <NA>                 unknown   FALSE         <NA>
#>  13:   -1.799184        <NA>        <NA>     unknown   FALSE         <NA>
#>  14:    0.905366        <NA>        <NA>        <NA>   FALSE         <NA>
#>  15:    0.594078        <NA>        <NA>           .   FALSE         <NA>
#>  16:    1.313204        <NA>                     999   FALSE         <NA>
#>  17:    0.414140        <NA>        <NA>     unknown    TRUE   2006-10-11
#>  18:   -2.115044        <NA>                 unknown   FALSE         <NA>
#>  19:   -0.107411        <NA>        <NA>        <NA>   FALSE         <NA>
#>  20:    3.113082        <NA>        <NA>         999   FALSE         <NA>
#>  21:   -2.597347        <NA>        <NA>         N/A   FALSE         <NA>
#>  22:    0.682216        <NA>                    <NA>   FALSE         <NA>
#>  23:    3.267717        <NA>        <NA>        <NA>   FALSE         <NA>
#>  24:   -0.405814        <NA>        <NA>         999   FALSE         <NA>
#>  25:    1.318932        <NA>                    <NA>   FALSE         <NA>
#>  26:   -0.455031        <NA>                 unknown   FALSE         <NA>
#>  27:    1.149077        <NA>                    <NA>   FALSE         <NA>
#>  28:   -1.989588        <NA>                    <NA>   FALSE         <NA>
#>  29:   -0.708027        <NA>        <NA>        #N/A    TRUE   2005-10-28
#>  30:    2.334323        <NA>        <NA>        <NA>   FALSE         <NA>
#>  31:    4.526089        <NA>                    <NA>   FALSE         <NA>
#>  32:   -0.355460        <NA>                    <NA>   FALSE         <NA>
#>  33:    1.084070        <NA>        <NA>        <NA>   FALSE         <NA>
#>  34:    2.594823        <NA>        <NA>        <NA>   FALSE         <NA>
#>  35:    0.006402        <NA>                     N/A   FALSE         <NA>
#>  36:    0.672020        <NA>                    <NA>   FALSE         <NA>
#>  37:    1.772247        <NA>        <NA>        <NA>   FALSE         <NA>
#>  38:   -3.879410        <NA>                    <NA>   FALSE         <NA>
#>  39:    1.539012        <NA>                       .   FALSE         <NA>
#>  40:   -1.155076        <NA>        <NA>        <NA>   FALSE         <NA>
#>  41:    0.605702        <NA>                    <NA>   FALSE         <NA>
#>  42:   -0.169956        <NA>        <NA>          -1   FALSE         <NA>
#>  43:    0.272292        <NA>        <NA>        NULL   FALSE         <NA>
#>  44:    2.068850        <NA>        <NA>        <NA>   FALSE         <NA>
#>  45:    0.989606        <NA>        <NA>        <NA>   FALSE         <NA>
#>  46:   -0.512391        <NA>        <NA>        <NA>   FALSE         <NA>
#>  47:    0.615645        <NA>                    NULL   FALSE         <NA>
#>  48:    2.025145        <NA>                    <NA>   FALSE         <NA>
#>  49:    1.361591        <NA>                      -1   FALSE         <NA>
#>  50:   -2.213414        <NA>                    <NA>    TRUE   2017-02-10
#>  51:   -4.909140        <NA>                    <NA>   FALSE         <NA>
#>  52:    1.092574        <NA>        <NA>        <NA>   FALSE         <NA>
#>  53:   -0.246553        <NA>                    #N/A   FALSE         <NA>
#>  54:    1.139080        <NA>                     999   FALSE         <NA>
#>  55:    0.974756        <NA>        <NA>          -1   FALSE         <NA>
#>  56:   -0.430027        <NA>                    <NA>   FALSE         <NA>
#>  57:    1.081591        <NA>        <NA>        #N/A   FALSE         <NA>
#>  58:    1.448629        <NA>        <NA>        <NA>   FALSE         <NA>
#>  59:    2.145363        <NA>                    <NA>   FALSE         <NA>
#>  60:    0.590018        <NA>        <NA>           .   FALSE         <NA>
#>  61:   -1.164018        <NA>                     N/A    TRUE   2016-05-04
#>  62:    0.052337        <NA>                     999   FALSE         <NA>
#>  63:   -1.816670        <NA>        <NA>     unknown   FALSE         <NA>
#>  64:    0.657542        <NA>        <NA>         N/A   FALSE         <NA>
#>  65:   -2.170130        <NA>        <NA>        <NA>   FALSE         <NA>
#>  66:    4.217090        <NA>                      -1   FALSE         <NA>
#>  67:   -2.970318        <NA>                    <NA>   FALSE         <NA>
#>  68:    0.190296        <NA>        <NA>     unknown   FALSE         <NA>
#>  69:    4.053520        <NA>                     N/A   FALSE         <NA>
#>  70:   -1.547943        <NA>                    <NA>   FALSE         <NA>
#>  71:   -1.117983        <NA>                    <NA>   FALSE         <NA>
#>  72:   -3.292374        <NA>        <NA>          -1   FALSE         <NA>
#>  73:   -2.325049        <NA>                       .   FALSE         <NA>
#>  74:   -1.470725        <NA>        <NA>        <NA>   FALSE         <NA>
#>  75:   -2.445188        <NA>                       .   FALSE         <NA>
#>  76:    1.087213        <NA>        <NA>        <NA>   FALSE         <NA>
#>  77:    3.060571        <NA>                    <NA>    TRUE   2016-11-12
#>  78:   -1.128299        <NA>                    <NA>   FALSE         <NA>
#>  79:   -1.620076        <NA>        <NA>        #N/A   FALSE         <NA>
#>  80:    2.514598        <NA>                     N/A   FALSE         <NA>
#>  81:   -2.236809        <NA>                    <NA>   FALSE         <NA>
#>  82:    1.037811        <NA>                    <NA>    TRUE   2017-09-11
#>  83:    1.799680        <NA>        <NA>        <NA>   FALSE         <NA>
#>  84:    4.106166        <NA>        <NA>        NULL   FALSE         <NA>
#>  85:    1.252130        <NA>        <NA>        NULL   FALSE         <NA>
#>  86:   -1.083332        <NA>        <NA>        <NA>   FALSE         <NA>
#>  87:    2.833747        <NA>        <NA>          -1   FALSE         <NA>
#>  88:   -2.505783        <NA>        <NA>        <NA>   FALSE         <NA>
#>  89:    1.393036        <NA>        <NA>           .   FALSE         <NA>
#>  90:    0.573962        <NA>        <NA>        <NA>   FALSE         <NA>
#>  91:   -3.754840        <NA>        <NA>        <NA>   FALSE         <NA>
#>  92:    0.287611        <NA>        <NA>         999   FALSE         <NA>
#>  93:    1.126676        <NA>                    <NA>    TRUE   2011-11-10
#>  94:    0.439138        <NA>        <NA>         999   FALSE         <NA>
#>  95:    3.185611        <NA>                    <NA>   FALSE         <NA>
#>  96:   -0.401928        <NA>        <NA>         999   FALSE         <NA>
#>  97:   -2.087084        <NA>                    <NA>   FALSE         <NA>
#>  98:   -0.099431        <NA>        <NA>        <NA>   FALSE         <NA>
#>  99:    0.722020        <NA>        <NA>        <NA>   FALSE         <NA>
#> 100:   -3.848476        <NA>        <NA>          -1   FALSE         <NA>
#>      grs_finngen messy_allna messy_empty messy_label htn_hes htn_hes_date
#>            <num>      <char>      <char>      <char>  <lgcl>       <IDat>
#>      htn_death htn_death_date htn_icd10 htn_icd10_date
#>         <lgcl>         <IDat>    <lgcl>         <IDat>
#>   1:     FALSE           <NA>     FALSE           <NA>
#>   2:     FALSE           <NA>     FALSE           <NA>
#>   3:     FALSE           <NA>     FALSE           <NA>
#>   4:     FALSE           <NA>     FALSE           <NA>
#>   5:     FALSE           <NA>     FALSE           <NA>
#>   6:     FALSE           <NA>     FALSE           <NA>
#>   7:     FALSE           <NA>     FALSE           <NA>
#>   8:     FALSE           <NA>     FALSE           <NA>
#>   9:     FALSE           <NA>     FALSE           <NA>
#>  10:     FALSE           <NA>     FALSE           <NA>
#>  11:     FALSE           <NA>     FALSE           <NA>
#>  12:     FALSE           <NA>     FALSE           <NA>
#>  13:     FALSE           <NA>     FALSE           <NA>
#>  14:     FALSE           <NA>     FALSE           <NA>
#>  15:     FALSE           <NA>     FALSE           <NA>
#>  16:     FALSE           <NA>     FALSE           <NA>
#>  17:     FALSE           <NA>      TRUE     2006-10-11
#>  18:     FALSE           <NA>     FALSE           <NA>
#>  19:     FALSE           <NA>     FALSE           <NA>
#>  20:     FALSE           <NA>     FALSE           <NA>
#>  21:     FALSE           <NA>     FALSE           <NA>
#>  22:     FALSE           <NA>     FALSE           <NA>
#>  23:     FALSE           <NA>     FALSE           <NA>
#>  24:     FALSE           <NA>     FALSE           <NA>
#>  25:     FALSE           <NA>     FALSE           <NA>
#>  26:     FALSE           <NA>     FALSE           <NA>
#>  27:     FALSE           <NA>     FALSE           <NA>
#>  28:     FALSE           <NA>     FALSE           <NA>
#>  29:     FALSE           <NA>      TRUE     2005-10-28
#>  30:     FALSE           <NA>     FALSE           <NA>
#>  31:     FALSE           <NA>     FALSE           <NA>
#>  32:     FALSE           <NA>     FALSE           <NA>
#>  33:     FALSE           <NA>     FALSE           <NA>
#>  34:     FALSE           <NA>     FALSE           <NA>
#>  35:     FALSE           <NA>     FALSE           <NA>
#>  36:     FALSE           <NA>     FALSE           <NA>
#>  37:     FALSE           <NA>     FALSE           <NA>
#>  38:     FALSE           <NA>     FALSE           <NA>
#>  39:     FALSE           <NA>     FALSE           <NA>
#>  40:     FALSE           <NA>     FALSE           <NA>
#>  41:     FALSE           <NA>     FALSE           <NA>
#>  42:     FALSE           <NA>     FALSE           <NA>
#>  43:     FALSE           <NA>     FALSE           <NA>
#>  44:     FALSE           <NA>     FALSE           <NA>
#>  45:     FALSE           <NA>     FALSE           <NA>
#>  46:     FALSE           <NA>     FALSE           <NA>
#>  47:     FALSE           <NA>     FALSE           <NA>
#>  48:     FALSE           <NA>     FALSE           <NA>
#>  49:     FALSE           <NA>     FALSE           <NA>
#>  50:     FALSE           <NA>      TRUE     2017-02-10
#>  51:     FALSE           <NA>     FALSE           <NA>
#>  52:     FALSE           <NA>     FALSE           <NA>
#>  53:     FALSE           <NA>     FALSE           <NA>
#>  54:     FALSE           <NA>     FALSE           <NA>
#>  55:     FALSE           <NA>     FALSE           <NA>
#>  56:     FALSE           <NA>     FALSE           <NA>
#>  57:     FALSE           <NA>     FALSE           <NA>
#>  58:     FALSE           <NA>     FALSE           <NA>
#>  59:     FALSE           <NA>     FALSE           <NA>
#>  60:     FALSE           <NA>     FALSE           <NA>
#>  61:     FALSE           <NA>      TRUE     2016-05-04
#>  62:     FALSE           <NA>     FALSE           <NA>
#>  63:     FALSE           <NA>     FALSE           <NA>
#>  64:     FALSE           <NA>     FALSE           <NA>
#>  65:     FALSE           <NA>     FALSE           <NA>
#>  66:     FALSE           <NA>     FALSE           <NA>
#>  67:     FALSE           <NA>     FALSE           <NA>
#>  68:     FALSE           <NA>     FALSE           <NA>
#>  69:     FALSE           <NA>     FALSE           <NA>
#>  70:     FALSE           <NA>     FALSE           <NA>
#>  71:     FALSE           <NA>     FALSE           <NA>
#>  72:     FALSE           <NA>     FALSE           <NA>
#>  73:     FALSE           <NA>     FALSE           <NA>
#>  74:     FALSE           <NA>     FALSE           <NA>
#>  75:     FALSE           <NA>     FALSE           <NA>
#>  76:     FALSE           <NA>     FALSE           <NA>
#>  77:     FALSE           <NA>      TRUE     2016-11-12
#>  78:     FALSE           <NA>     FALSE           <NA>
#>  79:     FALSE           <NA>     FALSE           <NA>
#>  80:     FALSE           <NA>     FALSE           <NA>
#>  81:     FALSE           <NA>     FALSE           <NA>
#>  82:     FALSE           <NA>      TRUE     2017-09-11
#>  83:     FALSE           <NA>     FALSE           <NA>
#>  84:     FALSE           <NA>     FALSE           <NA>
#>  85:     FALSE           <NA>     FALSE           <NA>
#>  86:     FALSE           <NA>     FALSE           <NA>
#>  87:     FALSE           <NA>     FALSE           <NA>
#>  88:     FALSE           <NA>     FALSE           <NA>
#>  89:     FALSE           <NA>     FALSE           <NA>
#>  90:     FALSE           <NA>     FALSE           <NA>
#>  91:     FALSE           <NA>     FALSE           <NA>
#>  92:     FALSE           <NA>     FALSE           <NA>
#>  93:     FALSE           <NA>      TRUE     2011-11-10
#>  94:     FALSE           <NA>     FALSE           <NA>
#>  95:     FALSE           <NA>     FALSE           <NA>
#>  96:     FALSE           <NA>     FALSE           <NA>
#>  97:     FALSE           <NA>     FALSE           <NA>
#>  98:     FALSE           <NA>     FALSE           <NA>
#>  99:     FALSE           <NA>     FALSE           <NA>
#> 100:     FALSE           <NA>     FALSE           <NA>
#>      htn_death htn_death_date htn_icd10 htn_icd10_date
#>         <lgcl>         <IDat>    <lgcl>         <IDat>
derive_icd10(dt, name = "mi",
             icd10  = "I21",
             source = c("hes", "death", "first_occurrence"),
             fo_col = "p131742")
#> ! derive_hes (mi): 0 cases found.
#> ✔ derive_death_registry (mi): 2 cases, 2 with date.
#> ✔ derive_first_occurrence (mi): 5 cases with valid date.
#> ✔ derive_icd10 (mi): 7 cases across 3 sources, 7 with date.
#> Index: <eid>
#>           eid    p31   p34     p53_i0 p21022 p21001_i0            p20116_i0
#>         <int> <char> <int>     <char>  <int>     <num>               <char>
#>   1: 10000001   Male  1947 2006-07-01     70   32.1921                Never
#>   2: 10000002   Male  1953 2010-02-06     40   12.0000                Never
#>   3: 10000003 Female  1978 2009-02-24     57   35.3399             Previous
#>   4: 10000004   Male  1947 2010-12-28     67   25.6982                Never
#>   5: 10000005   Male  1934 2010-02-25     71   33.4425                Never
#>   6: 10000006 Female  1975 2010-04-28     38   30.5572                Never
#>   7: 10000007   Male  1969 2010-09-12     52   27.2689                Never
#>   8: 10000008 Female  1969 2010-03-10     55   20.0618                Never
#>   9: 10000009   Male  1950 2008-09-18     80   25.5108                Never
#>  10: 10000010   Male  1965 2006-12-03     70   22.4651                Never
#>  11: 10000011 Female  1965 2007-06-23     40   17.0800                Never
#>  12: 10000012   Male  1968 2010-04-15     48   25.9817                Never
#>  13: 10000013   Male  1971 2009-04-18     57   25.0374              Current
#>  14: 10000014 Female  1947 2008-05-17     50   21.2340             Previous
#>  15: 10000015 Female  1956 2006-07-31     65   23.3968              Current
#>  16: 10000016   Male  1942 2010-05-30     71   16.0744                Never
#>  17: 10000017   Male  1948 2006-07-20     51   21.1052             Previous
#>  18: 10000018 Female  1961 2009-11-25     54   31.0512                Never
#>  19: 10000019 Female  1945 2006-03-03     78   33.0471                Never
#>  20: 10000020   Male  1958 2009-07-16     59   20.4181             Previous
#>  21: 10000021   Male  1946 2009-11-06     50   22.5421             Previous
#>  22: 10000022 Female  1973 2009-02-21     73   30.2374             Previous
#>  23: 10000023   Male  1938 2008-12-22     50   23.4009                Never
#>  24: 10000024   Male  1950 2007-07-15     35   23.8501              Current
#>  25: 10000025 Female  1972 2007-07-27     76   22.7689              Current
#>  26: 10000026 Female  1977 2010-07-10     70   27.2887                Never
#>  27: 10000027 Female  1937 2010-11-28     39   34.4533             Previous
#>  28: 10000028   Male  1958 2007-06-24     53   19.9263             Previous
#>  29: 10000029 Female  1967 2006-01-02     79   28.9327              Current
#>  30: 10000030   Male  1930 2007-11-02     36   33.9460              Current
#>  31: 10000031   Male  1942 2010-07-30     43   22.7715                Never
#>  32: 10000032   Male  1943 2009-02-24     41   22.1209             Previous
#>  33: 10000033 Female  1934 2009-05-16     80   28.2715                Never
#>  34: 10000034   Male  1938 2008-02-10     39   18.9940                Never
#>  35: 10000035 Female  1945 2008-01-11     54   26.6297             Previous
#>  36: 10000036   Male  1955 2006-09-26     66   21.8252             Previous
#>  37: 10000037 Female  1972 2008-11-01     31   35.9157             Previous
#>  38: 10000038 Female  1971 2007-12-06     64   21.0497                Never
#>  39: 10000039   Male  1971 2007-11-01     63   30.0716                Never
#>  40: 10000040   Male  1962 2010-05-06     56   22.0429                Never
#>  41: 10000041 Female  1958 2007-03-20     75   23.6251             Previous
#>  42: 10000042 Female  1954 2007-11-08     60   21.5553              Current
#>  43: 10000043 Female  1980 2010-05-02     56   20.1965              Current
#>  44: 10000044   Male  1961 2009-05-06     45   18.9216                Never
#>  45: 10000045 Female  1946 2008-06-30     65   22.9462             Previous
#>  46: 10000046   Male  1975 2008-10-30     53   30.3157             Previous
#>  47: 10000047   Male  1943 2008-08-24     67   21.6816             Previous
#>  48: 10000048   Male  1976 2009-07-02     50   16.4947                Never
#>  49: 10000049   Male  1935 2009-05-09     49   24.0631                Never
#>  50: 10000050   Male  1976 2010-11-04     40   22.5190                Never
#>  51: 10000051 Female  1972 2010-03-19     62   30.0748             Previous
#>  52: 10000052 Female  1966 2008-04-29     43   21.6480                Never
#>  53: 10000053 Female  1945 2006-06-30     57   12.0000             Previous
#>  54: 10000054   Male  1978 2008-01-21     62   28.0840                Never
#>  55: 10000055 Female  1978 2009-07-31     58   15.5790                Never
#>  56: 10000056   Male  1979 2010-11-23     65   27.1776                Never
#>  57: 10000057   Male  1960 2007-04-08     74   33.9104             Previous
#>  58: 10000058 Female  1963 2007-08-28     61   28.2519                Never
#>  59: 10000059 Female  1959 2009-08-29     67   25.9327                Never
#>  60: 10000060 Female  1961 2006-03-25     51   39.7490                Never
#>  61: 10000061   Male  1935 2008-09-11     73   29.3218             Previous
#>  62: 10000062   Male  1951 2007-04-09     36   31.5286                Never
#>  63: 10000063   Male  1967 2008-09-10     73   40.7828              Current
#>  64: 10000064   Male  1960 2006-08-13     34   26.0103 Prefer not to answer
#>  65: 10000065   Male  1935 2010-05-16     60   23.9471              Current
#>  66: 10000066 Female  1949 2009-01-30     61   25.6299                Never
#>  67: 10000067 Female  1944 2006-06-20     47   23.0394                Never
#>  68: 10000068   Male  1963 2007-05-04     68   23.3766                Never
#>  69: 10000069   Male  1971 2010-08-13     42   25.8959             Previous
#>  70: 10000070 Female  1952 2008-07-10     59   20.8186             Previous
#>  71: 10000071 Female  1941 2007-11-25     31   26.5229              Current
#>  72: 10000072 Female  1955 2010-05-10     57   26.5400              Current
#>  73: 10000073 Female  1970 2010-05-09     32   24.1073             Previous
#>  74: 10000074 Female  1930 2008-10-19     62   33.9993             Previous
#>  75: 10000075 Female  1931 2010-09-05     76   21.6981              Current
#>  76: 10000076   Male  1953 2009-12-15     58   23.6863              Current
#>  77: 10000077 Female  1963 2010-04-28     49   27.3962                Never
#>  78: 10000078 Female  1954 2009-05-15     72   29.6378                Never
#>  79: 10000079 Female  1957 2009-01-13     38   29.0456             Previous
#>  80: 10000080 Female  1972 2006-06-02     39   25.1804              Current
#>  81: 10000081   Male  1943 2008-08-18     36   25.8478                Never
#>  82: 10000082 Female  1963 2006-08-28     80   22.3258                Never
#>  83: 10000083 Female  1931 2006-02-18     57   22.3517                Never
#>  84: 10000084   Male  1960 2009-03-08     47   29.2850                Never
#>  85: 10000085   Male  1961 2006-06-05     54   26.4631                Never
#>  86: 10000086   Male  1956 2006-10-01     73   29.3183                Never
#>  87: 10000087 Female  1939 2010-05-10     39   19.6211                Never
#>  88: 10000088 Female  1957 2009-06-03     38   31.4778             Previous
#>  89: 10000089 Female  1966 2008-02-01     48   28.9899                Never
#>  90: 10000090 Female  1939 2006-06-19     44   24.1424              Current
#>  91: 10000091   Male  1978 2006-10-19     75   34.0125              Current
#>  92: 10000092 Female  1978 2006-05-28     32   35.5191 Prefer not to answer
#>  93: 10000093 Female  1934 2007-12-20     51   29.0423             Previous
#>  94: 10000094   Male  1964 2006-07-08     49   25.9354                Never
#>  95: 10000095   Male  1943 2009-02-10     71   19.1586                Never
#>  96: 10000096   Male  1943 2008-11-16     63   23.5068             Previous
#>  97: 10000097 Female  1957 2007-08-29     52   33.2823             Previous
#>  98: 10000098 Female  1962 2007-10-07     46   31.3178              Current
#>  99: 10000099   Male  1966 2009-01-14     47   30.1938                Never
#> 100: 10000100   Male  1964 2010-07-08     48   25.1382                Never
#>           eid    p31   p34     p53_i0 p21022 p21001_i0            p20116_i0
#>         <int> <char> <int>     <char>  <int>     <num>               <char>
#>                        p1558_i0 p21000_i0 p22189     p54_i0 p22009_a1 p22009_a2
#>                          <char>    <char>  <num>     <char>     <num>     <num>
#>   1: One to three times a month     White  -3.96  Liverpool  1.303365 -2.277778
#>   2: Three or four times a week     White  -1.73      Leeds -1.500221  0.290524
#>   3:       Once or twice a week     Asian  -0.68 Manchester -0.606989  0.422306
#>   4: Three or four times a week     White  -4.20  Newcastle -0.292245  1.294737
#>   5:       Once or twice a week     White  -2.31 Nottingham -1.289683  0.164714
#>   6:     Special occasions only     White  -4.98  Edinburgh  0.694106  0.204954
#>   7:       Once or twice a week     White  -7.00 Manchester -0.599182  0.604604
#>   8:      Daily or almost daily     White   1.33      Leeds  1.256907 -0.019141
#>   9:      Daily or almost daily     White  -3.60     Oxford  0.053508 -0.079714
#>  10:     Special occasions only     Asian  -4.97  Edinburgh  0.728093  0.115984
#>  11:      Daily or almost daily     White   2.50  Sheffield  1.561098  0.744173
#>  12: One to three times a month     Asian  -5.44 Birmingham  0.265625 -0.431291
#>  13: One to three times a month     White   2.13     Oxford  1.076726 -0.499529
#>  14: Three or four times a week     White  -4.79      Leeds  0.210698 -0.865162
#>  15:       Once or twice a week     White  -6.30  Edinburgh -1.511674 -0.957757
#>  16:     Special occasions only     Asian  -7.00     Oxford  0.022402  0.326800
#>  17:       Once or twice a week     White  -6.20  Sheffield  0.718136  1.547372
#>  18: Three or four times a week     White  -0.98 Nottingham  0.489457 -0.968860
#>  19: One to three times a month     White  -7.00  Newcastle -0.173888 -0.188440
#>  20: Three or four times a week     White   0.56     Oxford -1.217699 -1.030001
#>  21:       Once or twice a week     White   1.53  Liverpool  0.646398  0.908086
#>  22:                      Never     White  -0.78  Edinburgh -0.916456 -0.317382
#>  23: Three or four times a week     White  -4.05 Manchester -1.251823  0.179004
#>  24:     Special occasions only     White   1.82     Oxford  0.594928  0.348028
#>  25:       Once or twice a week     White  -3.28 Manchester -1.232811 -1.054279
#>  26: One to three times a month     White  -2.99  Liverpool  0.244364 -0.104744
#>  27:       Once or twice a week     Asian  -6.92  Liverpool  0.002772 -0.228343
#>  28: Three or four times a week     White  -2.89 Birmingham -1.328210  0.675356
#>  29:       Once or twice a week     White  -2.33      Leeds  1.179696 -1.233245
#>  30:                      Never     White  -6.67    Bristol -0.592805 -1.199962
#>  31:       Once or twice a week     White   2.96    Bristol  1.199978  0.765867
#>  32:      Daily or almost daily     White  -4.35     Oxford -0.475034 -0.588098
#>  33:      Daily or almost daily     White  -4.72 Manchester -0.575057 -0.660296
#>  34:       Once or twice a week     White  -0.94  Edinburgh -0.031226  0.113014
#>  35: One to three times a month     White  -0.19 Manchester -0.358057 -0.320399
#>  36: One to three times a month     White  -5.67      Leeds -0.356601  1.866381
#>  37:       Once or twice a week     Other  -2.56 Nottingham -0.877664  0.259531
#>  38: One to three times a month     White  -0.29 Manchester -1.212897  0.161560
#>  39:       Once or twice a week     White  -4.02 Nottingham  0.613287  0.931075
#>  40: Three or four times a week     White   1.92  Newcastle -0.806203 -0.059947
#>  41: One to three times a month     White  -7.00 Birmingham -1.376457  0.048740
#>  42:       Once or twice a week     White  -3.93    Bristol -0.507848 -1.072875
#>  43:      Daily or almost daily     White   0.27     Oxford -0.800935 -2.292971
#>  44: One to three times a month     Other   1.67  Newcastle -2.192786 -1.207207
#>  45: One to three times a month     Asian  -1.08 Nottingham -0.290937  0.114109
#>  46:     Special occasions only     White  -3.10      Leeds  0.167174 -1.033297
#>  47: One to three times a month     White   2.76 Nottingham  0.294692  0.688808
#>  48:      Daily or almost daily     Mixed  -6.52  Edinburgh  0.392741  0.725083
#>  49:       Once or twice a week     White   0.34 Nottingham -1.000844  0.217380
#>  50:       Once or twice a week     White  -3.52    Bristol -0.325727 -0.201657
#>  51: One to three times a month     White  -0.32 Manchester -1.008349 -1.365690
#>  52:       Once or twice a week     White  -6.85 Birmingham -0.635431 -0.308938
#>  53: One to three times a month     Mixed   3.94  Sheffield -1.209841 -0.452903
#>  54: Three or four times a week     Mixed   0.18  Sheffield -1.116464  0.663229
#>  55:       Once or twice a week     White  -6.71  Edinburgh  0.629881  1.308630
#>  56:       Once or twice a week     White  -5.39     Oxford -0.272522  0.501040
#>  57:      Daily or almost daily     White   4.72  Newcastle -0.258841 -1.128289
#>  58:       Once or twice a week     White   0.61 Nottingham  1.729558  1.670997
#>  59:       Once or twice a week     White  -7.00 Birmingham -0.058392  1.010353
#>  60:       Once or twice a week     White  -1.03     Oxford -0.537064  0.223521
#>  61:       Once or twice a week     White  -6.72     Oxford  0.747287 -2.206485
#>  62:       Once or twice a week     White  -7.00  Newcastle -0.487258 -0.954586
#>  63: Three or four times a week     Other  -1.09  Newcastle  1.372908 -0.068573
#>  64:       Once or twice a week     Asian  -1.26 Birmingham -0.377672  0.761306
#>  65: Three or four times a week     Other  -5.65      Leeds -0.616153 -1.179904
#>  66: One to three times a month     White  -0.78  Edinburgh -1.168125  3.211199
#>  67: One to three times a month     White   0.13 Nottingham  0.328640 -2.553825
#>  68:       Once or twice a week     White  -5.96 Manchester  1.466511 -0.235934
#>  69:     Special occasions only     White  -0.14 Manchester -0.356010 -0.259563
#>  70:      Daily or almost daily     White  -2.18  Newcastle  0.261468 -0.663367
#>  71:       Once or twice a week     White   2.36  Sheffield  0.333329 -0.318991
#>  72:     Special occasions only     White  -2.47     Oxford  1.422193  0.742395
#>  73:                      Never     White   0.81 Birmingham  0.663877 -0.874293
#>  74:       Once or twice a week     White  -5.26    Bristol -1.073655 -2.082814
#>  75: One to three times a month     White   1.31 Birmingham -0.696902  0.093768
#>  76: One to three times a month     White   2.94     Oxford -0.746130 -0.001820
#>  77:       Once or twice a week     White   2.85      Leeds  0.141573 -0.013101
#>  78:       Once or twice a week     White  -2.55      Leeds -0.003947  0.667968
#>  79: Three or four times a week     White   1.28 Nottingham  0.367938 -0.013168
#>  80:                      Never     White   1.16    Bristol -0.657343  0.776047
#>  81:       Once or twice a week     White  -1.64  Sheffield -0.376347 -2.010735
#>  82: One to three times a month     White   0.76  Liverpool  0.741360 -1.128180
#>  83:     Special occasions only     White  -7.00  Edinburgh -0.099607  0.348800
#>  84: Three or four times a week     White  -0.52 Nottingham -0.654290 -0.352898
#>  85: Three or four times a week     White  -6.41 Birmingham  0.971164  0.944775
#>  86:     Special occasions only     White  -1.06  Edinburgh  0.013496 -1.004720
#>  87:       Once or twice a week     White   3.79  Edinburgh -0.916535  0.723903
#>  88: One to three times a month     White   0.39 Birmingham  1.709689 -0.668833
#>  89:      Daily or almost daily     White  -3.54  Liverpool -1.168101 -1.113040
#>  90: Three or four times a week     White  -2.72 Manchester -1.781036 -0.342805
#>  91:      Daily or almost daily     White  -5.25    Bristol -2.253132  0.049779
#>  92:       Prefer not to answer     White  -7.00 Manchester  0.651126 -1.227682
#>  93:     Special occasions only     White   1.45      Leeds -0.532833 -0.764006
#>  94: Three or four times a week     White   3.52     Oxford -0.275559 -1.246182
#>  95:       Once or twice a week     White  -1.21     Oxford  0.289627  1.016774
#>  96: Three or four times a week     White  -4.47  Newcastle -0.466484  0.723613
#>  97:                      Never     Asian  -1.84  Newcastle -1.608060 -1.032527
#>  98:       Once or twice a week     White  -1.72     Oxford -1.949784  0.557346
#>  99:       Once or twice a week     White  -3.53    Bristol -0.340700 -0.255581
#> 100: Three or four times a week     White  -2.42  Sheffield  0.174726 -1.113392
#>                        p1558_i0 p21000_i0 p22189     p54_i0 p22009_a1 p22009_a2
#>                          <char>    <char>  <num>     <char>     <num>     <num>
#>      p22009_a3 p22009_a4 p22009_a5 p22009_a6 p22009_a7 p22009_a8 p22009_a9
#>          <num>     <num>     <num>     <num>     <num>     <num>     <num>
#>   1:  0.421197 -0.914455  0.431134  2.633710 -1.166339  0.475958  0.610679
#>   2: -0.322950  0.528728  0.558312  0.166114  0.041895  0.573154 -0.666510
#>   3:  0.880180  0.835079  0.495961  1.905176  1.246489 -1.018860 -1.059883
#>   4: -0.194864  1.209137  1.661886  0.253718 -1.577971 -0.061872 -0.605839
#>   5:  1.188055  1.299473 -1.055035 -1.459022 -0.253820 -0.538305 -1.056841
#>   6: -0.509765  1.075732  1.508325 -2.227248  0.467831  0.416955  0.533106
#>   7:  0.219548  0.939801 -0.334209  0.649684  1.977530 -1.508277 -1.552093
#>   8:  0.370294  0.163375 -0.064981 -0.999250 -0.615606  1.539170 -0.978489
#>   9:  0.279108 -0.888139  0.081082  0.041972  1.519422  1.346018  0.027218
#>  10:  0.201942 -0.726161 -0.448215  1.777044 -0.432895 -0.842856 -1.715572
#>  11: -0.012997  0.407597 -2.553807  0.347183 -1.031018 -0.669874 -0.504888
#>  12: -0.090865  1.683536 -0.312933 -0.287097 -1.134334 -0.908487 -0.304923
#>  13:  1.365031  1.705980  0.041383 -1.924577 -0.221098 -0.136541  1.346078
#>  14:  0.908131 -1.926167 -1.737728 -0.800649 -0.022415 -0.501038 -0.257537
#>  15: -0.609888 -0.833998  0.549940 -0.575618 -0.322902  0.112638 -0.523287
#>  16:  1.396437  1.419133 -0.597274  0.684206  1.052223 -1.875218 -0.663218
#>  17:  0.144798 -1.064110  1.447742  0.483457  0.189541  0.158547  0.447221
#>  18: -0.640607 -1.613577  0.264868  0.013963 -0.105828  0.015563 -0.319451
#>  19:  0.169802  0.599811 -0.788783  0.180244 -0.602554 -1.600603 -0.543779
#>  20: -0.157187  1.732965  0.167732 -0.288123 -1.296016  0.275973 -0.279673
#>  21:  0.100940  1.934505  0.257583  0.030227 -1.959327  0.054953  1.065233
#>  22: -0.973394  0.532821  0.912047  0.271674  0.213412 -0.230573  1.567829
#>  23: -0.819825  0.719666 -0.156872  0.449158  0.025336 -0.013216 -0.643112
#>  24:  1.362919  0.560093 -2.033376  1.827628  1.365023  0.384949  0.020522
#>  25:  0.961371 -0.018087 -1.299666 -1.112024  0.291094  0.346724 -0.324184
#>  26: -0.883724 -3.371739 -0.857251  1.474807  0.797218 -0.431613  1.857396
#>  27: -0.900092  0.760703  0.426265  0.671512  0.040986  1.150178  0.590764
#>  28:  1.723333 -0.391227 -0.284836 -1.545329 -0.818324 -0.036532 -1.780627
#>  29:  1.909042  1.009901 -0.614369 -0.277047  0.289641 -0.135801 -0.434109
#>  30: -0.777141 -0.626973 -0.844891 -0.629343  0.339787  0.944618 -2.292750
#>  31: -1.302305 -1.634577  0.153695 -0.933000 -0.817393  0.992041 -0.092965
#>  32:  2.623495  1.245243 -0.851432 -1.537886 -0.028749 -0.700670  0.703964
#>  33:  0.229629  0.181377 -0.397921 -0.494102  2.000782 -0.991059 -0.894490
#>  34:  0.186750  3.495304 -0.939977 -0.435360 -1.129266 -0.705618 -1.282507
#>  35:  0.076137  0.915592 -1.388254 -0.323545  1.472179 -1.175776  1.255784
#>  36:  1.404860  1.048507  0.955185 -2.061114 -0.227069 -1.781197 -0.964630
#>  37: -0.191722  0.763825 -1.317495  0.441503  1.482311  0.310608  0.907784
#>  38:  1.459392 -0.603387  0.073029  0.746351 -0.843053 -0.145110  0.214074
#>  39: -0.220655 -0.370430 -0.568186  0.789643 -0.066195  0.642550  0.881023
#>  40:  0.505146  1.059826 -1.058451  0.770741  0.311233 -0.001659  1.002545
#>  41: -1.033497  1.055111  0.259314  0.200506 -0.112590  0.409163  1.139911
#>  42:  0.170473  0.582972  0.373135  1.468350  0.658739 -0.496058  1.236036
#>  43:  1.200668 -0.986567  1.264667 -0.876455 -0.166862 -0.960108  0.295402
#>  44: -0.163406  1.684622  0.325225 -1.226605  1.208873  0.778132  0.171761
#>  45:  1.282476 -1.366841 -0.138467  0.337838  0.170419  0.761121 -0.955389
#>  46:  2.727196 -0.433214  2.602469  0.440824  0.692420 -1.733712 -1.210409
#>  47:  0.941924  2.325058 -0.650284 -0.746516 -1.185547  0.877295 -0.601383
#>  48: -0.248614  0.524122 -1.003183  0.036606 -0.658389 -1.773371 -0.135816
#>  49:  0.096479  0.970733 -0.535114  0.323310  1.089508 -0.045687 -0.987273
#>  50: -0.433931  0.376973 -0.110415  0.379676  0.508786 -0.394872  0.831925
#>  51:  2.178668 -0.995933  0.600430  0.876556 -0.135907 -0.128056 -0.795060
#>  52: -2.958780 -0.597483  0.415845  0.933388 -0.108783  1.096238  0.340465
#>  53:  0.080888  0.165251 -0.105751 -2.428808  0.754900 -1.255218  0.870430
#>  54:  0.110138 -2.928477 -0.856563  1.727994 -0.223811 -0.265484 -1.182161
#>  55:  0.213448 -0.847914  1.127327  0.456003  0.074955  2.553302  1.022894
#>  56: -1.557820  0.798585  0.916282 -0.570360 -1.645955 -1.478306 -2.108435
#>  57:  0.216212 -0.298456 -0.724380 -1.114624  1.774009 -0.626588  0.229763
#>  58:  0.187664 -0.283611  0.686779  0.905064  0.765968 -0.041052  1.511711
#>  59:  1.258622  0.869519  0.450086  0.328096  0.832288  0.199953  0.555438
#>  60:  0.523518 -0.544355  1.045222  1.078090 -1.905458 -0.533306  0.914879
#>  61:  1.115454  0.628803  0.149629 -0.060316 -0.020837 -0.266032 -0.553397
#>  62: -0.957502 -1.422334 -1.141067 -0.243519 -0.408934  1.084148  0.298376
#>  63: -0.124406 -1.227513  0.802499  2.241423 -1.376386 -0.180745  1.106380
#>  64:  0.191738 -1.674106 -0.728717 -2.035993  0.727430  0.251555 -1.329150
#>  65:  0.272217  0.084398  0.527209  0.390914  1.234131  0.369542  1.001694
#>  66: -0.693814 -0.206126  1.673479  0.384813 -0.553224  0.407034 -1.409304
#>  67:  1.479172  1.441872 -1.418828  0.438696 -0.229190  0.492505 -0.498781
#>  68: -0.611767 -0.041782  1.561911  0.558141  1.711462  0.054633  2.622757
#>  69: -1.614310  1.353754  1.353161 -0.276406 -1.649808 -0.708674  0.510666
#>  70:  0.402490  1.945225 -0.528697  1.166288  0.744221 -0.058271 -0.090843
#>  71:  0.664555 -0.490938 -0.251273 -2.454277 -0.314021 -0.963422  0.978766
#>  72:  0.944127  0.388439 -0.685848 -0.805566 -0.115311  0.093393 -0.243809
#>  73: -0.946261 -0.844893 -0.570368 -0.119145 -0.610974 -0.347901  0.621809
#>  74: -0.248288  0.737990  0.579631  0.163216  1.096695 -0.118334 -0.344595
#>  75: -1.328436 -1.079760 -0.898959  0.406480 -1.127168 -1.099091 -2.355225
#>  76:  0.844764 -1.026474 -0.190330  0.639340  0.962609 -0.283076  0.472388
#>  77:  0.347697  0.288793 -0.143903 -1.508518  1.406464 -1.089735 -0.511480
#>  78:  0.913763  0.090811 -0.096573  0.007671 -1.641650 -0.405666 -0.573602
#>  79:  0.608275  0.262623  0.181447  0.524168 -1.126904  0.526907  0.003797
#>  80: -0.607548  0.069335  1.596574  1.326336  0.591545  0.240420  1.342551
#>  81:  0.179658 -0.528644 -0.451332 -0.113568 -0.956309  0.898362  0.295462
#>  82: -1.908409 -0.130202 -0.794880  1.599149 -0.691530  0.487968  0.841787
#>  83:  0.502946  1.620159  0.792284 -0.281528 -0.445353  0.111991  0.629064
#>  84:  0.968899 -0.017895  0.380472 -0.049898 -0.344484  0.998313  0.101598
#>  85: -0.875737 -1.318489  0.235788  0.160214  0.703698  1.191717  0.671121
#>  86: -2.136025 -0.844560  0.590988 -0.502381 -0.603006 -1.399388 -0.138316
#>  87: -1.522828 -1.101815 -1.411930  0.715938  0.089350  0.892148 -1.249312
#>  88: -1.113118 -0.900090  1.063296 -1.345787  0.737495  0.777959  0.347635
#>  89:  1.240984 -1.261084  0.453918 -0.005644 -1.540379  0.941915 -2.277814
#>  90:  0.003482 -2.625849  0.951313 -0.540543 -0.689632 -0.908803 -0.986209
#>  91: -1.237795  0.669066 -0.598518 -0.547074  0.859793  2.408931 -0.059541
#>  92:  0.555699  0.660042 -1.841940  1.151445 -0.376520 -2.594250 -0.160759
#>  93: -2.183149 -0.250600 -0.484590  1.052220 -2.535083  0.006863 -0.420362
#>  94: -0.247024 -0.723797 -0.906847  1.598027 -0.857809  0.118107  0.988591
#>  95:  1.112857 -0.812182  2.222762 -0.263797  0.816026 -0.149697 -1.069614
#>  96: -0.341673  0.398734 -0.413467  0.032401 -0.426589  0.747873 -2.613643
#>  97:  1.305438  0.226564 -0.215674 -1.551583 -0.404637  0.124035  0.780452
#>  98:  1.795324  0.421644  1.062979 -0.388179 -0.145769 -0.778055  0.045105
#>  99: -1.167835  0.004838  0.620347  1.764148  0.719466  1.410033 -0.108489
#> 100: -1.152288  0.618984  0.673067 -0.416528 -0.491091 -0.293912 -0.391224
#>      p22009_a3 p22009_a4 p22009_a5 p22009_a6 p22009_a7 p22009_a8 p22009_a9
#>          <num>     <num>     <num>     <num>     <num>     <num>     <num>
#>      p22009_a10                       p20002_i0_a0
#>           <num>                             <char>
#>   1:  -1.687000                               <NA>
#>   2:  -0.952704                     joint disorder
#>   3:   0.507414 heart attack/myocardial infarction
#>   4:   0.018816                               <NA>
#>   5:  -1.418910                               <NA>
#>   6:   0.598172                               <NA>
#>   7:   0.786380                               <NA>
#>   8:  -0.134633                               <NA>
#>   9:  -0.016387                               <NA>
#>  10:   1.409140                               <NA>
#>  11:   0.394839                               <NA>
#>  12:   1.219875                               <NA>
#>  13:  -0.045077                               <NA>
#>  14:   1.479488                               <NA>
#>  15:  -0.075684                               <NA>
#>  16:   0.917748                               <NA>
#>  17:  -0.344779                               <NA>
#>  18:  -1.077003                               <NA>
#>  19:   1.001605                               <NA>
#>  20:   2.296004                               <NA>
#>  21:  -0.325878       thyroid problem (not cancer)
#>  22:   1.468856                               <NA>
#>  23:  -0.236909                               <NA>
#>  24:   0.923493                               <NA>
#>  25:  -0.989192                               <NA>
#>  26:   0.275646                               <NA>
#>  27:  -0.763661                               <NA>
#>  28:  -1.352112                               <NA>
#>  29:   0.655024                       back problem
#>  30:   1.609647                       back problem
#>  31:  -0.788507                               <NA>
#>  32:  -0.883876                               <NA>
#>  33:  -1.072515                               <NA>
#>  34:  -0.458141                               <NA>
#>  35:   0.665647                       hypertension
#>  36:   0.712228                               <NA>
#>  37:   0.442954                               <NA>
#>  38:   0.759587                               <NA>
#>  39:  -0.468878                               <NA>
#>  40:  -0.172710                               <NA>
#>  41:   0.682050                               <NA>
#>  42:  -0.281577                               <NA>
#>  43:  -0.961623 heart attack/myocardial infarction
#>  44:  -1.377650 heart attack/myocardial infarction
#>  45:   2.697587                               <NA>
#>  46:  -1.699715                               <NA>
#>  47:   0.029317                               <NA>
#>  48:   1.934314                               <NA>
#>  49:   0.837511                       back problem
#>  50:  -0.185346                             asthma
#>  51:   0.533329                               <NA>
#>  52:   1.784956                               <NA>
#>  53:   0.189628                               <NA>
#>  54:  -0.569088                           fracture
#>  55:   1.451893                       back problem
#>  56:   1.868993                               <NA>
#>  57:  -0.984555                     joint disorder
#>  58:   0.718757                               <NA>
#>  59:   0.129347                               <NA>
#>  60:   0.701641                               <NA>
#>  61:   0.526698                               <NA>
#>  62:  -0.020513                               <NA>
#>  63:   0.438251                               <NA>
#>  64:  -1.210529                               <NA>
#>  65:  -1.404420                               <NA>
#>  66:   0.720749                               <NA>
#>  67:   0.086036                               <NA>
#>  68:  -0.131617                       hypertension
#>  69:  -1.676052                               <NA>
#>  70:  -0.569498                               <NA>
#>  71:   0.192205                               <NA>
#>  72:  -0.486323                               <NA>
#>  73:   0.081284                               <NA>
#>  74:   0.384897                               <NA>
#>  75:  -0.137502                               <NA>
#>  76:   0.427593                           fracture
#>  77:  -0.243064                               <NA>
#>  78:  -0.318353                               <NA>
#>  79:  -0.254106                               <NA>
#>  80:   0.638887                               <NA>
#>  81:   0.821065                               <NA>
#>  82:   2.335479                               <NA>
#>  83:  -0.983308                               <NA>
#>  84:  -0.707457                               <NA>
#>  85:   0.644149                               <NA>
#>  86:   1.637665                       hypertension
#>  87:   1.226648                               <NA>
#>  88:  -0.467706                               <NA>
#>  89:  -0.678231                               <NA>
#>  90:   1.696402                               <NA>
#>  91:   1.542847                           fracture
#>  92:   0.214528                               <NA>
#>  93:   1.700688                               <NA>
#>  94:  -0.007987                               <NA>
#>  95:  -0.817900                               <NA>
#>  96:  -0.050610                               <NA>
#>  97:   0.079921                       hypertension
#>  98:  -1.559571                               <NA>
#>  99:  -0.171498                               <NA>
#> 100:  -0.418607                               <NA>
#>      p22009_a10                       p20002_i0_a0
#>           <num>                             <char>
#>                            p20002_i0_a1   p20002_i0_a2
#>                                  <char>         <char>
#>   1:                               <NA>           <NA>
#>   2:                               <NA>           <NA>
#>   3:                               <NA>           <NA>
#>   4:                               <NA>           <NA>
#>   5:                               <NA>           <NA>
#>   6:                               <NA>           <NA>
#>   7:                       hypertension           <NA>
#>   8:                               <NA>           <NA>
#>   9:                               <NA>           <NA>
#>  10:                               <NA>           <NA>
#>  11:                               <NA>           <NA>
#>  12:                               <NA>           <NA>
#>  13:                               <NA>           <NA>
#>  14:                               <NA>           <NA>
#>  15:                               <NA>           <NA>
#>  16:                               <NA>           <NA>
#>  17:                               <NA>           <NA>
#>  18:                     joint disorder           <NA>
#>  19:                               <NA>           <NA>
#>  20:                               <NA>           <NA>
#>  21:                               <NA>           <NA>
#>  22:                             asthma           <NA>
#>  23:                               <NA> joint disorder
#>  24:                               <NA>           <NA>
#>  25:                               <NA>           <NA>
#>  26:                             asthma           <NA>
#>  27:                               <NA>           <NA>
#>  28:                               <NA>           <NA>
#>  29:                               <NA>           <NA>
#>  30:                               <NA>           <NA>
#>  31:                               <NA>           <NA>
#>  32:                               <NA>           <NA>
#>  33:                               <NA>           <NA>
#>  34:                               <NA>           <NA>
#>  35:                           fracture           <NA>
#>  36: heart attack/myocardial infarction           <NA>
#>  37:       thyroid problem (not cancer)           <NA>
#>  38:                               <NA>           <NA>
#>  39:                               <NA>           <NA>
#>  40:                       hypertension           <NA>
#>  41:                               <NA>           <NA>
#>  42:                               <NA>           <NA>
#>  43:                               <NA>           <NA>
#>  44:                     joint disorder           <NA>
#>  45:                       back problem           <NA>
#>  46:                               <NA>           <NA>
#>  47:                               <NA>           <NA>
#>  48:                               <NA>           <NA>
#>  49:                               <NA>           <NA>
#>  50:       thyroid problem (not cancer)           <NA>
#>  51:                               <NA>           <NA>
#>  52:                               <NA>           <NA>
#>  53:                               <NA>           <NA>
#>  54:                               <NA>   back problem
#>  55:                               <NA>           <NA>
#>  56:                               <NA>           <NA>
#>  57:                               <NA>           <NA>
#>  58: heart attack/myocardial infarction           <NA>
#>  59:                               <NA>           <NA>
#>  60:                               <NA>           <NA>
#>  61:                               <NA>           <NA>
#>  62:                               <NA>           <NA>
#>  63:       thyroid problem (not cancer)           <NA>
#>  64:                               <NA>           <NA>
#>  65:                               <NA> joint disorder
#>  66:                               <NA>           <NA>
#>  67:                               <NA>           <NA>
#>  68:                               <NA>           <NA>
#>  69:                           fracture           <NA>
#>  70:                               <NA>           <NA>
#>  71:                               <NA>           <NA>
#>  72:                               <NA>           <NA>
#>  73:                               <NA>           <NA>
#>  74:       thyroid problem (not cancer)           <NA>
#>  75:                               <NA>           <NA>
#>  76:                               <NA>       fracture
#>  77:                       hypertension           <NA>
#>  78:                               <NA>           <NA>
#>  79:                           fracture           <NA>
#>  80:                               <NA>           <NA>
#>  81:                               <NA>           <NA>
#>  82:                               <NA>           <NA>
#>  83:                               <NA>           <NA>
#>  84:                               <NA>           <NA>
#>  85:                       hypertension           <NA>
#>  86:                               <NA>           <NA>
#>  87:                               <NA>           <NA>
#>  88:                             asthma   back problem
#>  89:                               <NA>   hypertension
#>  90:                               <NA>           <NA>
#>  91:                               <NA>           <NA>
#>  92:                               <NA>           <NA>
#>  93:       thyroid problem (not cancer)           <NA>
#>  94:                               <NA>   back problem
#>  95:                               <NA>           <NA>
#>  96:                               <NA>           <NA>
#>  97:                               <NA>           <NA>
#>  98:                               <NA>           <NA>
#>  99:                               <NA>           <NA>
#> 100:                               <NA>           <NA>
#>                            p20002_i0_a1   p20002_i0_a2
#>                                  <char>         <char>
#>                      p20002_i0_a3    p20002_i0_a4 p20008_i0_a0 p20008_i0_a1
#>                            <char>          <char>        <num>        <num>
#>   1:                         <NA>            <NA>           NA           NA
#>   2:                         <NA>            <NA>       2013.5           NA
#>   3:                 back problem            <NA>       2000.5           NA
#>   4:                         <NA>            <NA>           NA           NA
#>   5:                         <NA>            <NA>           NA           NA
#>   6:                         <NA>            <NA>           NA           NA
#>   7:                         <NA>            <NA>           NA       2004.5
#>   8:                         <NA>            <NA>           NA           NA
#>   9:                         <NA>            <NA>           NA           NA
#>  10:                         <NA>            <NA>           NA           NA
#>  11:                         <NA>            <NA>           NA           NA
#>  12:                         <NA>            <NA>           NA           NA
#>  13:                         <NA>            <NA>           NA           NA
#>  14:                         <NA>            <NA>           NA           NA
#>  15:                         <NA>            <NA>           NA           NA
#>  16:                         <NA>            <NA>           NA           NA
#>  17:                         <NA>            <NA>           NA           NA
#>  18:                         <NA>            <NA>           NA       2006.5
#>  19:                         <NA>            <NA>           NA           NA
#>  20:                         <NA>            <NA>           NA           NA
#>  21:                         <NA> type 2 diabetes       2002.5           NA
#>  22:                         <NA>            <NA>           NA       2006.5
#>  23:                         <NA>            <NA>           NA           NA
#>  24:                         <NA>            <NA>           NA           NA
#>  25:                         <NA>            <NA>           NA           NA
#>  26:                         <NA>            <NA>           NA       2014.5
#>  27:                         <NA>            <NA>           NA           NA
#>  28:                         <NA>            <NA>           NA           NA
#>  29:                         <NA>            <NA>       2009.5           NA
#>  30:                         <NA>            <NA>       2001.5           NA
#>  31:                         <NA>            <NA>           NA           NA
#>  32:                         <NA>            <NA>           NA           NA
#>  33:                         <NA> type 2 diabetes           NA           NA
#>  34:                         <NA>            <NA>           NA           NA
#>  35:                         <NA>            <NA>       2003.5       2005.5
#>  36:                         <NA>            <NA>           NA       2014.5
#>  37:                         <NA>            <NA>           NA       2007.5
#>  38:                         <NA>            <NA>           NA           NA
#>  39:                         <NA>            <NA>           NA           NA
#>  40:                         <NA>            <NA>           NA       2009.5
#>  41:                         <NA>            <NA>           NA           NA
#>  42:                         <NA>            <NA>           NA           NA
#>  43:                         <NA>            <NA>       2004.5           NA
#>  44:                         <NA>            <NA>       2005.5       2011.5
#>  45:                         <NA>            <NA>           NA       2005.5
#>  46:               joint disorder            <NA>           NA           NA
#>  47:                         <NA>            <NA>           NA           NA
#>  48:                         <NA>            <NA>           NA           NA
#>  49:                 hypertension            <NA>       2001.5           NA
#>  50:                         <NA>            <NA>       2005.5       2015.5
#>  51:                         <NA>            <NA>           NA           NA
#>  52:                         <NA>            <NA>           NA           NA
#>  53:                 hypertension            <NA>           NA           NA
#>  54:                         <NA>            <NA>       2015.5           NA
#>  55:                         <NA>            <NA>       2009.5           NA
#>  56:                         <NA>            <NA>           NA           NA
#>  57:                         <NA>            <NA>       2004.5           NA
#>  58:                         <NA>            <NA>           NA       2012.5
#>  59:                     fracture            <NA>           NA           NA
#>  60:                         <NA>            <NA>           NA           NA
#>  61:                         <NA>        fracture           NA           NA
#>  62:                         <NA>            <NA>           NA           NA
#>  63:                         <NA>            <NA>           NA       2011.5
#>  64:                         <NA>            <NA>           NA           NA
#>  65:                         <NA>        fracture           NA           NA
#>  66:                         <NA>            <NA>           NA           NA
#>  67:                         <NA>            <NA>           NA           NA
#>  68:                         <NA>            <NA>       2009.5           NA
#>  69:                         <NA>            <NA>           NA       2015.5
#>  70:                         <NA>            <NA>           NA           NA
#>  71:                         <NA>            <NA>           NA           NA
#>  72:                         <NA>            <NA>           NA           NA
#>  73:                         <NA>            <NA>           NA           NA
#>  74:                         <NA>            <NA>           NA       2008.5
#>  75:                         <NA>            <NA>           NA           NA
#>  76:                         <NA>            <NA>       2005.5           NA
#>  77:                         <NA>            <NA>           NA       2001.5
#>  78:                         <NA>            <NA>           NA           NA
#>  79:                         <NA>            <NA>           NA       2005.5
#>  80:                         <NA>            <NA>           NA           NA
#>  81:                         <NA>            <NA>           NA           NA
#>  82:                         <NA>            <NA>           NA           NA
#>  83:                         <NA>            <NA>           NA           NA
#>  84:                         <NA>            <NA>           NA           NA
#>  85:                         <NA>            <NA>           NA       2011.5
#>  86:                         <NA>            <NA>       2010.5           NA
#>  87:                         <NA>            <NA>           NA           NA
#>  88:                         <NA>            <NA>           NA       2009.5
#>  89:                         <NA>            <NA>           NA           NA
#>  90:                         <NA>            <NA>           NA           NA
#>  91:                         <NA>            <NA>       2005.5           NA
#>  92:                         <NA>            <NA>           NA           NA
#>  93:                         <NA>            <NA>           NA       2006.5
#>  94:                         <NA>            <NA>           NA           NA
#>  95:                         <NA>            <NA>           NA           NA
#>  96:                         <NA>            <NA>           NA           NA
#>  97: thyroid problem (not cancer)            <NA>       2005.5           NA
#>  98:                         <NA>            <NA>           NA           NA
#>  99:                 hypertension            <NA>           NA           NA
#> 100:                     fracture            <NA>           NA           NA
#>                      p20002_i0_a3    p20002_i0_a4 p20008_i0_a0 p20008_i0_a1
#>                            <char>          <char>        <num>        <num>
#>      p20008_i0_a2 p20008_i0_a3 p20008_i0_a4 p20001_i0_a0
#>             <num>        <num>        <num>       <char>
#>   1:           NA           NA           NA         <NA>
#>   2:           NA           NA           NA         <NA>
#>   3:           NA       2011.5           NA         <NA>
#>   4:           NA           NA           NA         <NA>
#>   5:           NA           NA           NA         <NA>
#>   6:           NA           NA           NA         <NA>
#>   7:           NA           NA           NA         <NA>
#>   8:           NA           NA           NA         <NA>
#>   9:           NA           NA           NA         <NA>
#>  10:           NA           NA           NA         <NA>
#>  11:           NA           NA           NA         <NA>
#>  12:           NA           NA           NA         <NA>
#>  13:           NA           NA           NA         <NA>
#>  14:           NA           NA           NA         <NA>
#>  15:           NA           NA           NA         <NA>
#>  16:           NA           NA           NA         <NA>
#>  17:           NA           NA           NA         <NA>
#>  18:           NA           NA           NA         <NA>
#>  19:           NA           NA           NA         <NA>
#>  20:           NA           NA           NA         <NA>
#>  21:           NA           NA       2003.5         <NA>
#>  22:           NA           NA           NA         <NA>
#>  23:       2005.5           NA           NA         <NA>
#>  24:           NA           NA           NA         <NA>
#>  25:           NA           NA           NA         <NA>
#>  26:           NA           NA           NA         <NA>
#>  27:           NA           NA           NA         <NA>
#>  28:           NA           NA           NA         <NA>
#>  29:           NA           NA           NA         <NA>
#>  30:           NA           NA           NA         <NA>
#>  31:           NA           NA           NA         <NA>
#>  32:           NA           NA           NA         <NA>
#>  33:           NA           NA       2014.5         <NA>
#>  34:           NA           NA           NA         <NA>
#>  35:           NA           NA           NA         <NA>
#>  36:           NA           NA           NA         <NA>
#>  37:           NA           NA           NA         <NA>
#>  38:           NA           NA           NA         <NA>
#>  39:           NA           NA           NA         <NA>
#>  40:           NA           NA           NA         <NA>
#>  41:           NA           NA           NA         <NA>
#>  42:           NA           NA           NA         <NA>
#>  43:           NA           NA           NA         <NA>
#>  44:           NA           NA           NA         <NA>
#>  45:           NA           NA           NA         <NA>
#>  46:           NA       2011.5           NA         <NA>
#>  47:           NA           NA           NA         <NA>
#>  48:           NA           NA           NA         <NA>
#>  49:           NA       2001.5           NA         <NA>
#>  50:           NA           NA           NA         <NA>
#>  51:           NA           NA           NA         <NA>
#>  52:           NA           NA           NA         <NA>
#>  53:           NA       2003.5           NA         <NA>
#>  54:       2008.5           NA           NA         <NA>
#>  55:           NA           NA           NA         <NA>
#>  56:           NA           NA           NA         <NA>
#>  57:           NA           NA           NA         <NA>
#>  58:           NA           NA           NA         <NA>
#>  59:           NA       2001.5           NA         <NA>
#>  60:           NA           NA           NA         <NA>
#>  61:           NA           NA       2007.5     lymphoma
#>  62:           NA           NA           NA         <NA>
#>  63:           NA           NA           NA         <NA>
#>  64:           NA           NA           NA         <NA>
#>  65:       2008.5           NA       2011.5         <NA>
#>  66:           NA           NA           NA         <NA>
#>  67:           NA           NA           NA         <NA>
#>  68:           NA           NA           NA     lymphoma
#>  69:           NA           NA           NA         <NA>
#>  70:           NA           NA           NA         <NA>
#>  71:           NA           NA           NA         <NA>
#>  72:           NA           NA           NA         <NA>
#>  73:           NA           NA           NA         <NA>
#>  74:           NA           NA           NA         <NA>
#>  75:           NA           NA           NA         <NA>
#>  76:       2001.5           NA           NA         <NA>
#>  77:           NA           NA           NA         <NA>
#>  78:           NA           NA           NA         <NA>
#>  79:           NA           NA           NA         <NA>
#>  80:           NA           NA           NA         <NA>
#>  81:           NA           NA           NA         <NA>
#>  82:           NA           NA           NA         <NA>
#>  83:           NA           NA           NA         <NA>
#>  84:           NA           NA           NA         <NA>
#>  85:           NA           NA           NA         <NA>
#>  86:           NA           NA           NA         <NA>
#>  87:           NA           NA           NA         <NA>
#>  88:       2009.5           NA           NA         <NA>
#>  89:       2006.5           NA           NA         <NA>
#>  90:           NA           NA           NA         <NA>
#>  91:           NA           NA           NA         <NA>
#>  92:           NA           NA           NA         <NA>
#>  93:           NA           NA           NA         <NA>
#>  94:       2009.5           NA           NA         <NA>
#>  95:           NA           NA           NA         <NA>
#>  96:           NA           NA           NA         <NA>
#>  97:           NA       2003.5           NA         <NA>
#>  98:           NA           NA           NA         <NA>
#>  99:           NA       2003.5           NA         <NA>
#> 100:           NA       2013.5           NA         <NA>
#>      p20008_i0_a2 p20008_i0_a3 p20008_i0_a4 p20001_i0_a0
#>             <num>        <num>        <num>       <char>
#>                  p20001_i0_a1             p20001_i0_a2 p20001_i0_a3
#>                        <char>                   <char>       <char>
#>   1:                     <NA>                     <NA>         <NA>
#>   2: non-melanoma skin cancer                     <NA>         <NA>
#>   3:                     <NA>                     <NA>         <NA>
#>   4:                     <NA>                     <NA>         <NA>
#>   5:                     <NA>                     <NA>         <NA>
#>   6:                 lymphoma                     <NA>         <NA>
#>   7:                     <NA>                     <NA>         <NA>
#>   8:           thyroid cancer                     <NA>         <NA>
#>   9:                     <NA>                     <NA>         <NA>
#>  10:                     <NA>                     <NA>         <NA>
#>  11:                     <NA>                     <NA>         <NA>
#>  12:                     <NA>                     <NA>         <NA>
#>  13:              lung cancer                     <NA>         <NA>
#>  14:                     <NA>                     <NA>         <NA>
#>  15:                     <NA>                     <NA>         <NA>
#>  16:                     <NA>                     <NA>         <NA>
#>  17:                     <NA>                     <NA>         <NA>
#>  18:                     <NA>                     <NA>         <NA>
#>  19:                     <NA>                     <NA>         <NA>
#>  20:                     <NA>                     <NA>         <NA>
#>  21:                     <NA>                     <NA>         <NA>
#>  22:                     <NA>                     <NA>         <NA>
#>  23:                     <NA>                     <NA>         <NA>
#>  24:                     <NA>                     <NA>         <NA>
#>  25:                     <NA>                     <NA>         <NA>
#>  26:                     <NA>                     <NA>         <NA>
#>  27:                     <NA>                     <NA>         <NA>
#>  28:                     <NA>                     <NA>         <NA>
#>  29:                     <NA>                     <NA>         <NA>
#>  30:                     <NA>                     <NA>         <NA>
#>  31:                     <NA>                     <NA>         <NA>
#>  32:                     <NA>                     <NA>         <NA>
#>  33:                     <NA>                     <NA>         <NA>
#>  34:                     <NA>                     <NA>         <NA>
#>  35:                     <NA>                     <NA>         <NA>
#>  36:                     <NA>                     <NA>         <NA>
#>  37:                     <NA>                     <NA>         <NA>
#>  38:                     <NA>                     <NA>         <NA>
#>  39:                     <NA>                     <NA>         <NA>
#>  40:                     <NA>                     <NA>         <NA>
#>  41:                     <NA>                     <NA>         <NA>
#>  42:                     <NA>                     <NA>         <NA>
#>  43:                     <NA>                     <NA>         <NA>
#>  44:                     <NA>                     <NA>         <NA>
#>  45:                     <NA>                     <NA>         <NA>
#>  46:                     <NA>                     <NA>         <NA>
#>  47:                     <NA>                     <NA>         <NA>
#>  48:                     <NA>                     <NA>         <NA>
#>  49:                     <NA>                     <NA>         <NA>
#>  50:                     <NA>                     <NA>         <NA>
#>  51:                     <NA>                     <NA>         <NA>
#>  52:                     <NA>                     <NA>         <NA>
#>  53:           bladder cancer                     <NA>         <NA>
#>  54:                     <NA>                     <NA>         <NA>
#>  55:                     <NA>                     <NA>         <NA>
#>  56:                     <NA>                     <NA>         <NA>
#>  57:                     <NA>                     <NA>         <NA>
#>  58:                     <NA>                     <NA>         <NA>
#>  59:                 lymphoma                     <NA>         <NA>
#>  60:                     <NA>                     <NA>         <NA>
#>  61:                     <NA>                     <NA>         <NA>
#>  62:                     <NA>                     <NA>         <NA>
#>  63:                     <NA>                     <NA>         <NA>
#>  64:                     <NA>                     <NA>         <NA>
#>  65:                     <NA>                     <NA>         <NA>
#>  66:                     <NA>                     <NA>         <NA>
#>  67:                     <NA>                     <NA>         <NA>
#>  68:                     <NA>                     <NA>         <NA>
#>  69:                     <NA>                     <NA>         <NA>
#>  70:                     <NA>                     <NA>         <NA>
#>  71:                     <NA>                     <NA>         <NA>
#>  72:                     <NA>                     <NA>         <NA>
#>  73:                     <NA>                     <NA>         <NA>
#>  74:                     <NA>                     <NA>         <NA>
#>  75:                     <NA>                     <NA>         <NA>
#>  76:                     <NA>                     <NA>         <NA>
#>  77:                     <NA>                     <NA>         <NA>
#>  78:                     <NA>                     <NA>         <NA>
#>  79:                     <NA> kidney/renal cell cancer         <NA>
#>  80:                     <NA>                     <NA>         <NA>
#>  81:                     <NA>                     <NA>         <NA>
#>  82:                     <NA>                     <NA>         <NA>
#>  83:                     <NA>                     <NA>         <NA>
#>  84:                     <NA>                     <NA>         <NA>
#>  85:                     <NA>                     <NA>         <NA>
#>  86:                     <NA>                     <NA>         <NA>
#>  87:                     <NA>                     <NA>         <NA>
#>  88:                     <NA>                     <NA>         <NA>
#>  89:                     <NA>                     <NA>         <NA>
#>  90:                     <NA>                     <NA>         <NA>
#>  91:                     <NA>                     <NA>         <NA>
#>  92:                     <NA>                     <NA>         <NA>
#>  93:                     <NA>                     <NA>         <NA>
#>  94:                     <NA>                     <NA>         <NA>
#>  95:                     <NA>                     <NA>         <NA>
#>  96:                     <NA>                     <NA>         <NA>
#>  97:                     <NA>                     <NA>         <NA>
#>  98:                     <NA>                     <NA>         <NA>
#>  99:                     <NA>                     <NA>         <NA>
#> 100:                     <NA>                     <NA>         <NA>
#>                  p20001_i0_a1             p20001_i0_a2 p20001_i0_a3
#>                        <char>                   <char>       <char>
#>      p20001_i0_a4 p20006_i0_a0 p20006_i0_a1 p20006_i0_a2 p20006_i0_a3
#>            <char>        <num>        <num>        <num>        <num>
#>   1:         <NA>           NA           NA           NA           NA
#>   2:         <NA>           NA       2014.5           NA           NA
#>   3:         <NA>           NA           NA           NA           NA
#>   4:         <NA>           NA           NA           NA           NA
#>   5:         <NA>           NA           NA           NA           NA
#>   6:         <NA>           NA       2012.5           NA           NA
#>   7:         <NA>           NA           NA           NA           NA
#>   8:         <NA>           NA       2000.5           NA           NA
#>   9:         <NA>           NA           NA           NA           NA
#>  10:         <NA>           NA           NA           NA           NA
#>  11:         <NA>           NA           NA           NA           NA
#>  12:         <NA>           NA           NA           NA           NA
#>  13:         <NA>           NA       2007.5           NA           NA
#>  14:         <NA>           NA           NA           NA           NA
#>  15:         <NA>           NA           NA           NA           NA
#>  16:         <NA>           NA           NA           NA           NA
#>  17:         <NA>           NA           NA           NA           NA
#>  18:         <NA>           NA           NA           NA           NA
#>  19:         <NA>           NA           NA           NA           NA
#>  20:         <NA>           NA           NA           NA           NA
#>  21:         <NA>           NA           NA           NA           NA
#>  22:         <NA>           NA           NA           NA           NA
#>  23:         <NA>           NA           NA           NA           NA
#>  24:         <NA>           NA           NA           NA           NA
#>  25:         <NA>           NA           NA           NA           NA
#>  26:         <NA>           NA           NA           NA           NA
#>  27:         <NA>           NA           NA           NA           NA
#>  28:         <NA>           NA           NA           NA           NA
#>  29:         <NA>           NA           NA           NA           NA
#>  30:         <NA>           NA           NA           NA           NA
#>  31:         <NA>           NA           NA           NA           NA
#>  32:         <NA>           NA           NA           NA           NA
#>  33:         <NA>           NA           NA           NA           NA
#>  34:         <NA>           NA           NA           NA           NA
#>  35:         <NA>           NA           NA           NA           NA
#>  36:         <NA>           NA           NA           NA           NA
#>  37:         <NA>           NA           NA           NA           NA
#>  38:         <NA>           NA           NA           NA           NA
#>  39:         <NA>           NA           NA           NA           NA
#>  40:         <NA>           NA           NA           NA           NA
#>  41:         <NA>           NA           NA           NA           NA
#>  42:         <NA>           NA           NA           NA           NA
#>  43:         <NA>           NA           NA           NA           NA
#>  44:         <NA>           NA           NA           NA           NA
#>  45:         <NA>           NA           NA           NA           NA
#>  46:         <NA>           NA           NA           NA           NA
#>  47:         <NA>           NA           NA           NA           NA
#>  48:         <NA>           NA           NA           NA           NA
#>  49:         <NA>           NA           NA           NA           NA
#>  50:         <NA>           NA           NA           NA           NA
#>  51:         <NA>           NA           NA           NA           NA
#>  52:         <NA>           NA           NA           NA           NA
#>  53:         <NA>           NA       2006.5           NA           NA
#>  54:         <NA>           NA           NA           NA           NA
#>  55:         <NA>           NA           NA           NA           NA
#>  56:         <NA>           NA           NA           NA           NA
#>  57:         <NA>           NA           NA           NA           NA
#>  58:         <NA>           NA           NA           NA           NA
#>  59:         <NA>           NA       2009.5           NA           NA
#>  60:         <NA>           NA           NA           NA           NA
#>  61:         <NA>       2009.5           NA           NA           NA
#>  62:         <NA>           NA           NA           NA           NA
#>  63:         <NA>           NA           NA           NA           NA
#>  64:         <NA>           NA           NA           NA           NA
#>  65:         <NA>           NA           NA           NA           NA
#>  66:         <NA>           NA           NA           NA           NA
#>  67:         <NA>           NA           NA           NA           NA
#>  68:         <NA>       2012.5           NA           NA           NA
#>  69:         <NA>           NA           NA           NA           NA
#>  70:         <NA>           NA           NA           NA           NA
#>  71:         <NA>           NA           NA           NA           NA
#>  72:         <NA>           NA           NA           NA           NA
#>  73:         <NA>           NA           NA           NA           NA
#>  74:         <NA>           NA           NA           NA           NA
#>  75:         <NA>           NA           NA           NA           NA
#>  76:         <NA>           NA           NA           NA           NA
#>  77:         <NA>           NA           NA           NA           NA
#>  78:         <NA>           NA           NA           NA           NA
#>  79:         <NA>           NA           NA       2014.5           NA
#>  80:         <NA>           NA           NA           NA           NA
#>  81:         <NA>           NA           NA           NA           NA
#>  82:         <NA>           NA           NA           NA           NA
#>  83:         <NA>           NA           NA           NA           NA
#>  84:         <NA>           NA           NA           NA           NA
#>  85:         <NA>           NA           NA           NA           NA
#>  86:         <NA>           NA           NA           NA           NA
#>  87:         <NA>           NA           NA           NA           NA
#>  88:         <NA>           NA           NA           NA           NA
#>  89:         <NA>           NA           NA           NA           NA
#>  90:         <NA>           NA           NA           NA           NA
#>  91:         <NA>           NA           NA           NA           NA
#>  92:         <NA>           NA           NA           NA           NA
#>  93:         <NA>           NA           NA           NA           NA
#>  94:         <NA>           NA           NA           NA           NA
#>  95:         <NA>           NA           NA           NA           NA
#>  96:         <NA>           NA           NA           NA           NA
#>  97:         <NA>           NA           NA           NA           NA
#>  98:         <NA>           NA           NA           NA           NA
#>  99:         <NA>           NA           NA           NA           NA
#> 100:         <NA>           NA           NA           NA           NA
#>      p20001_i0_a4 p20006_i0_a0 p20006_i0_a1 p20006_i0_a2 p20006_i0_a3
#>            <char>        <num>        <num>        <num>        <num>
#>      p20006_i0_a4                    p41270  p41280_a0  p41280_a1  p41280_a2
#>             <num>                    <char>     <char>     <char>     <char>
#>   1:           NA                      <NA>       <NA>       <NA>       <NA>
#>   2:           NA                      <NA>       <NA>       <NA>       <NA>
#>   3:           NA                      <NA>       <NA>       <NA>       <NA>
#>   4:           NA                   ["K57"] 2007-07-25       <NA>       <NA>
#>   5:           NA                      <NA>       <NA>       <NA>       <NA>
#>   6:           NA                   ["C44"] 2013-01-31       <NA>       <NA>
#>   7:           NA ["F32","I25","G35","E11"] 2020-10-25 2016-10-31 2021-12-31
#>   8:           NA                      <NA>       <NA>       <NA>       <NA>
#>   9:           NA                      <NA>       <NA>       <NA>       <NA>
#>  10:           NA                   ["I48"] 2018-04-26       <NA>       <NA>
#>  11:           NA ["G35","I48","E11","L20"] 2011-06-06 2013-12-14 2022-12-28
#>  12:           NA                   ["K57"] 2021-04-07       <NA>       <NA>
#>  13:           NA                      <NA>       <NA>       <NA>       <NA>
#>  14:           NA                      <NA>       <NA>       <NA>       <NA>
#>  15:           NA                      <NA>       <NA>       <NA>       <NA>
#>  16:           NA                      <NA>       <NA>       <NA>       <NA>
#>  17:           NA                   ["I10"] 2006-10-11       <NA>       <NA>
#>  18:           NA                      <NA>       <NA>       <NA>       <NA>
#>  19:           NA       ["C44","M79","E11"] 2013-12-09 2017-02-09 2017-07-21
#>  20:           NA       ["C44","J45","I25"] 2011-09-19 2007-04-19 2006-01-05
#>  21:           NA                      <NA>       <NA>       <NA>       <NA>
#>  22:           NA                      <NA>       <NA>       <NA>       <NA>
#>  23:           NA                      <NA>       <NA>       <NA>       <NA>
#>  24:           NA                      <NA>       <NA>       <NA>       <NA>
#>  25:           NA                      <NA>       <NA>       <NA>       <NA>
#>  26:           NA                      <NA>       <NA>       <NA>       <NA>
#>  27:           NA             ["C44","E11"] 2007-05-12 2000-03-14       <NA>
#>  28:           NA                      <NA>       <NA>       <NA>       <NA>
#>  29:           NA             ["I10","F32"] 2005-10-28 2001-05-07       <NA>
#>  30:           NA                      <NA>       <NA>       <NA>       <NA>
#>  31:           NA                      <NA>       <NA>       <NA>       <NA>
#>  32:           NA                      <NA>       <NA>       <NA>       <NA>
#>  33:           NA                      <NA>       <NA>       <NA>       <NA>
#>  34:           NA                   ["J45"] 2004-02-22       <NA>       <NA>
#>  35:           NA                      <NA>       <NA>       <NA>       <NA>
#>  36:           NA                   ["G35"] 2022-02-27       <NA>       <NA>
#>  37:           NA                      <NA>       <NA>       <NA>       <NA>
#>  38:           NA                      <NA>       <NA>       <NA>       <NA>
#>  39:           NA                      <NA>       <NA>       <NA>       <NA>
#>  40:           NA                      <NA>       <NA>       <NA>       <NA>
#>  41:           NA                      <NA>       <NA>       <NA>       <NA>
#>  42:           NA                      <NA>       <NA>       <NA>       <NA>
#>  43:           NA                      <NA>       <NA>       <NA>       <NA>
#>  44:           NA       ["N18","I48","E11"] 2018-02-15 2012-08-20 2020-02-08
#>  45:           NA ["E11","J45","L20","G35"] 2010-08-23 2008-02-24 2006-06-16
#>  46:           NA                      <NA>       <NA>       <NA>       <NA>
#>  47:           NA                      <NA>       <NA>       <NA>       <NA>
#>  48:           NA                      <NA>       <NA>       <NA>       <NA>
#>  49:           NA                      <NA>       <NA>       <NA>       <NA>
#>  50:           NA             ["E11","I10"] 2001-06-07 2017-02-10       <NA>
#>  51:           NA                      <NA>       <NA>       <NA>       <NA>
#>  52:           NA                      <NA>       <NA>       <NA>       <NA>
#>  53:           NA                      <NA>       <NA>       <NA>       <NA>
#>  54:           NA                      <NA>       <NA>       <NA>       <NA>
#>  55:           NA             ["M79","I48"] 2004-10-31 2013-05-14       <NA>
#>  56:           NA                      <NA>       <NA>       <NA>       <NA>
#>  57:           NA                      <NA>       <NA>       <NA>       <NA>
#>  58:           NA                      <NA>       <NA>       <NA>       <NA>
#>  59:           NA                   ["C44"] 2013-07-08       <NA>       <NA>
#>  60:           NA ["L20","K57","I25","M79"] 2008-03-22 2012-02-20 2016-07-05
#>  61:           NA ["N18","E11","M79","I10"] 2018-06-02 2011-10-29 2018-05-09
#>  62:           NA                      <NA>       <NA>       <NA>       <NA>
#>  63:           NA       ["I25","G35","L20"] 2016-10-18 2003-07-08 2021-03-19
#>  64:           NA                      <NA>       <NA>       <NA>       <NA>
#>  65:           NA                      <NA>       <NA>       <NA>       <NA>
#>  66:           NA                      <NA>       <NA>       <NA>       <NA>
#>  67:           NA                      <NA>       <NA>       <NA>       <NA>
#>  68:           NA                      <NA>       <NA>       <NA>       <NA>
#>  69:           NA                      <NA>       <NA>       <NA>       <NA>
#>  70:           NA                   ["K57"] 2021-05-12       <NA>       <NA>
#>  71:           NA                   ["K57"] 2014-06-14       <NA>       <NA>
#>  72:           NA                      <NA>       <NA>       <NA>       <NA>
#>  73:           NA             ["M79","F32"] 2000-04-13 2014-06-06       <NA>
#>  74:           NA                      <NA>       <NA>       <NA>       <NA>
#>  75:           NA                      <NA>       <NA>       <NA>       <NA>
#>  76:           NA                      <NA>       <NA>       <NA>       <NA>
#>  77:           NA                   ["I10"] 2016-11-12       <NA>       <NA>
#>  78:           NA                      <NA>       <NA>       <NA>       <NA>
#>  79:           NA                      <NA>       <NA>       <NA>       <NA>
#>  80:           NA                      <NA>       <NA>       <NA>       <NA>
#>  81:           NA                   ["E11"] 2015-04-21       <NA>       <NA>
#>  82:           NA ["I10","N18","M79","C44"] 2017-09-11 2013-01-18 2012-05-01
#>  83:           NA             ["C44","I25"] 2019-03-01 2004-10-10       <NA>
#>  84:           NA ["N18","I25","F32","E11"] 2002-02-28 2000-02-06 2009-08-25
#>  85:           NA                      <NA>       <NA>       <NA>       <NA>
#>  86:           NA                      <NA>       <NA>       <NA>       <NA>
#>  87:           NA       ["L20","M79","C44"] 2000-08-31 2020-09-14 2020-07-20
#>  88:           NA                      <NA>       <NA>       <NA>       <NA>
#>  89:           NA                      <NA>       <NA>       <NA>       <NA>
#>  90:           NA                   ["C44"] 2007-12-08       <NA>       <NA>
#>  91:           NA                   ["C44"] 2020-11-11       <NA>       <NA>
#>  92:           NA                   ["L20"] 2021-05-12       <NA>       <NA>
#>  93:           NA       ["I10","L20","K57"] 2011-11-10 2019-06-04 2010-01-09
#>  94:           NA                      <NA>       <NA>       <NA>       <NA>
#>  95:           NA       ["M79","K57","I48"] 2019-03-06 2016-02-19 2021-01-15
#>  96:           NA       ["M79","K57","L20"] 2007-11-21 2019-07-13 2010-05-31
#>  97:           NA       ["M79","I25","I48"] 2020-06-19 2018-08-03 2010-11-14
#>  98:           NA                      <NA>       <NA>       <NA>       <NA>
#>  99:           NA ["J45","E11","G35","I48"] 2007-12-25 2006-08-16 2012-09-24
#> 100:           NA                      <NA>       <NA>       <NA>       <NA>
#>      p20006_i0_a4                    p41270  p41280_a0  p41280_a1  p41280_a2
#>             <num>                    <char>     <char>     <char>     <char>
#>       p41280_a3 p41280_a4 p41280_a5 p41280_a6 p41280_a7 p41280_a8 p40006_i0
#>          <char>    <char>    <char>    <char>    <char>    <char>    <char>
#>   1:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   2:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   3:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   4:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   5:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   6:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   7: 2002-05-17      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   8:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>   9:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C34
#>  10:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  11: 2016-04-21      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  12:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  13:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  14:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  15:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  16:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  17:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  18:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  19:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  20:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  21:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  22:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  23:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  24:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  25:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  26:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  27:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  28:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  29:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C43
#>  30:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  31:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  32:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  33:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  34:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  35:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  36:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  37:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C34
#>  38:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  39:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  40:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  41:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  42:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  43:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  44:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  45: 2020-08-24      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  46:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  47:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  48:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  49:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  50:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  51:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  52:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  53:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  54:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  55:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C64
#>  56:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  57:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  58:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  59:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  60: 2013-05-23      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  61: 2016-05-04      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  62:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  63:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  64:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  65:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  66:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C61
#>  67:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  68:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  69:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  70:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  71:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>       C20
#>  72:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  73:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  74:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  75:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  76:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  77:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  78:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  79:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  80:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  81:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  82: 2001-08-22      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  83:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  84: 2005-07-10      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  85:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  86:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  87:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  88:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  89:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  90:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  91:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  92:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  93:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  94:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  95:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  96:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  97:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  98:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>  99: 2021-06-02      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#> 100:       <NA>      <NA>      <NA>      <NA>      <NA>      <NA>      <NA>
#>       p41280_a3 p41280_a4 p41280_a5 p41280_a6 p41280_a7 p41280_a8 p40006_i0
#>          <char>    <char>    <char>    <char>    <char>    <char>    <char>
#>      p40011_i0 p40012_i0  p40005_i0 p40006_i1 p40011_i1 p40012_i1  p40005_i1
#>          <int>     <int>     <char>    <char>     <int>     <int>     <char>
#>   1:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   2:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   3:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   4:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   5:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   6:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   7:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   8:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>   9:      8520         6 2014-10-21      <NA>        NA        NA       <NA>
#>  10:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  11:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  12:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  13:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  14:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  15:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  16:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  17:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  18:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  19:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  20:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  21:        NA        NA       <NA>       C18      8130         3 2006-12-19
#>  22:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  23:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  24:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  25:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  26:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  27:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  28:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  29:      8010         3 2009-02-10      <NA>        NA        NA       <NA>
#>  30:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  31:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  32:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  33:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  34:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  35:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  36:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  37:      8000         3 1994-09-27      <NA>        NA        NA       <NA>
#>  38:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  39:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  40:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  41:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  42:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  43:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  44:        NA        NA       <NA>       C34      8090         1 2001-03-26
#>  45:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  46:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  47:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  48:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  49:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  50:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  51:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  52:        NA        NA       <NA>       C43      8090         3 1990-02-27
#>  53:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  54:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  55:      8010         9 2019-03-22      <NA>        NA        NA       <NA>
#>  56:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  57:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  58:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  59:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  60:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  61:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  62:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  63:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  64:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  65:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  66:      8140         0 2005-10-09      <NA>        NA        NA       <NA>
#>  67:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  68:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  69:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  70:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  71:      8090         2 1990-03-22      <NA>        NA        NA       <NA>
#>  72:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  73:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  74:        NA        NA       <NA>       C18      8743         2 2008-07-11
#>  75:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  76:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  77:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  78:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  79:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  80:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  81:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  82:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  83:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  84:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  85:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  86:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  87:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  88:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  89:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  90:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  91:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  92:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  93:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  94:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  95:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  96:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  97:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  98:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>  99:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#> 100:        NA        NA       <NA>      <NA>        NA        NA       <NA>
#>      p40011_i0 p40012_i0  p40005_i0 p40006_i1 p40011_i1 p40012_i1  p40005_i1
#>          <int>     <int>     <char>    <char>     <int>     <int>     <char>
#>      p40006_i2 p40011_i2 p40012_i2  p40005_i2 p40001_i0 p40002_i0_a0
#>         <char>     <int>     <int>     <char>    <char>       <char>
#>   1:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   2:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   3:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   4:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   5:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   6:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   7:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   8:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>   9:      <NA>        NA        NA       <NA>     C50.9        C25.9
#>  10:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  11:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  12:      <NA>        NA        NA       <NA>     I25.9         <NA>
#>  13:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  14:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  15:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  16:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  17:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  18:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  19:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  20:      <NA>        NA        NA       <NA>     C50.9         <NA>
#>  21:      <NA>        NA        NA       <NA>     E11.9         <NA>
#>  22:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  23:      <NA>        NA        NA       <NA>     C34.9         <NA>
#>  24:      <NA>        NA        NA       <NA>       C61          C61
#>  25:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  26:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  27:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  28:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  29:       C43      8500         2 2011-07-25      <NA>         <NA>
#>  30:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  31:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  32:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  33:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  34:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  35:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  36:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  37:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  38:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  39:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  40:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  41:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  42:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  43:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  44:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  45:      <NA>        NA        NA       <NA>       I64          I64
#>  46:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  47:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  48:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  49:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  50:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  51:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  52:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  53:      <NA>        NA        NA       <NA>     I48.0         <NA>
#>  54:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  55:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  56:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  57:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  58:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  59:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  60:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  61:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  62:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  63:      <NA>        NA        NA       <NA>     C18.9         <NA>
#>  64:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  65:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  66:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  67:      <NA>        NA        NA       <NA>     I25.9         <NA>
#>  68:      <NA>        NA        NA       <NA>     I21.9         <NA>
#>  69:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  70:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  71:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  72:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  73:      <NA>        NA        NA       <NA>     C18.9         <NA>
#>  74:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  75:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  76:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  77:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  78:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  79:      <NA>        NA        NA       <NA>       C61         <NA>
#>  80:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  81:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  82:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  83:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  84:      <NA>        NA        NA       <NA>     I48.0         <NA>
#>  85:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  86:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  87:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  88:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  89:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  90:       C20      8010         9 2009-09-24      <NA>         <NA>
#>  91:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  92:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  93:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  94:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  95:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  96:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  97:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  98:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>  99:      <NA>        NA        NA       <NA>     I21.9         <NA>
#> 100:      <NA>        NA        NA       <NA>      <NA>         <NA>
#>      p40006_i2 p40011_i2 p40012_i2  p40005_i2 p40001_i0 p40002_i0_a0
#>         <char>     <int>     <int>     <char>    <char>       <char>
#>      p40002_i0_a1 p40002_i0_a2  p40000_i0    p131742   grs_bmi    grs_raw
#>            <char>       <char>     <char>     <char>     <num>      <num>
#>   1:         <NA>         <NA>       <NA>       <NA>  0.021609   4.119301
#>   2:         <NA>         <NA>       <NA>       <NA>  2.847126  -1.068375
#>   3:         <NA>         <NA>       <NA>       <NA>  0.676117  -1.709500
#>   4:         <NA>         <NA>       <NA>       <NA> -0.600684   3.042186
#>   5:         <NA>         <NA>       <NA>       <NA> -0.340030   3.501643
#>   6:         <NA>         <NA>       <NA>       <NA>  7.060673  -3.980057
#>   7:         <NA>         <NA>       <NA>       <NA> -0.883849   6.245520
#>   8:         <NA>         <NA>       <NA>       <NA>  2.417561  -5.542793
#>   9:         <NA>         <NA> 2014-04-16       <NA>  4.028432   5.099845
#>  10:         <NA>         <NA>       <NA>       <NA> -1.852965   1.773366
#>  11:         <NA>         <NA>       <NA>       <NA> -0.095659   5.659451
#>  12:         <NA>          I64 2014-09-16       <NA>  1.857489   3.542727
#>  13:         <NA>         <NA>       <NA>       <NA>  3.857785   6.716829
#>  14:         <NA>         <NA>       <NA>       <NA>  3.662161   1.536181
#>  15:         <NA>         <NA>       <NA>       <NA>  0.653029   4.532348
#>  16:         <NA>         <NA>       <NA>       <NA>  1.730675  -2.326168
#>  17:         <NA>         <NA>       <NA>       <NA>  1.306783   1.161314
#>  18:         <NA>         <NA>       <NA>       <NA>  1.482341   6.471390
#>  19:         <NA>         <NA>       <NA>       <NA>  0.347114   4.018216
#>  20:         <NA>         <NA> 2012-01-10       <NA> -3.823814  -3.674077
#>  21:        C50.9         <NA> 2014-05-17       <NA>  0.138854  -0.562140
#>  22:         <NA>         <NA>       <NA>       <NA>  1.540169   1.987958
#>  23:         <NA>         <NA> 2018-02-04       <NA>  1.773638  -1.501415
#>  24:        C34.9         <NA> 2014-08-13       <NA>  0.745601  -1.156863
#>  25:         <NA>         <NA>       <NA>       <NA>  1.842031   7.467715
#>  26:         <NA>         <NA>       <NA>       <NA>  0.205781  -2.218112
#>  27:         <NA>         <NA>       <NA>       <NA> -3.504630   2.302857
#>  28:         <NA>         <NA>       <NA>       <NA>  0.351665   4.491370
#>  29:         <NA>         <NA>       <NA>       <NA>  0.494700   2.264275
#>  30:         <NA>         <NA>       <NA>       <NA> -5.123789   0.917649
#>  31:         <NA>         <NA>       <NA>       <NA>  3.100736   3.872237
#>  32:         <NA>         <NA>       <NA>       <NA> -1.942790  -0.156689
#>  33:         <NA>         <NA>       <NA>       <NA>  2.351239   7.068708
#>  34:         <NA>         <NA>       <NA>       <NA>  1.425759  -0.503581
#>  35:         <NA>         <NA>       <NA>       <NA> -1.608448  -2.527301
#>  36:         <NA>         <NA>       <NA>       <NA>  1.424656 -10.117574
#>  37:         <NA>         <NA>       <NA>       <NA>  4.009477   2.506912
#>  38:         <NA>         <NA>       <NA>       <NA>  1.279449  -1.996846
#>  39:         <NA>         <NA>       <NA>       <NA>  0.099330   1.722641
#>  40:         <NA>         <NA>       <NA>       <NA>  0.919699  -3.923742
#>  41:         <NA>         <NA>       <NA>       <NA>  0.029150   4.941069
#>  42:         <NA>         <NA>       <NA>       <NA> -3.142930   0.747979
#>  43:         <NA>         <NA>       <NA>       <NA>  1.222075   5.436972
#>  44:         <NA>         <NA>       <NA>       <NA> -1.490589   3.340988
#>  45:         <NA>         <NA> 2022-06-06       <NA> -3.122234   4.821942
#>  46:         <NA>         <NA>       <NA> 2006-03-02 -4.040376   3.492777
#>  47:         <NA>         <NA>       <NA>       <NA> -0.126759   2.278545
#>  48:         <NA>         <NA>       <NA>       <NA>  2.405921   6.848048
#>  49:         <NA>         <NA>       <NA>       <NA> -2.982039   0.023685
#>  50:         <NA>         <NA>       <NA>       <NA> -1.021113  -3.002445
#>  51:         <NA>         <NA>       <NA>       <NA>  1.939797   8.618853
#>  52:         <NA>         <NA>       <NA>       <NA> -2.399704   0.557300
#>  53:        C25.9         <NA> 2015-01-28       <NA>  4.581159   4.876335
#>  54:         <NA>         <NA>       <NA>       <NA> -1.213205   0.467835
#>  55:         <NA>         <NA>       <NA> 2005-10-23 -0.350983   2.443917
#>  56:         <NA>         <NA>       <NA>       <NA>  3.837411   3.382863
#>  57:         <NA>         <NA>       <NA>       <NA>  2.174932  -5.054569
#>  58:         <NA>         <NA>       <NA>       <NA>  2.958808   2.698314
#>  59:         <NA>         <NA>       <NA>       <NA> -2.054506  -1.762573
#>  60:         <NA>         <NA>       <NA>       <NA>  3.478392   8.202791
#>  61:         <NA>         <NA>       <NA>       <NA>  0.800876   3.924331
#>  62:         <NA>         <NA>       <NA>       <NA>  2.027209   5.816133
#>  63:         <NA>         <NA> 2016-07-29 2005-07-05  0.884115   0.568528
#>  64:         <NA>         <NA>       <NA>       <NA>  0.375346   1.832600
#>  65:         <NA>         <NA>       <NA> 2003-06-10  6.108202   2.702922
#>  66:         <NA>         <NA>       <NA>       <NA> -2.535697   2.868933
#>  67:        C18.9         <NA> 2016-07-26       <NA>  4.392914  -1.813727
#>  68:         <NA>         <NA> 2023-12-04       <NA> -0.022262   0.744138
#>  69:         <NA>         <NA>       <NA>       <NA> -1.025169  -2.747311
#>  70:         <NA>         <NA>       <NA>       <NA>  2.550825   6.678603
#>  71:         <NA>         <NA>       <NA>       <NA> -0.211277   0.747080
#>  72:         <NA>         <NA>       <NA>       <NA>  3.101550   4.005463
#>  73:         <NA>         <NA> 2019-09-29       <NA> -1.575432   1.028322
#>  74:         <NA>         <NA>       <NA>       <NA> -1.859912   4.232483
#>  75:         <NA>         <NA>       <NA>       <NA>  4.002564   2.818326
#>  76:         <NA>         <NA>       <NA>       <NA>  2.672228   5.202175
#>  77:         <NA>         <NA>       <NA>       <NA>  0.400722   4.724100
#>  78:         <NA>         <NA>       <NA>       <NA>  2.079422   3.236861
#>  79:         <NA>         <NA> 2014-12-29 2012-06-02  0.956295   0.142627
#>  80:         <NA>         <NA>       <NA>       <NA>  1.012196  -0.017678
#>  81:         <NA>         <NA>       <NA>       <NA> -0.398647   3.505991
#>  82:         <NA>         <NA>       <NA>       <NA>  1.494782  -1.251276
#>  83:         <NA>         <NA>       <NA>       <NA>  0.520495   5.597912
#>  84:         <NA>         <NA> 2019-10-03       <NA>  4.011875   3.742728
#>  85:         <NA>         <NA>       <NA>       <NA> -3.389348   3.268896
#>  86:         <NA>         <NA>       <NA>       <NA>  2.472043   1.789279
#>  87:         <NA>         <NA>       <NA>       <NA> -0.576458   4.936015
#>  88:         <NA>         <NA>       <NA>       <NA> -0.545487   2.625123
#>  89:         <NA>         <NA>       <NA>       <NA>  0.694612   1.051580
#>  90:         <NA>         <NA>       <NA>       <NA>  4.295643   0.397911
#>  91:         <NA>         <NA>       <NA>       <NA> -2.742106   1.124167
#>  92:         <NA>         <NA>       <NA>       <NA> -1.449225   4.667456
#>  93:         <NA>         <NA>       <NA>       <NA>  0.266988   2.278901
#>  94:         <NA>         <NA>       <NA>       <NA>  1.251750  -0.170729
#>  95:         <NA>         <NA>       <NA>       <NA>  1.303593   0.768698
#>  96:         <NA>         <NA>       <NA>       <NA>  5.741759  -6.496860
#>  97:         <NA>         <NA>       <NA>       <NA>  1.384529   2.509193
#>  98:         <NA>         <NA>       <NA>       <NA>  0.647035   4.948357
#>  99:         <NA>         <NA> 2015-03-10       <NA>  1.268670  -2.438080
#> 100:         <NA>         <NA>       <NA>       <NA> -1.427677   1.876287
#>      p40002_i0_a1 p40002_i0_a2  p40000_i0    p131742   grs_bmi    grs_raw
#>            <char>       <char>     <char>     <char>     <num>      <num>
#>      grs_finngen messy_allna messy_empty messy_label htn_hes htn_hes_date
#>            <num>      <char>      <char>      <char>  <lgcl>       <IDat>
#>   1:   -0.463630        <NA>                    <NA>   FALSE         <NA>
#>   2:   -1.009118        <NA>        <NA>        <NA>   FALSE         <NA>
#>   3:    0.568112        <NA>        <NA>        <NA>   FALSE         <NA>
#>   4:   -0.926223        <NA>        <NA>        <NA>   FALSE         <NA>
#>   5:    0.270758        <NA>                    <NA>   FALSE         <NA>
#>   6:    2.791891        <NA>        <NA>        <NA>   FALSE         <NA>
#>   7:   -2.652631        <NA>        <NA>        <NA>   FALSE         <NA>
#>   8:   -0.802261        <NA>        <NA>        <NA>   FALSE         <NA>
#>   9:   -0.363472        <NA>        <NA>         999   FALSE         <NA>
#>  10:    2.656164        <NA>        <NA>        <NA>   FALSE         <NA>
#>  11:    2.000984        <NA>                    <NA>   FALSE         <NA>
#>  12:    0.305794        <NA>                 unknown   FALSE         <NA>
#>  13:   -1.799184        <NA>        <NA>     unknown   FALSE         <NA>
#>  14:    0.905366        <NA>        <NA>        <NA>   FALSE         <NA>
#>  15:    0.594078        <NA>        <NA>           .   FALSE         <NA>
#>  16:    1.313204        <NA>                     999   FALSE         <NA>
#>  17:    0.414140        <NA>        <NA>     unknown    TRUE   2006-10-11
#>  18:   -2.115044        <NA>                 unknown   FALSE         <NA>
#>  19:   -0.107411        <NA>        <NA>        <NA>   FALSE         <NA>
#>  20:    3.113082        <NA>        <NA>         999   FALSE         <NA>
#>  21:   -2.597347        <NA>        <NA>         N/A   FALSE         <NA>
#>  22:    0.682216        <NA>                    <NA>   FALSE         <NA>
#>  23:    3.267717        <NA>        <NA>        <NA>   FALSE         <NA>
#>  24:   -0.405814        <NA>        <NA>         999   FALSE         <NA>
#>  25:    1.318932        <NA>                    <NA>   FALSE         <NA>
#>  26:   -0.455031        <NA>                 unknown   FALSE         <NA>
#>  27:    1.149077        <NA>                    <NA>   FALSE         <NA>
#>  28:   -1.989588        <NA>                    <NA>   FALSE         <NA>
#>  29:   -0.708027        <NA>        <NA>        #N/A    TRUE   2005-10-28
#>  30:    2.334323        <NA>        <NA>        <NA>   FALSE         <NA>
#>  31:    4.526089        <NA>                    <NA>   FALSE         <NA>
#>  32:   -0.355460        <NA>                    <NA>   FALSE         <NA>
#>  33:    1.084070        <NA>        <NA>        <NA>   FALSE         <NA>
#>  34:    2.594823        <NA>        <NA>        <NA>   FALSE         <NA>
#>  35:    0.006402        <NA>                     N/A   FALSE         <NA>
#>  36:    0.672020        <NA>                    <NA>   FALSE         <NA>
#>  37:    1.772247        <NA>        <NA>        <NA>   FALSE         <NA>
#>  38:   -3.879410        <NA>                    <NA>   FALSE         <NA>
#>  39:    1.539012        <NA>                       .   FALSE         <NA>
#>  40:   -1.155076        <NA>        <NA>        <NA>   FALSE         <NA>
#>  41:    0.605702        <NA>                    <NA>   FALSE         <NA>
#>  42:   -0.169956        <NA>        <NA>          -1   FALSE         <NA>
#>  43:    0.272292        <NA>        <NA>        NULL   FALSE         <NA>
#>  44:    2.068850        <NA>        <NA>        <NA>   FALSE         <NA>
#>  45:    0.989606        <NA>        <NA>        <NA>   FALSE         <NA>
#>  46:   -0.512391        <NA>        <NA>        <NA>   FALSE         <NA>
#>  47:    0.615645        <NA>                    NULL   FALSE         <NA>
#>  48:    2.025145        <NA>                    <NA>   FALSE         <NA>
#>  49:    1.361591        <NA>                      -1   FALSE         <NA>
#>  50:   -2.213414        <NA>                    <NA>    TRUE   2017-02-10
#>  51:   -4.909140        <NA>                    <NA>   FALSE         <NA>
#>  52:    1.092574        <NA>        <NA>        <NA>   FALSE         <NA>
#>  53:   -0.246553        <NA>                    #N/A   FALSE         <NA>
#>  54:    1.139080        <NA>                     999   FALSE         <NA>
#>  55:    0.974756        <NA>        <NA>          -1   FALSE         <NA>
#>  56:   -0.430027        <NA>                    <NA>   FALSE         <NA>
#>  57:    1.081591        <NA>        <NA>        #N/A   FALSE         <NA>
#>  58:    1.448629        <NA>        <NA>        <NA>   FALSE         <NA>
#>  59:    2.145363        <NA>                    <NA>   FALSE         <NA>
#>  60:    0.590018        <NA>        <NA>           .   FALSE         <NA>
#>  61:   -1.164018        <NA>                     N/A    TRUE   2016-05-04
#>  62:    0.052337        <NA>                     999   FALSE         <NA>
#>  63:   -1.816670        <NA>        <NA>     unknown   FALSE         <NA>
#>  64:    0.657542        <NA>        <NA>         N/A   FALSE         <NA>
#>  65:   -2.170130        <NA>        <NA>        <NA>   FALSE         <NA>
#>  66:    4.217090        <NA>                      -1   FALSE         <NA>
#>  67:   -2.970318        <NA>                    <NA>   FALSE         <NA>
#>  68:    0.190296        <NA>        <NA>     unknown   FALSE         <NA>
#>  69:    4.053520        <NA>                     N/A   FALSE         <NA>
#>  70:   -1.547943        <NA>                    <NA>   FALSE         <NA>
#>  71:   -1.117983        <NA>                    <NA>   FALSE         <NA>
#>  72:   -3.292374        <NA>        <NA>          -1   FALSE         <NA>
#>  73:   -2.325049        <NA>                       .   FALSE         <NA>
#>  74:   -1.470725        <NA>        <NA>        <NA>   FALSE         <NA>
#>  75:   -2.445188        <NA>                       .   FALSE         <NA>
#>  76:    1.087213        <NA>        <NA>        <NA>   FALSE         <NA>
#>  77:    3.060571        <NA>                    <NA>    TRUE   2016-11-12
#>  78:   -1.128299        <NA>                    <NA>   FALSE         <NA>
#>  79:   -1.620076        <NA>        <NA>        #N/A   FALSE         <NA>
#>  80:    2.514598        <NA>                     N/A   FALSE         <NA>
#>  81:   -2.236809        <NA>                    <NA>   FALSE         <NA>
#>  82:    1.037811        <NA>                    <NA>    TRUE   2017-09-11
#>  83:    1.799680        <NA>        <NA>        <NA>   FALSE         <NA>
#>  84:    4.106166        <NA>        <NA>        NULL   FALSE         <NA>
#>  85:    1.252130        <NA>        <NA>        NULL   FALSE         <NA>
#>  86:   -1.083332        <NA>        <NA>        <NA>   FALSE         <NA>
#>  87:    2.833747        <NA>        <NA>          -1   FALSE         <NA>
#>  88:   -2.505783        <NA>        <NA>        <NA>   FALSE         <NA>
#>  89:    1.393036        <NA>        <NA>           .   FALSE         <NA>
#>  90:    0.573962        <NA>        <NA>        <NA>   FALSE         <NA>
#>  91:   -3.754840        <NA>        <NA>        <NA>   FALSE         <NA>
#>  92:    0.287611        <NA>        <NA>         999   FALSE         <NA>
#>  93:    1.126676        <NA>                    <NA>    TRUE   2011-11-10
#>  94:    0.439138        <NA>        <NA>         999   FALSE         <NA>
#>  95:    3.185611        <NA>                    <NA>   FALSE         <NA>
#>  96:   -0.401928        <NA>        <NA>         999   FALSE         <NA>
#>  97:   -2.087084        <NA>                    <NA>   FALSE         <NA>
#>  98:   -0.099431        <NA>        <NA>        <NA>   FALSE         <NA>
#>  99:    0.722020        <NA>        <NA>        <NA>   FALSE         <NA>
#> 100:   -3.848476        <NA>        <NA>          -1   FALSE         <NA>
#>      grs_finngen messy_allna messy_empty messy_label htn_hes htn_hes_date
#>            <num>      <char>      <char>      <char>  <lgcl>       <IDat>
#>      htn_death htn_death_date htn_icd10 htn_icd10_date mi_hes mi_hes_date
#>         <lgcl>         <IDat>    <lgcl>         <IDat> <lgcl>      <IDat>
#>   1:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   2:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   3:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   4:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   5:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   6:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   7:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   8:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>   9:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  10:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  11:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  12:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  13:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  14:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  15:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  16:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  17:     FALSE           <NA>      TRUE     2006-10-11  FALSE        <NA>
#>  18:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  19:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  20:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  21:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  22:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  23:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  24:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  25:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  26:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  27:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  28:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  29:     FALSE           <NA>      TRUE     2005-10-28  FALSE        <NA>
#>  30:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  31:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  32:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  33:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  34:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  35:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  36:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  37:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  38:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  39:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  40:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  41:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  42:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  43:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  44:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  45:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  46:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  47:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  48:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  49:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  50:     FALSE           <NA>      TRUE     2017-02-10  FALSE        <NA>
#>  51:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  52:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  53:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  54:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  55:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  56:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  57:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  58:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  59:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  60:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  61:     FALSE           <NA>      TRUE     2016-05-04  FALSE        <NA>
#>  62:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  63:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  64:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  65:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  66:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  67:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  68:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  69:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  70:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  71:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  72:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  73:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  74:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  75:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  76:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  77:     FALSE           <NA>      TRUE     2016-11-12  FALSE        <NA>
#>  78:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  79:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  80:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  81:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  82:     FALSE           <NA>      TRUE     2017-09-11  FALSE        <NA>
#>  83:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  84:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  85:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  86:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  87:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  88:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  89:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  90:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  91:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  92:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  93:     FALSE           <NA>      TRUE     2011-11-10  FALSE        <NA>
#>  94:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  95:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  96:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  97:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  98:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>  99:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#> 100:     FALSE           <NA>     FALSE           <NA>  FALSE        <NA>
#>      htn_death htn_death_date htn_icd10 htn_icd10_date mi_hes mi_hes_date
#>         <lgcl>         <IDat>    <lgcl>         <IDat> <lgcl>      <IDat>
#>      mi_death mi_death_date mi_fo_date  mi_fo mi_icd10 mi_icd10_date
#>        <lgcl>        <IDat>     <IDat> <lgcl>   <lgcl>        <IDat>
#>   1:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   2:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   3:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   4:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   5:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   6:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   7:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   8:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>   9:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  10:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  11:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  12:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  13:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  14:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  15:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  16:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  17:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  18:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  19:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  20:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  21:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  22:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  23:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  24:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  25:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  26:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  27:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  28:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  29:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  30:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  31:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  32:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  33:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  34:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  35:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  36:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  37:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  38:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  39:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  40:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  41:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  42:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  43:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  44:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  45:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  46:    FALSE          <NA> 2006-03-02   TRUE     TRUE    2006-03-02
#>  47:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  48:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  49:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  50:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  51:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  52:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  53:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  54:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  55:    FALSE          <NA> 2005-10-23   TRUE     TRUE    2005-10-23
#>  56:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  57:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  58:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  59:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  60:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  61:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  62:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  63:    FALSE          <NA> 2005-07-05   TRUE     TRUE    2005-07-05
#>  64:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  65:    FALSE          <NA> 2003-06-10   TRUE     TRUE    2003-06-10
#>  66:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  67:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  68:     TRUE    2023-12-04       <NA>  FALSE     TRUE    2023-12-04
#>  69:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  70:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  71:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  72:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  73:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  74:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  75:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  76:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  77:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  78:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  79:    FALSE          <NA> 2012-06-02   TRUE     TRUE    2012-06-02
#>  80:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  81:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  82:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  83:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  84:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  85:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  86:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  87:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  88:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  89:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  90:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  91:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  92:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  93:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  94:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  95:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  96:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  97:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  98:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>  99:     TRUE    2015-03-10       <NA>  FALSE     TRUE    2015-03-10
#> 100:    FALSE          <NA>       <NA>  FALSE    FALSE          <NA>
#>      mi_death mi_death_date mi_fo_date  mi_fo mi_icd10 mi_icd10_date
#>        <lgcl>        <IDat>     <IDat> <lgcl>   <lgcl>        <IDat>
# }
```
