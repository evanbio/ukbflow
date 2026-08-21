# Phenotype Definition Recipes

## Overview

The `recipe_*` functions are a small, read-only library of UK Biobank
phenotype definitions. A recipe records **how a phenotype was
operationally defined** — its data sources, the codes and patterns used,
how those sources combine, and the caveats that matter when reproducing
it.

Recipes are deliberately limited in scope. **No `recipe_*` function
reads or writes your cohort** — none of them takes a `data` argument.
Three of them browse and inspect the library
([`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md),
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
[`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md));
three author a definition
([`recipe_rule()`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md),
[`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md),
[`recipe_write()`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)),
and the only file they touch is the definition itself. The library:

- **records** definitions as versioned YAML — a recipe never silently
  mutates your data;
- **is applied** to data by a single companion function,
  [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
  (part of the `derive_*` family — see
  [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)),
  which you call explicitly;
- **does not** select or recommend a “correct” case definition and is
  not a medical reference;
- ships as versioned YAML files (`inst/extdata/recipes/*.yaml`) so a
  definition can be cited, compared, and contributed to.

The motivation is reproducibility. Phenotype definitions in UK Biobank
studies are often described only in prose, making them hard to reproduce
or compare across papers. A recipe turns that prose into a structured,
inspectable record. Recipes sit alongside the `audit_*` family:
`audit_*` records *what an analysis did*, while `recipe_*` records *how
a phenotype was defined*.

Unlike most of ukbflow, the `recipe_*` functions run entirely locally
and need no RAP access — the examples below execute against the bundled
library.

------------------------------------------------------------------------

## Browse the Library

[`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
returns a one-row-per-recipe index of everything in the bundled library.

``` r

library(ukbflow)

recipe_list()
#> ✔ recipe_list: 67 recipes.
#>                                          id
#>                                      <char>
#>  1:        age_related_macular_degeneration
#>  2:                         aortic_aneurysm
#>  3:                         atherosclerosis
#>  4:                       atopic_dermatitis
#>  5:                     atrial_fibrillation
#>  6:                 atrial_fibrillation_qin
#>  7:                                     bcc
#>  8:                        bradyarrhythmias
#>  9:                                  cancer
#> 10:                         cancer_thompson
#> 11:                          cancer_vazquez
#> 12:                     cardiac_arrhythmias
#> 13:                  cardiovascular_disease
#> 14:               cardiovascular_disease_mu
#> 15:         cardiovascular_disease_thompson
#> 16:         cardiovascular_kidney_metabolic
#> 17:                  chronic_kidney_disease
#> 18:               chronic_kidney_disease_lu
#> 19:                                    copd
#> 20:                               copd_chen
#> 21:                            copd_vazquez
#> 22:                  coronary_heart_disease
#> 23: coronary_heart_disease_first_occurrence
#> 24:           coronary_heart_disease_nyberg
#> 25:          coronary_heart_disease_vazquez
#> 26:                                    cscc
#> 27:                                     cvd
#> 28:                           cvd_mortality
#> 29:                       cvd_mortality_yun
#> 30:                    deep_vein_thrombosis
#> 31:                                dementia
#> 32:                    dementia_algorithmic
#> 33:                        dementia_vazquez
#> 34:                     dementia_yiallourou
#> 35:                              depression
#> 36:                                diabetes
#> 37:                           heart_failure
#> 38:                       heart_failure_qin
#> 39:                            hypertension
#> 40:                                     ihd
#> 41:                                melanoma
#> 42:                   myocardial_infarction
#> 43:                myocardial_infarction_mu
#> 44:               myocardial_infarction_yun
#> 45:       non_alcoholic_fatty_liver_disease
#> 46:                          osteoarthritis
#> 47:                              parkinsons
#> 48:                               psoriasis
#> 49:                      pulmonary_embolism
#> 50:                           severe_asthma
#> 51:                                  stroke
#> 52:                               stroke_lu
#> 53:                               stroke_mu
#> 54:                           stroke_nyberg
#> 55:                              stroke_qin
#> 56:                          stroke_vazquez
#> 57:                              stroke_yun
#> 58:                         type_1_diabetes
#> 59:                         type_2_diabetes
#> 60:                   type_2_diabetes_chong
#> 61:                    type_2_diabetes_feng
#> 62:                      type_2_diabetes_lu
#> 63:                  type_2_diabetes_nyberg
#> 64:                type_2_diabetes_thompson
#> 65:                  type_2_diabetes_wirler
#> 66:                  venous_thromboembolism
#> 67:                 ventricular_arrhythmias
#>                                          id
#>                                      <char>
#>                                       label             short_label version
#>                                      <char>                  <char>   <int>
#>  1:        Age-related macular degeneration                     AMD       2
#>  2:                         Aortic aneurysm                      AA       3
#>  3:                         Atherosclerosis         Atherosclerosis       2
#>  4:                       Atopic dermatitis                      AD       2
#>  5:                     Atrial fibrillation                      AF       1
#>  6:                     Atrial fibrillation                      AF       1
#>  7:                    Basal cell carcinoma                     BCC       2
#>  8:                        Bradyarrhythmias        Bradyarrhythmias       1
#>  9:                                  Cancer                  Cancer       2
#> 10:                                  Cancer                  Cancer       2
#> 11:                                  Cancer                  Cancer       2
#> 12:                     Cardiac arrhythmias             Arrhythmias       1
#> 13:                  Cardiovascular disease                     CVD       2
#> 14:                  Cardiovascular disease                     CVD       1
#> 15:                  Cardiovascular disease                     CVD       2
#> 16: Cardiovascular-kidney-metabolic disease                     CKM       2
#> 17:                  Chronic kidney disease                     CKD       2
#> 18:                  Chronic kidney disease                     CKD       2
#> 19:   Chronic obstructive pulmonary disease                    COPD       2
#> 20:   Chronic obstructive pulmonary disease                    COPD       1
#> 21:   Chronic obstructive pulmonary disease                    COPD       2
#> 22:                  Coronary heart disease                     CHD       3
#> 23:                  Coronary heart disease                     CHD       2
#> 24:                  Coronary heart disease                     CHD       2
#> 25:                  Coronary heart disease                     CHD       3
#> 26:       Cutaneous squamous cell carcinoma                    cSCC       2
#> 27:                  Cardiovascular disease                     CVD       1
#> 28:        Cardiovascular disease mortality           CVD mortality       3
#> 29:        Cardiovascular disease mortality           CVD mortality       1
#> 30:                    Deep vein thrombosis                     DVT       1
#> 31:                      All-cause dementia                Dementia       4
#> 32:                      All-cause dementia                Dementia       3
#> 33:                      All-cause dementia                Dementia       2
#> 34:                      All-cause dementia                Dementia       1
#> 35:                              Depression              Depression       2
#> 36:                                Diabetes                Diabetes       2
#> 37:                           Heart failure                      HF       1
#> 38:                           Heart failure                      HF       1
#> 39:                            Hypertension                     HTN       2
#> 40:                  Ischemic heart disease                     IHD       1
#> 41:                      Malignant melanoma                Melanoma       2
#> 42:                   Myocardial infarction                      MI       2
#> 43:                   Myocardial infarction                      MI       1
#> 44:                   Myocardial infarction                      MI       1
#> 45:       Non-alcoholic fatty liver disease                   NAFLD       2
#> 46:                          Osteoarthritis                      OA       2
#> 47:                     Parkinson's disease            Parkinsonism       2
#> 48:                               Psoriasis               Psoriasis       2
#> 49:                      Pulmonary embolism                      PE       1
#> 50:                           Severe asthma                  Asthma       2
#> 51:                                  Stroke                  Stroke       2
#> 52:                                  Stroke                  Stroke       2
#> 53:                                  Stroke                  Stroke       1
#> 54:                                  Stroke                  Stroke       2
#> 55:                                  Stroke                  Stroke       1
#> 56:                                  Stroke                  Stroke       2
#> 57:                                  Stroke                  Stroke       1
#> 58:                         Type 1 diabetes                     T1D       2
#> 59:                         Type 2 diabetes                     T2D       2
#> 60:                         Type 2 diabetes                     T2D       3
#> 61:                         Type 2 diabetes                     T2D       1
#> 62:                         Type 2 diabetes                     T2D       2
#> 63:                         Type 2 diabetes                     T2D       2
#> 64:                         Type 2 diabetes                     T2D       2
#> 65:                         Type 2 diabetes                     T2D       1
#> 66:                  Venous thromboembolism                     VTE       1
#> 67:                 Ventricular arrhythmias Ventricular arrhythmias       1
#>                                       label             short_label version
#>                                      <char>                  <char>   <int>
#>        updated
#>         <char>
#>  1: 2026-07-13
#>  2: 2026-07-13
#>  3: 2026-07-13
#>  4: 2026-07-13
#>  5: 2026-07-13
#>  6: 2026-07-16
#>  7: 2026-07-13
#>  8: 2026-07-16
#>  9: 2026-07-13
#> 10: 2026-07-13
#> 11: 2026-07-13
#> 12: 2026-07-16
#> 13: 2026-07-13
#> 14: 2026-07-13
#> 15: 2026-07-13
#> 16: 2026-07-13
#> 17: 2026-07-13
#> 18: 2026-07-13
#> 19: 2026-07-13
#> 20: 2026-07-15
#> 21: 2026-07-13
#> 22: 2026-07-21
#> 23: 2026-07-13
#> 24: 2026-07-13
#> 25: 2026-07-21
#> 26: 2026-07-13
#> 27: 2026-07-16
#> 28: 2026-07-13
#> 29: 2026-07-15
#> 30: 2026-07-15
#> 31: 2026-07-21
#> 32: 2026-07-13
#> 33: 2026-07-13
#> 34: 2026-07-15
#> 35: 2026-07-13
#> 36: 2026-07-13
#> 37: 2026-07-13
#> 38: 2026-07-16
#> 39: 2026-07-13
#> 40: 2026-07-16
#> 41: 2026-07-13
#> 42: 2026-07-13
#> 43: 2026-07-13
#> 44: 2026-07-15
#> 45: 2026-07-13
#> 46: 2026-07-13
#> 47: 2026-07-13
#> 48: 2026-07-13
#> 49: 2026-07-15
#> 50: 2026-07-13
#> 51: 2026-07-13
#> 52: 2026-07-13
#> 53: 2026-07-13
#> 54: 2026-07-13
#> 55: 2026-07-16
#> 56: 2026-07-13
#> 57: 2026-07-15
#> 58: 2026-07-13
#> 59: 2026-07-13
#> 60: 2026-07-21
#> 61: 2026-07-13
#> 62: 2026-07-13
#> 63: 2026-07-13
#> 64: 2026-07-13
#> 65: 2026-07-13
#> 66: 2026-07-15
#> 67: 2026-07-16
#>        updated
#>         <char>
```

Pass `details = TRUE` to append the free-text `description` column.

``` r

recipe_list(details = TRUE)
#> ✔ recipe_list: 67 recipes.
#>                                          id
#>                                      <char>
#>  1:        age_related_macular_degeneration
#>  2:                         aortic_aneurysm
#>  3:                         atherosclerosis
#>  4:                       atopic_dermatitis
#>  5:                     atrial_fibrillation
#>  6:                 atrial_fibrillation_qin
#>  7:                                     bcc
#>  8:                        bradyarrhythmias
#>  9:                                  cancer
#> 10:                         cancer_thompson
#> 11:                          cancer_vazquez
#> 12:                     cardiac_arrhythmias
#> 13:                  cardiovascular_disease
#> 14:               cardiovascular_disease_mu
#> 15:         cardiovascular_disease_thompson
#> 16:         cardiovascular_kidney_metabolic
#> 17:                  chronic_kidney_disease
#> 18:               chronic_kidney_disease_lu
#> 19:                                    copd
#> 20:                               copd_chen
#> 21:                            copd_vazquez
#> 22:                  coronary_heart_disease
#> 23: coronary_heart_disease_first_occurrence
#> 24:           coronary_heart_disease_nyberg
#> 25:          coronary_heart_disease_vazquez
#> 26:                                    cscc
#> 27:                                     cvd
#> 28:                           cvd_mortality
#> 29:                       cvd_mortality_yun
#> 30:                    deep_vein_thrombosis
#> 31:                                dementia
#> 32:                    dementia_algorithmic
#> 33:                        dementia_vazquez
#> 34:                     dementia_yiallourou
#> 35:                              depression
#> 36:                                diabetes
#> 37:                           heart_failure
#> 38:                       heart_failure_qin
#> 39:                            hypertension
#> 40:                                     ihd
#> 41:                                melanoma
#> 42:                   myocardial_infarction
#> 43:                myocardial_infarction_mu
#> 44:               myocardial_infarction_yun
#> 45:       non_alcoholic_fatty_liver_disease
#> 46:                          osteoarthritis
#> 47:                              parkinsons
#> 48:                               psoriasis
#> 49:                      pulmonary_embolism
#> 50:                           severe_asthma
#> 51:                                  stroke
#> 52:                               stroke_lu
#> 53:                               stroke_mu
#> 54:                           stroke_nyberg
#> 55:                              stroke_qin
#> 56:                          stroke_vazquez
#> 57:                              stroke_yun
#> 58:                         type_1_diabetes
#> 59:                         type_2_diabetes
#> 60:                   type_2_diabetes_chong
#> 61:                    type_2_diabetes_feng
#> 62:                      type_2_diabetes_lu
#> 63:                  type_2_diabetes_nyberg
#> 64:                type_2_diabetes_thompson
#> 65:                  type_2_diabetes_wirler
#> 66:                  venous_thromboembolism
#> 67:                 ventricular_arrhythmias
#>                                          id
#>                                      <char>
#>                                       label             short_label version
#>                                      <char>                  <char>   <int>
#>  1:        Age-related macular degeneration                     AMD       2
#>  2:                         Aortic aneurysm                      AA       3
#>  3:                         Atherosclerosis         Atherosclerosis       2
#>  4:                       Atopic dermatitis                      AD       2
#>  5:                     Atrial fibrillation                      AF       1
#>  6:                     Atrial fibrillation                      AF       1
#>  7:                    Basal cell carcinoma                     BCC       2
#>  8:                        Bradyarrhythmias        Bradyarrhythmias       1
#>  9:                                  Cancer                  Cancer       2
#> 10:                                  Cancer                  Cancer       2
#> 11:                                  Cancer                  Cancer       2
#> 12:                     Cardiac arrhythmias             Arrhythmias       1
#> 13:                  Cardiovascular disease                     CVD       2
#> 14:                  Cardiovascular disease                     CVD       1
#> 15:                  Cardiovascular disease                     CVD       2
#> 16: Cardiovascular-kidney-metabolic disease                     CKM       2
#> 17:                  Chronic kidney disease                     CKD       2
#> 18:                  Chronic kidney disease                     CKD       2
#> 19:   Chronic obstructive pulmonary disease                    COPD       2
#> 20:   Chronic obstructive pulmonary disease                    COPD       1
#> 21:   Chronic obstructive pulmonary disease                    COPD       2
#> 22:                  Coronary heart disease                     CHD       3
#> 23:                  Coronary heart disease                     CHD       2
#> 24:                  Coronary heart disease                     CHD       2
#> 25:                  Coronary heart disease                     CHD       3
#> 26:       Cutaneous squamous cell carcinoma                    cSCC       2
#> 27:                  Cardiovascular disease                     CVD       1
#> 28:        Cardiovascular disease mortality           CVD mortality       3
#> 29:        Cardiovascular disease mortality           CVD mortality       1
#> 30:                    Deep vein thrombosis                     DVT       1
#> 31:                      All-cause dementia                Dementia       4
#> 32:                      All-cause dementia                Dementia       3
#> 33:                      All-cause dementia                Dementia       2
#> 34:                      All-cause dementia                Dementia       1
#> 35:                              Depression              Depression       2
#> 36:                                Diabetes                Diabetes       2
#> 37:                           Heart failure                      HF       1
#> 38:                           Heart failure                      HF       1
#> 39:                            Hypertension                     HTN       2
#> 40:                  Ischemic heart disease                     IHD       1
#> 41:                      Malignant melanoma                Melanoma       2
#> 42:                   Myocardial infarction                      MI       2
#> 43:                   Myocardial infarction                      MI       1
#> 44:                   Myocardial infarction                      MI       1
#> 45:       Non-alcoholic fatty liver disease                   NAFLD       2
#> 46:                          Osteoarthritis                      OA       2
#> 47:                     Parkinson's disease            Parkinsonism       2
#> 48:                               Psoriasis               Psoriasis       2
#> 49:                      Pulmonary embolism                      PE       1
#> 50:                           Severe asthma                  Asthma       2
#> 51:                                  Stroke                  Stroke       2
#> 52:                                  Stroke                  Stroke       2
#> 53:                                  Stroke                  Stroke       1
#> 54:                                  Stroke                  Stroke       2
#> 55:                                  Stroke                  Stroke       1
#> 56:                                  Stroke                  Stroke       2
#> 57:                                  Stroke                  Stroke       1
#> 58:                         Type 1 diabetes                     T1D       2
#> 59:                         Type 2 diabetes                     T2D       2
#> 60:                         Type 2 diabetes                     T2D       3
#> 61:                         Type 2 diabetes                     T2D       1
#> 62:                         Type 2 diabetes                     T2D       2
#> 63:                         Type 2 diabetes                     T2D       2
#> 64:                         Type 2 diabetes                     T2D       2
#> 65:                         Type 2 diabetes                     T2D       1
#> 66:                  Venous thromboembolism                     VTE       1
#> 67:                 Ventricular arrhythmias Ventricular arrhythmias       1
#>                                       label             short_label version
#>                                      <char>                  <char>   <int>
#>        updated
#>         <char>
#>  1: 2026-07-13
#>  2: 2026-07-13
#>  3: 2026-07-13
#>  4: 2026-07-13
#>  5: 2026-07-13
#>  6: 2026-07-16
#>  7: 2026-07-13
#>  8: 2026-07-16
#>  9: 2026-07-13
#> 10: 2026-07-13
#> 11: 2026-07-13
#> 12: 2026-07-16
#> 13: 2026-07-13
#> 14: 2026-07-13
#> 15: 2026-07-13
#> 16: 2026-07-13
#> 17: 2026-07-13
#> 18: 2026-07-13
#> 19: 2026-07-13
#> 20: 2026-07-15
#> 21: 2026-07-13
#> 22: 2026-07-21
#> 23: 2026-07-13
#> 24: 2026-07-13
#> 25: 2026-07-21
#> 26: 2026-07-13
#> 27: 2026-07-16
#> 28: 2026-07-13
#> 29: 2026-07-15
#> 30: 2026-07-15
#> 31: 2026-07-21
#> 32: 2026-07-13
#> 33: 2026-07-13
#> 34: 2026-07-15
#> 35: 2026-07-13
#> 36: 2026-07-13
#> 37: 2026-07-13
#> 38: 2026-07-16
#> 39: 2026-07-13
#> 40: 2026-07-16
#> 41: 2026-07-13
#> 42: 2026-07-13
#> 43: 2026-07-13
#> 44: 2026-07-15
#> 45: 2026-07-13
#> 46: 2026-07-13
#> 47: 2026-07-13
#> 48: 2026-07-13
#> 49: 2026-07-15
#> 50: 2026-07-13
#> 51: 2026-07-13
#> 52: 2026-07-13
#> 53: 2026-07-13
#> 54: 2026-07-13
#> 55: 2026-07-16
#> 56: 2026-07-13
#> 57: 2026-07-15
#> 58: 2026-07-13
#> 59: 2026-07-13
#> 60: 2026-07-21
#> 61: 2026-07-13
#> 62: 2026-07-13
#> 63: 2026-07-13
#> 64: 2026-07-13
#> 65: 2026-07-13
#> 66: 2026-07-15
#> 67: 2026-07-16
#>        updated
#>         <char>
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                description
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                     <char>
#>  1:                                                                                                                                                                                 A UK Biobank operational phenotype definition for incident age-related macular degeneration as used by Chen et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-025-01340-8): hospital inpatient (HES) records with AMD as a primary or secondary diagnosis, ICD-10 H35.3 and ICD-9 3625.
#>  2:                                                                                                                                                                                                        A UK Biobank operational phenotype definition for incident aortic aneurysm as defined by Aune et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-026-01402-5): ICD-10 I71.1-I71.9 and ICD-9 441.1-441.9 from hospital inpatient (HES) and death-registry records.
#>  3:                                                                                                                                                                                                                A UK Biobank operational phenotype definition for atherosclerosis as used by Lu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04909-6): the UKB First Occurrence field (131380), and ICD-10 I70 from hospital admission and death-registry records.
#>  4:                                                                                                                                                                                                                                                                                                                                   A UK Biobank operational phenotype definition for atopic dermatitis, based on self-report and the ICD-10 L20 First Occurrence field.
#>  5:                                                                                                                                                                            A UK Biobank operational phenotype definition for atrial fibrillation as used by Mu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04701-6): ICD-10 I48 (Table S1) from hospital inpatient (HES, main and secondary diagnosis) and death-registry (primary and secondary cause) records.
#>  6:                                                                                                                                                                                                                                               A UK Biobank operational phenotype definition for atrial fibrillation as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I48 from hospital admission (HES) and death-certificate records.
#>  7:                                                                                                                                                                                                                                                                                        A UK Biobank operational phenotype definition for basal cell carcinoma, based on self-report and cancer-registry records: C44 with basal-cell histology and invasive behaviour.
#>  8:                                                                                                                                                                                                             A UK Biobank operational phenotype definition for bradyarrhythmias as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I44.0, I44.1, I44.2, I44.3, I44.5, I49.5 from hospital admission (HES) and death-certificate records.
#>  9:                                                                                                                 A UK Biobank operational phenotype definition for incident cancer as used by Nyberg et al. 2025 (Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1): ICD-10 C00-C97 (all malignant neoplasms) and ICD-9 140-239 (all neoplasms) from the national cancer registry, hospital inpatient (HES), and death-registry records, any diagnosis position.
#> 10:                                                                                                                                                                                           A UK Biobank operational phenotype definition for incident cancer as used by Thompson et al. 2026 (Lancet Regional Health - Europe, DOI 10.1016/j.lanepe.2026.101736): ICD-10 C00-C97 excluding non-melanoma skin cancer (C44), via linkage with national cancer registries.
#> 11:                                                                                                                                                                                                 A UK Biobank operational phenotype definition for incident cancer as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): ICD-10 C00-C97 and ICD-9 140.1-208.9 (all malignant neoplasms) via linkage with national cancer registries.
#> 12:                                                                                                                                                                                                                                           A UK Biobank operational phenotype definition for cardiac arrhythmias as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I44-I49 from hospital admission (HES) and death-certificate records.
#> 13:                                                        A UK Biobank operational phenotype definition for incident cardiovascular disease as used by Zhang et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-026-01373-7), one component of their cardiovascular-kidney-metabolic (CKM) outcome: ICD-10 I50 (heart failure), I21-I25 (ischaemic heart disease) and I60-I64 (stroke) from hospital inpatient (HES) and death-registry records, plus baseline self-report.
#> 14:                                                                                      A UK Biobank operational phenotype definition for composite cardiovascular disease as used by Mu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04701-6): the union of myocardial infarction, atrial fibrillation, heart failure, and stroke (Table S1), from hospital inpatient (HES, main and secondary diagnosis) and death-registry (primary and secondary cause) records.
#> 15:                                                                                                                                                     A UK Biobank operational phenotype definition for incident cardiovascular disease as used by Thompson et al. 2026 (Lancet Regional Health - Europe, DOI 10.1016/j.lanepe.2026.101736): ICD-10 I20-I23, I24.1, I25.2, I60-I61, I63, I64 from hospital admission and death-registry records, any diagnosis position.
#> 16:   A UK Biobank operational phenotype definition for incident cardiovascular-kidney-metabolic (CKM) disease, the primary composite outcome of Zhang et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-026-01373-7): a case is the first occurrence of any of type 2 diabetes (ICD-10 E11), cardiovascular disease (I50, I21-I25, I60-I64) or chronic kidney disease (N18, I12-I13), from hospital inpatient (HES) and death-registry records, plus baseline self-report.
#> 17:                                                                      A UK Biobank operational phenotype definition for incident chronic kidney disease as used by Zhang et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-026-01373-7), one component of their cardiovascular-kidney-metabolic (CKM) outcome: ICD-10 N18 (kidney failure) and I12-I13 (hypertensive renal disease) from hospital inpatient (HES) and death-registry records, plus baseline self-report.
#> 18:                                                                                                                                                                                         A UK Biobank operational phenotype definition for incident chronic kidney disease as used by Lu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04909-6): the UKB First Occurrence field (132032), plus ICD-10 diagnoses from hospital admission and death-registry records.
#> 19:                                                                                                                                                                              A UK Biobank operational phenotype definition for incident COPD as used by Nyberg et al. 2025 (Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1): ICD-10 J41, J42, J43, J44 (COPD exacerbations) from hospital inpatient (HES) and death-registry records, any diagnosis position.
#> 20:                                                                                                                                                                                                       A UK Biobank operational phenotype definition for incident COPD as used by Chen et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04854-4, PMID 42163317): ICD-10 J43-J44 (plus the ICD-9 equivalents) from hospital inpatient (HES) and death-registry records.
#> 21:                                                                                                                                                                                       A UK Biobank operational phenotype definition for incident COPD as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): the UK Biobank algorithmically-defined COPD outcome (data field 42016), derived by the UKB Outcomes Adjudication Group.
#> 22:                                                                                                                                                                                                                                                      A UK Biobank operational phenotype definition for coronary heart disease from Zisou et al. 2026 (Int J Epidemiol, DOI 10.1093/ije/dyag014): ICD-10 I20-I25, coronary revascularisation (OPCS-4), and self-report.
#> 23:                                                           A UK Biobank operational phenotype definition for incident coronary heart disease as used by Noga et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-026-01362-w): the first occurrence of ICD-10 I20-I25, taken from the UK Biobank First Occurrence fields (Category 1712, IDs 131296-131306), which algorithmically combine primary-care, hospital inpatient (HES), death-registry and self-report records.
#> 24:                                                                                                             A UK Biobank operational phenotype definition for incident coronary heart disease as used by Nyberg et al. 2025 (Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1): non-fatal myocardial infarction (ICD-10 I21-I22) from hospital inpatient (HES) records and coronary death (ICD-10 I20-I25) from death-registry records, any diagnosis position.
#> 25:                                                                                                                                                                                                                                       A UK Biobank operational phenotype definition for incident coronary heart disease as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): ICD-10 I20-I25 from hospital inpatient (HES) records.
#> 26:                                                                                                                                                                                                                                                     A UK Biobank operational phenotype definition for cutaneous squamous cell carcinoma, based on self-report and cancer-registry records, including C44 records with squamous-cell histology and D04 in-situ records.
#> 27:                                                                                                                    A UK Biobank operational phenotype definition for cardiovascular disease as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I20-I25, I60-I64, I50, I42.0, I42.6, I42.7, I42.9, I11.0 (the union of the paper's IHD, stroke, and heart failure subtypes) from hospital admission (HES) and death-certificate records.
#> 28:                                                                                                                                                                                                                                      A UK Biobank operational phenotype definition for cardiovascular disease mortality as defined by Zisou et al. 2026 (Int J Epidemiol, DOI 10.1093/ije/dyag014): death with an underlying cause coded I00-I25, I27-I88, or I95-I99.
#> 29:                                                                                                                                                                                                                               A UK Biobank operational phenotype definition for cardiovascular disease mortality as used by Yun et al. 2026 (eClinicalMedicine, DOI 10.1016/j.eclinm.2026.103769, PMID 41660364): death with an underlying cause coded ICD-10 I00-I99.
#> 30:                                                                                     A UK Biobank operational phenotype definition for incident deep vein thrombosis as used by He et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04893-x): the first occurrence of ICD-10 I80-I82, taken from the UK Biobank First Occurrence fields (Category 1712), which algorithmically combine primary-care, hospital inpatient (HES), death-registry and self-report records.
#> 31:                                                                            A UK Biobank operational phenotype definition for all-cause dementia as defined by Lin et al. 2025 (Environ Health Perspect, DOI 10.1289/EHP14723): the earliest diagnosis from primary care (Read v2/CTV3) and any-position HES inpatient diagnoses (ICD-10, plus ICD-9 in older Scottish records). All arms -- primary-care Read v2/CTV3 and HES ICD-10/ICD-9 -- are executed by ukbflow.
#> 32:                                                                                       A UK Biobank operational phenotype definition for incident all-cause dementia as defined by Novau-Ferré et al. 2025 (Int J Epidemiol, DOI 10.1093/ije/dyaf182): the UK Biobank algorithmically-defined all-cause dementia outcome (data field 42018), derived by the UKB Outcomes Adjudication Group from baseline assessment, hospital admission records, and death registries.
#> 33:                                                                                                                                                           A UK Biobank operational phenotype definition for incident all-cause dementia as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): the UK Biobank algorithmically-defined all-cause dementia outcome (data field 42018), derived by the UKB Outcomes Adjudication Group.
#> 34:                                                                                                                                                                  A UK Biobank operational phenotype definition for incident all-cause dementia as used by Yiallourou et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04536-7): the UK Biobank algorithmically-defined all-cause dementia outcome (data field 42018), derived by the UKB Outcomes Adjudication Group.
#> 35:                                                                                                                                                                                                                                 A UK Biobank operational phenotype definition for incident depression as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): ICD-10 F32-F33 from hospital inpatient (HES) records, plus self-report.
#> 36:                                                                                                                                                                                                                                   A UK Biobank operational phenotype definition for incident diabetes as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): ICD-10 E10-E14 from hospital inpatient (HES) records, plus self-report.
#> 37:                                                                                                                                                      A UK Biobank operational phenotype definition for heart failure as used by Mu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04701-6): ICD-10 I11.0/I13.0/I13.2/I25.5/I42/I50 (Table S1) from hospital inpatient (HES, main and secondary diagnosis) and death-registry (primary and secondary cause) records.
#> 38:                                                                                                                                                                                                                  A UK Biobank operational phenotype definition for heart failure as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I50, I42.0, I42.6, I42.7, I42.9, I11.0 from hospital admission (HES) and death-certificate records.
#> 39:                                                                                                                                     A UK Biobank operational phenotype definition for hypertension as used by Lu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04909-6): self-report, five UKB First Occurrence fields (131286/131288/131290/131292/131294, one per ICD-10 hypertension sub-block), and ICD-10 from hospital admission and death-registry records.
#> 40:                                                                                                                                                                                                                                        A UK Biobank operational phenotype definition for ischemic heart disease as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I20-I25 from hospital admission (HES) and death-certificate records.
#> 41:                                                                                                                                                                                                                                                                                               A UK Biobank operational phenotype definition for malignant melanoma, based on self-report and cancer-registry records: C43 malignant melanoma and D03 melanoma in situ.
#> 42:                                                                                                                                                                                                                                         A UK Biobank operational phenotype definition for myocardial infarction based on Zisou et al. 2026 (Int J Epidemiol, DOI 10.1093/ije/dyag014): ICD-10 I21-I23 from HES inpatient and death-registry records, plus self-report.
#> 43:                                                                                                                                                                  A UK Biobank operational phenotype definition for myocardial infarction as used by Mu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04701-6): ICD-10 I21/I22/I23 (Table S1) from hospital inpatient (HES, main and secondary diagnosis) and death-registry (primary and secondary cause) records.
#> 44:                                                                                                                                                                                                                       A UK Biobank operational phenotype definition for myocardial infarction as used by Yun et al. 2026 (eClinicalMedicine, DOI 10.1016/j.eclinm.2026.103769, PMID 41660364): ICD-10 I21-I22 (plus the ICD-9 equivalents) from HES inpatient records.
#> 45:                                                                                                                                                                                                                      A UK Biobank operational phenotype definition for incident non-alcoholic fatty liver disease (NAFLD) as used by Zhang et al. 2026 (Am J Epidemiol, DOI 10.1093/aje/kwaf046): hospitalisation (HES) or death due to NAFLD, ICD-10 K76.0 and K75.8.
#> 46:                                                                                                                                                                                                                             A UK Biobank operational phenotype definition for incident osteoarthritis as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): ICD-10 M15-M19 from hospital inpatient (HES) records, plus self-report.
#> 47:                                                                                                                                                      A UK Biobank operational phenotype definition for incident Parkinson's disease as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): the UK Biobank algorithmically-defined all-cause parkinsonism outcome (data field 42030), derived by the UKB Outcomes Adjudication Group.
#> 48:                                                                                                                                                                                                                                                                                                                                           A UK Biobank operational phenotype definition for psoriasis, based on self-report and the ICD-10 L40 First Occurrence field.
#> 49:                                                                                           A UK Biobank operational phenotype definition for incident pulmonary embolism as used by He et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04893-x): the first occurrence of ICD-10 I26, taken from the UK Biobank First Occurrence fields (Category 1712), which algorithmically combine primary-care, hospital inpatient (HES), death-registry and self-report records.
#> 50:                                                                                                                           A UK Biobank operational phenotype definition for incident severe asthma as used by Nyberg et al. 2025 (Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1): ICD-10 J45 or J46 from hospital inpatient (HES) and death-registry records, any diagnosis position. Severity is defined by ascertainment through hospitalisation or death.
#> 51:                                                                                                                                                                                                             A UK Biobank operational phenotype definition for stroke as defined by Zisou et al. 2026 (Int J Epidemiol, DOI 10.1093/ije/dyag014): ICD-10 I60-I61 and I63-I64, counting both non-fatal events (HES inpatient records) and fatal events (death registry).
#> 52:                                                                                                                                                 A UK Biobank operational phenotype definition for stroke as used by Lu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04909-6): self-report, five UKB First Occurrence fields (131360/131362/131364/131366/131368, one per ICD-10 stroke sub-block), and ICD-10 from hospital admission and death-registry records.
#> 53:                                                                                                                                                                             A UK Biobank operational phenotype definition for stroke as used by Mu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04701-6): ICD-10 I60/I61/I63/I64 (Table S1) from hospital inpatient (HES, main and secondary diagnosis) and death-registry (primary and secondary cause) records.
#> 54:                                                                                                                                                                                                 A UK Biobank operational phenotype definition for incident stroke as used by Nyberg et al. 2025 (Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1): ICD-10 I60, I61, I63, I64 from hospital inpatient (HES) and death-registry records, any diagnosis position.
#> 55:                                                                                                                                                                                                                                                        A UK Biobank operational phenotype definition for stroke as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I60-I64 from hospital admission (HES) and death-certificate records.
#> 56:                                                                                                                                                                                   A UK Biobank operational phenotype definition for incident stroke as used by Vazquez-Fernandez et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-05010-8): the UK Biobank algorithmically-defined stroke outcome (data field 42006), derived by the UKB Outcomes Adjudication Group.
#> 57:                                                                                                                                                                                                                                      A UK Biobank operational phenotype definition for stroke as used by Yun et al. 2026 (eClinicalMedicine, DOI 10.1016/j.eclinm.2026.103769, PMID 41660364): ICD-10 I60-I64 (plus the ICD-9 equivalents) from HES inpatient records.
#> 58:                                                                                                                                                                                                   A UK Biobank operational phenotype definition for type 1 diabetes as used by Lu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04909-6): self-report, the UKB First Occurrence field (130706), and ICD-10 E10 from hospital admission and death-registry records.
#> 59:                                                                                             A UK Biobank operational phenotype definition for incident type 2 diabetes as used by Zhang et al. 2026 (Eur J Epidemiol, DOI 10.1007/s10654-026-01373-7), one component of their cardiovascular-kidney-metabolic (CKM) outcome: ICD-10 E11 (non-insulin-dependent diabetes mellitus) from hospital inpatient (HES) and death-registry records, plus baseline self-report.
#> 60:                                                                                                                                                                        A UK Biobank operational phenotype definition for incident type 2 diabetes as used by Chong et al. 2026 (Diabetes Care, DOI 10.2337/dc25-3018): ICD-10 E11 from hospital inpatient (HES) and death-registry records, plus general-practice Read v2 and v3 (CTV3) codes, any diagnosis position.
#> 61:                                                                                                                                                                                                                    A UK Biobank operational phenotype definition for incident type 2 diabetes as used by Feng et al. 2026 (Diabetes Care, DOI 10.2337/dc25-2095): ICD-10 E11 from primary care, hospital inpatient (HES), death-registry, and self-reported diagnoses.
#> 62:                                                                                                                                                                                                   A UK Biobank operational phenotype definition for type 2 diabetes as used by Lu et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04909-6): self-report, the UKB First Occurrence field (130708), and ICD-10 E11 from hospital admission and death-registry records.
#> 63:                                                                                                                                                                                                       A UK Biobank operational phenotype definition for incident type 2 diabetes as used by Nyberg et al. 2025 (Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1): ICD-10 E11 from hospital inpatient (HES) and death-registry records, any diagnosis position.
#> 64:                                                                                                                                                                                                 A UK Biobank operational phenotype definition for incident type 2 diabetes as used by Thompson et al. 2026 (Lancet Regional Health - Europe, DOI 10.1016/j.lanepe.2026.101736): ICD-10 E11 from hospital admission and death-registry records, any diagnosis position.
#> 65:                                                                                                                                                                                                                                     A UK Biobank operational phenotype definition for incident type 2 diabetes as used by Wirler et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04907-8): ICD-10 E11 from hospital inpatient (HES) records, any diagnosis position.
#> 66: A UK Biobank operational phenotype definition for incident venous thromboembolism as used by He et al. 2026 (BMC Medicine, DOI 10.1186/s12916-026-04893-x): the first occurrence of ICD-10 I26 (pulmonary embolism) and I80-I82 (deep vein thrombosis and related venous thrombosis), taken from the UK Biobank First Occurrence fields (Category 1712), which algorithmically combine primary-care, hospital inpatient (HES), death-registry and self-report records.
#> 67:                                                                                                                                                                                                      A UK Biobank operational phenotype definition for ventricular arrhythmias as used by Qin et al. 2025 (BMC Medicine, DOI 10.1186/s12916-025-04546-5): ICD-10 I47.0, I47.2, I49.0, I46.0, I46.1, I46.9 from hospital admission (HES) and death-certificate records.
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                description
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                     <char>
```

The listing is tolerant: a file that cannot be parsed, or that lacks a
valid `id`, is skipped with a warning rather than aborting the whole
listing.

------------------------------------------------------------------------

## Inspect One Recipe

[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
reads a single recipe by `id` and returns a normalised `ukbflow_recipe`
object with a readable print method.

``` r

recipe_get("cscc")
#> 
#> ── Recipe: Cutaneous squamous cell carcinoma (cSCC) ────────────────────────────
#> id: cscc | version 2 | updated 2026-07-13
#> A UK Biobank operational phenotype definition for cutaneous squamous cell
#> carcinoma, based on self-report and cancer-registry records, including C44
#> records with squamous-cell histology and D04 in-situ records.
#> 
#> Sources
#>   • selfreport  field="cancer"  regex="^squamous cell carcinoma$"
#>   • cancer_registry
#>       - invasive  icd10="^C44"  histology=[13 codes]  behaviour=3
#>       - in_situ  icd10="^D04"
#>       - in_situ  icd10="^C44"  histology=[13 codes]  behaviour=2
#> 
#> Logic case=any | date=earliest
#> 
#> Notes
#>   1. Cancer-registry cSCC is split into invasive (behaviour 3) and in situ (behaviour 2); in situ additionally includes D04 regardless of histology.
#>   2. Behaviour codes: 3 = invasive / malignant, 2 = in situ.
#>   3. Self-report cancer dates rely on p20006 and baseline (p53); p40005 is deliberately NOT used to correct them, because p40005 instances may not align with the p40006 cancer-type instance and could borrow another cancer's date.
```

Where
[`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
is tolerant,
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
is strict: an unknown `id` or a structurally invalid recipe raises an
error because it cannot be reproduced.

The returned object always has the same shape, which makes it safe to
program against:

- all eleven source slots are present (`selfreport`, `hes`, `hes_icd9`,
  `opcs`, `gp_read2`, `gp_ctv3`, `death`, `first_occurrence`,
  `cancer_registry`, `cancer_registry_icd9`, `algorithm`), each a list
  of rules (empty when unused);
- `logic` carries the documented defaults (`case = "any"`,
  `date = "earliest"`) when the file omits them;
- `notes` is always a character vector.

``` r

ad <- recipe_get("atopic_dermatitis")

names(ad)
#>  [1] "id"          "label"       "short_label" "version"     "created"    
#>  [6] "updated"     "description" "sources"     "logic"       "notes"
ad$logic
#> $case
#> [1] "any"
#> 
#> $date
#> [1] "earliest"
ad$sources$first_occurrence
#> [[1]]
#> [[1]]$field
#> [1] 131720
```

------------------------------------------------------------------------

## Flatten to a Rule Table

[`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md)
flattens a recipe into a tidy `data.table`, one row per rule, in
canonical source order. This is the diff-friendly view: it is well
suited to comparing how different studies operationalised the same
phenotype, and to supplementary tables in a manuscript.

``` r

recipe_sources("cscc")
#> ✔ recipe_sources: 4 rules across 2 sources.
#>             source  rule  subtype  field  match position  cause
#>             <char> <int>   <char> <char> <char>   <char> <char>
#> 1:      selfreport     1     <NA> cancer   <NA>     <NA>   <NA>
#> 2: cancer_registry     1 invasive   <NA>   <NA>     <NA>   <NA>
#> 3: cancer_registry     2  in_situ   <NA>   <NA>     <NA>   <NA>
#> 4: cancer_registry     3  in_situ   <NA>   <NA>     <NA>   <NA>
#>                        regex  icd10   icd9   opcs  read2   ctv3
#>                       <char> <char> <char> <char> <char> <char>
#> 1: ^squamous cell carcinoma$   <NA>   <NA>   <NA>   <NA>   <NA>
#> 2:                      <NA>   ^C44   <NA>   <NA>   <NA>   <NA>
#> 3:                      <NA>   ^D04   <NA>   <NA>   <NA>   <NA>
#> 4:                      <NA>   ^C44   <NA>   <NA>   <NA>   <NA>
#>                                histology behaviour
#>                                   <list>     <num>
#> 1:                                    NA        NA
#> 2: 8051,8052,8070,8071,8072,8073,...[13]         3
#> 3:                                    NA        NA
#> 4: 8070,8071,8072,8073,8074,8075,...[13]         2
```

Each rule’s fields are spread across fixed columns (`source`, `rule`,
`subtype`, `field`, `match`, `position`, `cause`, `regex`, `icd10`,
`icd9`, `histology`, `behaviour`). `histology` is a **list-column**
holding the full integer vector of codes verbatim — nothing is folded or
counted away, so the table retains everything needed to reproduce the
definition.

``` r

rl  <- recipe_sources("cscc")
#> ✔ recipe_sources: 4 rules across 2 sources.
inv <- rl[subtype == "invasive", histology][[1]]
inv
#>  [1] 8051 8052 8070 8071 8072 8073 8074 8075 8076 8077 8078 8083 8084
```

Two columns capture source-specific restrictions that mirror the
`derive_*` arguments. `position` records the HES diagnosis position
(`derive_hes(position = )`: `"any"` for any-position diagnoses, `"main"`
for the primary diagnosis only), and `cause` records which
death-certificate cause was used (`derive_death_registry(cause = )`:
`"any"`, `"primary"` for the underlying cause, or `"secondary"` for
contributory causes). Both are empty where they do not apply and default
to `"any"`, so a recipe sets them only to record a deliberate
restriction — for example, an outcome ascertained from the underlying
cause of death only (`cause = "primary"`).

------------------------------------------------------------------------

## From a Recipe to a Derivation

[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
is the executable counterpart to
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md):
it reads a recipe, dispatches each rule to the matching `derive_*`
function, and combines the results per the recipe’s `logic`. One call
reproduces the full definition:

``` r

dt <- ops_toy(n = 500)
#> ✔ ops_toy: 500 participants | 107 columns | scenario = "cohort" | seed = 42

dt <- derive_recipe(dt, id = "type_2_diabetes")
#> ✔ derive_selfreport (type_2_diabetes): 37 cases, 37 with dates.
#> ✔ derive_hes (type_2_diabetes): 27 cases, 27 with date.
#> ✔ derive_death_registry (type_2_diabetes): 8 cases, 8 with date.
#> ✔ derive_recipe (type_2_diabetes): 71 cases, 71 with date [3 sources; logic: case=any, date=earliest]
```

Regardless of how many sources or rules a recipe uses, only two columns
are added to your data — `{id}_status` (logical) and `{id}_date`
(`IDate`); every source- and rule-level contribution is reported via the
`cli` messages above, not left behind as extra columns:

``` r

grep("^type_2_diabetes_(status|date)$", names(dt), value = TRUE)
#> [1] "type_2_diabetes_status" "type_2_diabetes_date"
```

Because the output is named `{id}_status` / `{id}_date`, it plugs
directly into the rest of the `derive_*` pipeline —
[`derive_age()`](https://evanbio.github.io/ukbflow/reference/derive_age.md),
[`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
and
[`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
already auto-detect that naming (see
[`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
and
[`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md)).

### What `derive_recipe()` does under the hood

The mapping from a recipe to `derive_*` calls is direct — each rule
corresponds to one `derive_*` call, and `logic` corresponds to how the
sources are combined. For the `type_2_diabetes` recipe above, the
equivalent manual derivation reads:

``` r

# selfreport rule  ->  derive_selfreport()
data <- derive_selfreport(
  data,
  name  = "t2d",
  field = "noncancer",
  regex = "^type 2 diabetes$"
)

# hes rule  ->  derive_hes()
data <- derive_hes(data, name = "t2d", icd10 = "E11", match = "prefix")

# death rule  ->  derive_death_registry()
data <- derive_death_registry(data, name = "t2d", icd10 = "E11", match = "prefix")

# logic: case = "any", date = "earliest"  ->  OR the three status columns,
# take the earliest of the three date columns
```

Keeping the recipe and the derivation conceptually separate is
deliberate: the recipe (`recipe_*`) is the citable, read-only record of
intent, and
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
is the explicit call that turns it into data. Recipe derivation does not
run automatically.

------------------------------------------------------------------------

## Write Your Own

A recipe is a YAML file, but you do not have to type YAML to produce
one.
[`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
builds the same structure from plain arguments and validates it as it
goes, so a mistake is an error message rather than a file that breaks
later.

Each source slot accepts a bare vector — shorthand for that slot’s own
code field:

``` r

rec <- recipe_new(
  id      = "myocardial_infarction_demo",
  label   = "Myocardial infarction",
  sources = list(hes = c("I21", "I22"), death = c("I21", "I22")),
  notes   = "Provenance: worked example, not a published definition."
)
#> ✔ recipe_new: "myocardial_infarction_demo" - 2 rules across 2 sources.
```

Use
[`recipe_rule()`](https://evanbio.github.io/ukbflow/reference/recipe_rule.md)
when a rule needs more than codes — a match mode, a diagnosis position,
a cause-of-death restriction:

``` r

rec <- recipe_new(
  id      = "dementia_demo",
  label   = "All-cause dementia",
  sources = list(
    hes      = recipe_rule(icd10 = c("F00", "G30"), match = "prefix"),
    hes_icd9 = recipe_rule(icd9  = c("2902", "3310"), match = "prefix"),
    death    = recipe_rule(icd10 = "F03", cause = "primary")
  ),
  notes = "Provenance: worked example, not a published definition."
)
#> ✔ recipe_new: "dementia_demo" - 3 rules across 3 sources.
```

Fields that are scalar *per rule* — `regex` for self-report, `field` for
First Occurrence and algorithmically-defined outcomes — expand a vector
into one rule each, so a definition built from several First Occurrence
fields is still a single call:

``` r

rec <- recipe_new(
  id      = "hypertension_demo",
  label   = "Hypertension",
  sources = list(first_occurrence = c(131286, 131288, 131290)),
  notes   = "Provenance: worked example, not a published definition."
)
#> ✔ recipe_new: "hypertension_demo" - 3 rules across 1 source.
```

[`print()`](https://rdrr.io/r/base/print.html) renders the object
exactly as it renders a bundled recipe, so you can read the definition
back — here, the three field ids as three separate rules — before
writing anything:

``` r

rec
#> 
#> ── Recipe: Hypertension ────────────────────────────────────────────────────────
#> id: hypertension_demo | version 1 | updated 2026-08-21
#> 
#> Sources
#>   • first_occurrence
#>       - field=131286
#>       - field=131288
#>       - field=131290
#> 
#> Logic case=any | date=earliest
#> 
#> Notes
#>   1. Provenance: worked example, not a published definition.
```

[`recipe_write()`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)
saves it. Generated files carry **no comments** — everything a reader
needs belongs in `notes`, which is validated, returned by
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
shown by [`print()`](https://rdrr.io/r/base/print.html), and read by the
catalogue; a YAML comment is none of those things. An existing file is
never overwritten unless you ask, because the bundled library was
written by hand and its commentary would be lost.

``` r

path <- file.path(tempdir(), "hypertension_demo.yaml")
recipe_write(rec, path)
#> ✔ recipe_write: "hypertension_demo" -> /tmp/RtmpvLVHcz/hypertension_demo.yaml.

cat(readLines(path)[1:8], sep = "\n")
#> id: hypertension_demo
#> label: Hypertension
#> version: 1
#> created: '2026-08-21'
#> updated: '2026-08-21'
#> sources:
#>   selfreport: []
#>   hes: []
```

See
[`?recipe_new`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
for the per-slot reference: which fields each source accepts, which take
a bare vector, and which expand.

------------------------------------------------------------------------

## Contributing a Recipe

The library is designed to be contributable: whatever route you take,
the thing that gets reviewed and merged is one YAML file under
`inst/extdata/recipes/`, with a fixed schema and no accompanying code
change. There are three ways to produce it, and none is second class:

- **A form**, if you would rather not touch YAML or git — open a [Recipe
  submission](https://github.com/evanbio/ukbflow/issues/new?template=recipe_submission.yml)
  issue and fill in the codes. Once a maintainer accepts it, a pull
  request is generated from what you entered.
- **[`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)**,
  as above, if you already work in R.
- **The YAML file itself**, written by hand — how the bundled library
  was built.

The full guide — the schema reference, an annotated template, the local
validation steps, and a submission checklist — lives in
[`CONTRIBUTING_RECIPE.md`](https://github.com/evanbio/ukbflow/blob/main/.github/CONTRIBUTING_RECIPE.md).

When adding a phenotype, model it on an existing recipe of a similar
shape — `atopic_dermatitis` for a self-report plus First Occurrence
definition, `cscc` for a self-report plus cancer-registry definition
with histology and behaviour filters, and `dementia` for an HES ICD-10
plus ICD-9 definition combined with primary-care Read v2 and CTV3 codes.
