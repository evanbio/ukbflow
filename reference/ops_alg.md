# Algorithmically-defined outcome fields (offline lookup)

UK Biobank derives an "algorithmically-defined outcome" (ADO, Category
42) for each of 19 selected health outcomes across 8 disease groups
(myocardial infarction, stroke, asthma, COPD, dementia, end-stage renal
disease, motor neurone disease and parkinsonism, several with subtypes).
For each outcome the adjudication algorithm takes the earliest recorded
date across self-report, hospital inpatient and death data, and a paired
*source* field naming which of those the earliest record came from. This
is an offline catalogue mapping each outcome to its date and source
field IDs, so the right field can be found without searching the
Showcase; the date field feeds straight into
[`derive_algorithm`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md).

## Usage

``` r
ops_alg(pattern = NULL, category = NULL)
```

## Arguments

- pattern:

  (character or NULL) Optional case-insensitive keyword or regular
  expression filtered across the `name` and the `date_field` /
  `source_field` IDs. A field ID does a reverse lookup. Default `NULL`
  returns all outcomes.

- category:

  (character or NULL) Optional case-insensitive keyword matched against
  the `category` column, e.g. `"stroke"`.

## Value

A `data.table` with columns:

- name:

  Outcome name.

- category:

  UK Biobank outcome category the outcome belongs to.

- date_field:

  Integer field ID of the outcome date.

- source_field:

  Integer field ID of the paired source-of-report.

## Details

The algorithms are UK Biobank's own adjudicated definitions and aim for
high positive predictive value; see UK Biobank Resource 593 for
source-specific PPV estimates.

The full table is always returned; `pattern` and `category` only subset
it. Console output reports what came back – one line per category for an
unfiltered call, a single line otherwise.

## Examples

``` r
ops_alg()
#> 
#> ── ukbflow algorithmically-defined outcomes ────────────────────────────────────
#> Myocardial infarction outcomes: 3
#> Stroke outcomes: 4
#> Asthma outcomes: 1
#> COPD outcomes: 1
#> Dementia outcomes: 4
#> End stage renal disease outcomes: 1
#> Motor neurone disease outcomes: 1
#> Parkinson's disease outcomes: 4
#> total: 19
#>                                      name                         category
#>                                    <char>                           <char>
#>  1:                 myocardial infarction   Myocardial infarction outcomes
#>  2:                                 STEMI   Myocardial infarction outcomes
#>  3:                                NSTEMI   Myocardial infarction outcomes
#>  4:                                stroke                  Stroke outcomes
#>  5:                      ischaemic stroke                  Stroke outcomes
#>  6:             intracerebral haemorrhage                  Stroke outcomes
#>  7:              subarachnoid haemorrhage                  Stroke outcomes
#>  8:                                asthma                  Asthma outcomes
#>  9: chronic obstructive pulmonary disease                    COPD outcomes
#> 10:                    all cause dementia                Dementia outcomes
#> 11:                   alzheimer's disease                Dementia outcomes
#> 12:                     vascular dementia                Dementia outcomes
#> 13:               frontotemporal dementia                Dementia outcomes
#> 14:               end stage renal disease End stage renal disease outcomes
#> 15:                 motor neurone disease   Motor neurone disease outcomes
#> 16:                all cause parkinsonism     Parkinson's disease outcomes
#> 17:                   parkinson's disease     Parkinson's disease outcomes
#> 18:        progressive supranuclear palsy     Parkinson's disease outcomes
#> 19:               multiple system atrophy     Parkinson's disease outcomes
#>     date_field source_field
#>          <int>        <int>
#>  1:      42000        42001
#>  2:      42002        42003
#>  3:      42004        42005
#>  4:      42006        42007
#>  5:      42008        42009
#>  6:      42010        42011
#>  7:      42012        42013
#>  8:      42014        42015
#>  9:      42016        42017
#> 10:      42018        42019
#> 11:      42020        42021
#> 12:      42022        42023
#> 13:      42024        42025
#> 14:      42026        42027
#> 15:      42028        42029
#> 16:      42030        42031
#> 17:      42032        42033
#> 18:      42034        42035
#> 19:      42036        42037
ops_alg("dementia")
#> ✔ ops_alg: 3 outcomes matching "dementia".
#>                       name          category date_field source_field
#>                     <char>            <char>      <int>        <int>
#> 1:      all cause dementia Dementia outcomes      42018        42019
#> 2:       vascular dementia Dementia outcomes      42022        42023
#> 3: frontotemporal dementia Dementia outcomes      42024        42025
ops_alg("42018")                   # reverse lookup by field ID
#> ✔ ops_alg: 1 outcome matching "42018".
#>                  name          category date_field source_field
#>                <char>            <char>      <int>        <int>
#> 1: all cause dementia Dementia outcomes      42018        42019
ops_alg(category = "stroke")
#> ✔ ops_alg: 4 outcomes in category "stroke".
#>                         name        category date_field source_field
#>                       <char>          <char>      <int>        <int>
#> 1:                    stroke Stroke outcomes      42006        42007
#> 2:          ischaemic stroke Stroke outcomes      42008        42009
#> 3: intracerebral haemorrhage Stroke outcomes      42010        42011
#> 4:  subarachnoid haemorrhage Stroke outcomes      42012        42013
```
