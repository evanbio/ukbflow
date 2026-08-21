# Common UK Biobank fields for quick reference

Returns a small offline reference table of frequently used UK Biobank
field IDs. This helper is intentionally limited: it is not a complete
UKB data dictionary and does not imply that a field is approved or
available in the current RAP project. Use
[`extract_ls`](https://evanbio.github.io/ukbflow/reference/extract_ls.md)
to search the approved fields in the active project before extraction.

## Usage

``` r
ops_fields_common(pattern = NULL, group = NULL)
```

## Arguments

- pattern:

  (character or NULL) Optional case-insensitive keyword or regular
  expression used to filter across `field_id`, `title`, `description`,
  `group`, and `structure`. Default `NULL` returns all common fields.

- group:

  (character or NULL) Optional group filter. Use values from the
  returned `group` column, e.g. `"demographics"`, `"genetics"`,
  `"self_report"`, `"hes"`, `"death"`, `"cancer_registry"`, or
  `"lifestyle"`.

## Value

A `data.table` with columns:

- field_id:

  Integer UKB field ID.

- title:

  UKB field title.

- description:

  Short practical description of the field.

- group:

  Broad reference group.

- structure:

  Expected field shape: `"single"`, `"instance"`, `"array"`, or
  `"instance_array"`.

## Examples

``` r
ops_fields_common()
#>     field_id
#>        <int>
#>  1:       31
#>  2:       34
#>  3:       53
#>  4:       54
#>  5:    21022
#>  6:    21000
#>  7:    22189
#>  8:    22009
#>  9:    22000
#> 10:    22001
#> 11:    22006
#> 12:    22020
#> 13:    22021
#> 14:    20002
#> 15:    20008
#> 16:    20009
#> 17:    20001
#> 18:    20006
#> 19:    20007
#> 20:    41270
#> 21:    41280
#> 22:    40000
#> 23:    40001
#> 24:    40002
#> 25:    40005
#> 26:    40006
#> 27:    40011
#> 28:    40012
#> 29:    21001
#> 30:    20116
#> 31:     1558
#> 32:      738
#> 33:      845
#> 34:      894
#> 35:      904
#>     field_id
#>        <int>
#>                                                                       title
#>                                                                      <char>
#>  1:                                                                     Sex
#>  2:                                                           Year of birth
#>  3:                                     Date of attending assessment centre
#>  4:                                            UK Biobank assessment centre
#>  5:                                                      Age at recruitment
#>  6:                                                       Ethnic background
#>  7:                               Townsend deprivation index at recruitment
#>  8:                                            Genetic principal components
#>  9:                                              Genotype measurement batch
#> 10:                                                             Genetic sex
#> 11:                                                 Genetic ethnic grouping
#> 12:                                    Used in genetic principal components
#> 13:                                   Genetic kinship to other participants
#> 14:                                                 Non-cancer illness code
#> 15:               Interpolated Year when non-cancer illness first diagnosed
#> 16: Interpolated Age of participant when non-cancer illness first diagnosed
#> 17:                                                             Cancer code
#> 18:                           Interpolated Year when cancer first diagnosed
#> 19:             Interpolated Age of participant when cancer first diagnosed
#> 20:                                                       Diagnoses - ICD10
#> 21:                              Date of first in-patient diagnosis - ICD10
#> 22:                                                           Date of death
#> 23:                              Underlying (primary) cause of death: ICD10
#> 24:                         Contributory (secondary) causes of death: ICD10
#> 25:                                                Date of cancer diagnosis
#> 26:                                                   Type of cancer: ICD10
#> 27:                                              Histology of cancer tumour
#> 28:                                              Behaviour of cancer tumour
#> 29:                                                   Body mass index (BMI)
#> 30:                                                          Smoking status
#> 31:                                               Alcohol intake frequency.
#> 32:                               Average total household income before tax
#> 33:                                       Age completed full time education
#> 34:                                           Duration of moderate activity
#> 35:           Number of days/week of vigorous physical activity 10+ minutes
#>                                                                       title
#>                                                                      <char>
#>                                                  description           group
#>                                                       <char>          <char>
#>  1:                                         Participant sex.    demographics
#>  2:                               Participant year of birth.    demographics
#>  3:                                   Assessment visit date.    demographics
#>  4:           Assessment centre attended by the participant.    demographics
#>  5:                                      Age at recruitment.    demographics
#>  6:                         Self-reported ethnic background.    demographics
#>  7:             Area-level deprivation index at recruitment.    demographics
#>  8:                   Genetic ancestry principal components.        genetics
#>  9:                     Genotyping batch or array indicator.        genetics
#> 10:                          Genetic sex from genotype data.        genetics
#> 11:                                 Genetic ethnic grouping.        genetics
#> 12: Indicator for inclusion in genetic principal components.        genetics
#> 13:                                    Genetic kinship flag.        genetics
#> 14:                   Self-reported non-cancer illness code.     self_report
#> 15:         Self-reported non-cancer illness diagnosis year.     self_report
#> 16:          Self-reported non-cancer illness diagnosis age.     self_report
#> 17:                               Self-reported cancer code.     self_report
#> 18:                     Self-reported cancer diagnosis year.     self_report
#> 19:                      Self-reported cancer diagnosis age.     self_report
#> 20:       Any-position HES inpatient ICD-10 diagnosis codes.             hes
#> 21:   Dates corresponding to HES inpatient ICD-10 diagnoses.             hes
#> 22:                                              Death date.           death
#> 23:             Underlying primary cause of death in ICD-10.           death
#> 24:        Contributory secondary causes of death in ICD-10.           death
#> 25:                          Cancer registry diagnosis date. cancer_registry
#> 26:                      Cancer registry ICD-10 cancer type. cancer_registry
#> 27:                        Cancer registry tumour histology. cancer_registry
#> 28:                        Cancer registry tumour behaviour. cancer_registry
#> 29:                                Measured body mass index.       lifestyle
#> 30:                                          Smoking status.       lifestyle
#> 31:                                Alcohol intake frequency.       lifestyle
#> 32:                     Average household income before tax.       lifestyle
#> 33:              Age when full-time education was completed.       lifestyle
#> 34:                  Duration of moderate physical activity.       lifestyle
#> 35:                 Frequency of vigorous physical activity.       lifestyle
#>                                                  description           group
#>                                                       <char>          <char>
#>          structure
#>             <char>
#>  1:         single
#>  2:         single
#>  3:       instance
#>  4:       instance
#>  5:         single
#>  6:       instance
#>  7:         single
#>  8:          array
#>  9:         single
#> 10:         single
#> 11:         single
#> 12:         single
#> 13:         single
#> 14: instance_array
#> 15: instance_array
#> 16: instance_array
#> 17: instance_array
#> 18: instance_array
#> 19: instance_array
#> 20:         single
#> 21:          array
#> 22:       instance
#> 23:       instance
#> 24: instance_array
#> 25:       instance
#> 26:       instance
#> 27:       instance
#> 28:       instance
#> 29:       instance
#> 30:       instance
#> 31:       instance
#> 32:       instance
#> 33:       instance
#> 34:       instance
#> 35:       instance
#>          structure
#>             <char>
ops_fields_common("sex")
#>    field_id       title                     description        group structure
#>       <int>      <char>                          <char>       <char>    <char>
#> 1:       31         Sex                Participant sex. demographics    single
#> 2:    22001 Genetic sex Genetic sex from genotype data.     genetics    single
ops_fields_common(group = "genetics")
#>    field_id                                 title
#>       <int>                                <char>
#> 1:    22009          Genetic principal components
#> 2:    22000            Genotype measurement batch
#> 3:    22001                           Genetic sex
#> 4:    22006               Genetic ethnic grouping
#> 5:    22020  Used in genetic principal components
#> 6:    22021 Genetic kinship to other participants
#>                                                 description    group structure
#>                                                      <char>   <char>    <char>
#> 1:                   Genetic ancestry principal components. genetics     array
#> 2:                     Genotyping batch or array indicator. genetics    single
#> 3:                          Genetic sex from genotype data. genetics    single
#> 4:                                 Genetic ethnic grouping. genetics    single
#> 5: Indicator for inclusion in genetic principal components. genetics    single
#> 6:                                    Genetic kinship flag. genetics    single
```
