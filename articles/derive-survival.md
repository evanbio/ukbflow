# Survival Analysis Setup for UKB Outcomes

## Overview

After disease case definitions have been derived (see
[`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)),
three additional functions prepare the data for time-to-event analysis:

| Function                                                                              | Output columns                                 | Purpose                                 |
|---------------------------------------------------------------------------------------|------------------------------------------------|-----------------------------------------|
| [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)     | `{name}_timing`                                | Classify prevalent vs. incident disease |
| [`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md)           | `age_at_{name}`                                | Age at event (years)                    |
| [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md) | `{name}_followup_end`, `{name}_followup_years` | Follow-up end date and duration         |

> **Prerequisite**: `{name}_status` and `{name}_date` must already be
> present — produced by
> [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md).
> The examples below assume the full disease derivation pipeline has
> been run on an
> [`ops_toy()`](https://evanbio.github.io/ukbflow/reference/ops_toy.md)
> dataset, so the baseline date column is `p53_i0` and age at
> recruitment is `p21022`.

------------------------------------------------------------------------

## Step 1: Classify Timing — Prevalent vs. Incident

[`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
compares the disease date to the UKB baseline assessment date and
assigns each participant to one of four categories:

| Value | Meaning                                                 |
|-------|---------------------------------------------------------|
| `0`   | No disease (`status` is `FALSE`)                        |
| `1`   | **Prevalent** — disease date on or before baseline      |
| `2`   | **Incident** — disease date strictly after baseline     |
| `NA`  | Case with no recorded date; timing cannot be determined |

``` r
library(ukbflow)

# Build on the derive pipeline from vignette("derive")
df <- ops_toy(n = 500)
df <- derive_missing(df)
df <- derive_covariate(df, as_factor = c("p31", "p20116_i0"))
df <- derive_selfreport(df, name = "dm", regex = "type 2 diabetes")
df <- derive_icd10(df, name = "dm", icd10 = "E11", source = c("hes", "death"))
df <- derive_case(df, name = "dm")
```

``` r
# Uses {name}_status and {name}_date by default
df <- derive_timing(df, name = "dm", baseline_col = "p53_i0")
```

Supply explicit column names when the defaults do not apply:

``` r
df <- derive_timing(df,
  name         = "dm",
  status_col   = "dm_status",
  date_col     = "dm_date",
  baseline_col = "p53_i0"
)
```

Call once per variable needed — for example, once for the combined case
and once per individual source (HES, self-report, etc.).

------------------------------------------------------------------------

## Step 2: Age at Event

[`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md)
computes age at the time of the event for cases, and returns `NA` for
non-cases and cases without a date.

$$\text{age\_at\_event} = \text{age\_at\_recruitment} + \frac{\text{event\_date} - \text{baseline\_date}}{365.25}$$

The divisor 365.25 accounts for leap years, ensuring sub-monthly
precision in age calculation across the full UKB follow-up window.

``` r
# Auto-detects {name}_date and {name}_status; produces age_at_{name} column.
df <- derive_age(df,
  name         = "dm",
  baseline_col = "p53_i0",
  age_col      = "p21022"
)
```

Supply explicit column mappings when names do not follow the default
`{name}_date` / `{name}_status` pattern:

``` r
df <- derive_age(df,
  name         = "dm",
  baseline_col = "p53_i0",
  age_col      = "p21022",
  date_cols    = c(dm = "dm_date"),
  status_cols  = c(dm = "dm_status")
)
```

------------------------------------------------------------------------

## Step 3: Follow-Up Time

[`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
computes the follow-up end date as the **earliest** of:

1.  The outcome event date (if the participant is a case)
2.  Date of death (field 40000; competing event)
3.  Date lost to follow-up (field 191)
4.  The administrative censoring date

Follow-up time in years is then derived from the baseline date.

``` r
df <- derive_followup(df,
  name         = "dm",
  event_col    = "dm_date",
  baseline_col = "p53_i0",
  censor_date  = as.Date("2022-10-31"),   # set to your study's cut-off date
  death_col    = "p40000_i0",
  lost_col     = FALSE                    # not available in ops_toy
)
```

Output columns:

| Column              | Type    | Description                |
|---------------------|---------|----------------------------|
| `dm_followup_end`   | IDate   | Earliest competing date    |
| `dm_followup_years` | numeric | Years from baseline to end |

### Prevalent cases receive `NA` follow-up time

Participants whose event date falls **before or on the baseline date**
(prevalent cases, `{name}_timing == 1`) will have `followup_years` set
to `NA` rather than a zero or negative value, which has no meaning in
time-to-event analysis. Use
[`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
to identify and exclude prevalent cases before fitting a Cox model (see
the full pipeline example below).

### Auto-detection of death and lost-to-follow-up columns

When `death_col` and `lost_col` are `NULL` (default),
[`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
looks them up automatically from the field cache (UKB fields 40000 and
191). Pass `FALSE` to explicitly disable a competing event:

``` r
df <- derive_followup(df,
  name         = "dm",
  event_col    = "dm_date",
  baseline_col = "p53_i0",
  censor_date  = as.Date("2022-10-31"),
  death_col    = FALSE,
  lost_col     = FALSE
)
```

------------------------------------------------------------------------

## Full Survival-Ready Pipeline

After completing all three steps, the data contains everything needed to
fit a Cox proportional hazards model:

``` r
library(survival)

# Incident analysis: exclude prevalent cases and those with undetermined timing
df_incident <- df[dm_timing != 1L]

fit <- coxph(
  Surv(dm_followup_years, dm_status) ~
    p20116_i0 + p21022 + p31 + p1558_i0,
  data = df_incident
)
summary(fit)
```

Column roles in the model:

| Column              | Role                                                |
|---------------------|-----------------------------------------------------|
| `dm_status`         | Event indicator (logical)                           |
| `dm_followup_years` | Time variable                                       |
| `dm_timing`         | Filter: exclude prevalent (`== 1`)                  |
| `age_at_dm`         | Age at diagnosis (descriptive / secondary analysis) |
| `p20116_i0`         | Exposure of interest (smoking status)               |

------------------------------------------------------------------------

## Getting Help

- [`?derive_timing`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
  [`?derive_age`](https://evanbio.github.io/ukbflow/reference/derive_age.md),
  [`?derive_followup`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
  — disease phenotype derivation
- [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md)
  — decoding column names and values
- [GitHub Issues](https://github.com/evanbio/ukbflow/issues)
