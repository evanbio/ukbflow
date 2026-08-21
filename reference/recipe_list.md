# List available phenotype recipes

Scans the bundled recipe library and returns a one-row-per-recipe index
of the UK Biobank phenotype definitions shipped with ukbflow. Recipes
are read-only reference definitions: each records how a phenotype was
operationally defined (sources, codes, combination logic, caveats) so an
analysis can be reproduced. The recipe library does not apply
definitions to data or decide a case definition on the user's behalf.

## Usage

``` r
recipe_list(details = FALSE)
```

## Arguments

- details:

  (logical) Include the verbose `description` column? Default `FALSE`
  keeps the listing concise (`id`, `label`, `short_label`, `version`,
  `updated`); `TRUE` appends `description`.

## Value

A `data.table` with one row per recipe and columns `id`, `label`,
`short_label`, `version`, and `updated`, plus `description` when
`details = TRUE`. Returns an empty table (with these columns) when no
recipe library is available.

## Details

Recipe files live in `inst/extdata/recipes/*.yaml`. Files that cannot be
parsed, or that lack a valid `id`, are skipped with a warning rather
than aborting the listing.

## Examples

``` r
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
