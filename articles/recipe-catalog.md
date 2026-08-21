# Recipe Catalog: The Phenotype Definition Library

## Purpose

`ukbflow` ships a versioned library of reproducible UK Biobank phenotype
definitions (“recipes”). Each recipe records **how a phenotype was
ascertained** by a published study (or a standard definition): the data
sources, the codes, the reconciliation logic, and the caveats that
matter when reproducing it.

This page is a **live catalog** of that library — the table below is
generated at build time directly from the installed recipes, so it
always reflects the current contents. For how to *use* recipes
([`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md),
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
[`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md))
and how to write one
([`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)),
see
[`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md);
for the data sources and code systems these recipes draw on, see
[`vignette("phenotype-scope")`](https://evanbio.github.io/ukbflow/articles/phenotype-scope.md).

## Library at a Glance

``` r

library(ukbflow)

# Prettify the fixed source-slot names for display.
slot_labels <- c(
  selfreport            = "Self-report",
  hes                   = "HES",
  hes_icd9              = "HES (ICD-9)",
  opcs                  = "HES (OPCS-4)",
  gp_read2              = "GP (Read v2)",
  gp_ctv3               = "GP (CTV3)",
  death                 = "Death",
  first_occurrence      = "First Occurrence",
  cancer_registry       = "Cancer registry",
  cancer_registry_icd9  = "Cancer registry (ICD-9)",
  algorithm             = "Algorithm"
)

catalog <- do.call(rbind, lapply(recipe_list()$id, function(id) {
  r <- recipe_get(id)

  # Source slots actually used by this recipe (non-empty rule lists).
  used  <- names(r$sources)[vapply(r$sources, length, integer(1)) > 0L]
  used  <- slot_labels[used]

  # Provenance: the first note, trimmed to author + year + journal.
  notes <- unlist(r$notes)
  prov  <- sub("^Provenance: ", "", notes[1])
  prov  <- sub(" DOI.*$", "", prov)      # drop DOI / PMID / trailing detail
  prov  <- sub("[,.] *$", "", prov)

  # Coverage: full unless a note records an arm ukbflow cannot execute
  # (recorded verbatim but "not applied" / "not currently supported", etc.).
  gap <- any(grepl(
    "COVERAGE|not applied|not executed|not executable|not currently supported",
    notes, ignore.case = TRUE
  ))

  data.frame(
    ID         = id,
    Phenotype  = r$label,
    Sources    = paste(used, collapse = ", "),
    Provenance = prov,
    Coverage   = if (gap) "Partial — see notes" else "Full",
    stringsAsFactors = FALSE
  )
}))

knitr::kable(
  catalog,
  row.names = FALSE,
  caption   = sprintf("%d phenotype recipes currently in the library.",
                      nrow(catalog))
)
```

| ID | Phenotype | Sources | Provenance | Coverage |
|:---|:---|:---|:---|:---|
| age_related_macular_degeneration | Age-related macular degeneration | HES, HES (ICD-9) | Chen et al. 2026, Eur J Epidemiol | Full |
| aortic_aneurysm | Aortic aneurysm | HES, HES (ICD-9), Death | Aune et al. 2026, Eur J Epidemiol | Full |
| atherosclerosis | Atherosclerosis | HES, Death, First Occurrence | Lu et al. 2026, BMC Medicine | Full |
| atopic_dermatitis | Atopic dermatitis | Self-report, First Occurrence | UKB self-report (p20002) only codes ‘eczema/dermatitis’; UKB has no distinct ‘atopic dermatitis’, ‘atopic eczema’, or ‘infantile/childhood/flexural eczema’ term | Full |
| atrial_fibrillation | Atrial fibrillation | HES, Death | Mu et al. 2026, BMC Medicine | Full |
| atrial_fibrillation_qin | Atrial fibrillation | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| bcc | Basal cell carcinoma | Self-report, Cancer registry | Cancer-registry BCC is C44 with basal-cell-carcinoma histology (8090-8098) and behaviour 3 (invasive / malignant) | Full |
| bradyarrhythmias | Bradyarrhythmias | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| cancer | Cancer | HES, HES (ICD-9), Death, Cancer registry, Cancer registry (ICD-9) | Nyberg et al. 2025, Lancet Public Health | Full |
| cancer_thompson | Cancer | Cancer registry | Thompson et al. 2026, Lancet Regional Health - Europe | Full |
| cancer_vazquez | Cancer | Cancer registry, Cancer registry (ICD-9) | Vazquez-Fernandez et al. 2026, BMC Medicine | Full |
| cardiac_arrhythmias | Cardiac arrhythmias | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| cardiovascular_disease | Cardiovascular disease | Self-report, HES, Death | Zhang et al. 2026, Eur J Epidemiol | Full |
| cardiovascular_disease_mu | Cardiovascular disease | HES, Death | Mu et al. 2026, BMC Medicine | Full |
| cardiovascular_disease_thompson | Cardiovascular disease | HES, Death | Thompson et al. 2026, Lancet Regional Health - Europe | Full |
| cardiovascular_kidney_metabolic | Cardiovascular-kidney-metabolic disease | Self-report, HES, Death | Zhang et al. 2026, Eur J Epidemiol | Full |
| chronic_kidney_disease | Chronic kidney disease | Self-report, HES, Death | Zhang et al. 2026, Eur J Epidemiol | Full |
| chronic_kidney_disease_lu | Chronic kidney disease | HES, Death, First Occurrence | Lu et al. 2026, BMC Medicine | Full |
| copd | Chronic obstructive pulmonary disease | HES, HES (ICD-9), Death | Nyberg et al. 2025, Lancet Public Health | Full |
| copd_chen | Chronic obstructive pulmonary disease | HES, HES (ICD-9), Death | Chen et al. 2026, BMC Medicine | Full |
| copd_vazquez | Chronic obstructive pulmonary disease | Algorithm | Vazquez-Fernandez et al. 2026, BMC Medicine | Full |
| coronary_heart_disease | Coronary heart disease | Self-report, HES, HES (OPCS-4), Death | Zisou et al. 2026, Int J Epidemiol | Partial — see notes |
| coronary_heart_disease_first_occurrence | Coronary heart disease | First Occurrence | Noga et al. 2026, Eur J Epidemiol | Partial — see notes |
| coronary_heart_disease_nyberg | Coronary heart disease | HES, HES (ICD-9), Death | Nyberg et al. 2025, Lancet Public Health | Full |
| coronary_heart_disease_vazquez | Coronary heart disease | HES, HES (ICD-9), HES (OPCS-4) | Vazquez-Fernandez et al. 2026, BMC Medicine | Partial — see notes |
| cscc | Cutaneous squamous cell carcinoma | Self-report, Cancer registry | Cancer-registry cSCC is split into invasive (behaviour 3) and in situ (behaviour 2); in situ additionally includes D04 regardless of histology | Full |
| cvd | Cardiovascular disease | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| cvd_mortality | Cardiovascular disease mortality | Death | Zisou et al. 2026, Int J Epidemiol | Full |
| cvd_mortality_yun | Cardiovascular disease mortality | Death | Yun et al. 2026, eClinicalMedicine | Full |
| deep_vein_thrombosis | Deep vein thrombosis | First Occurrence | He et al. 2026, BMC Medicine | Partial — see notes |
| dementia | All-cause dementia | HES, HES (ICD-9), GP (Read v2), GP (CTV3) | Lin et al. 2025, Environ Health Perspect | Full |
| dementia_algorithmic | All-cause dementia | Algorithm | Novau-Ferré et al. 2025, Int J Epidemiol | Full |
| dementia_vazquez | All-cause dementia | Algorithm | Vazquez-Fernandez et al. 2026, BMC Medicine | Full |
| dementia_yiallourou | All-cause dementia | Algorithm | Yiallourou et al. 2025, BMC Medicine | Full |
| depression | Depression | Self-report, HES | Vazquez-Fernandez et al. 2026, BMC Medicine | Partial — see notes |
| diabetes | Diabetes | Self-report, HES | Vazquez-Fernandez et al. 2026, BMC Medicine | Partial — see notes |
| heart_failure | Heart failure | HES, Death | Mu et al. 2026, BMC Medicine | Full |
| heart_failure_qin | Heart failure | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| hypertension | Hypertension | Self-report, HES, Death, First Occurrence | Lu et al. 2026, BMC Medicine | Full |
| ihd | Ischemic heart disease | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| melanoma | Malignant melanoma | Self-report, Cancer registry | Cancer-registry melanoma is ascertained from ICD-10 alone (C43 = malignant, D03 = in situ); unlike cSCC/BCC, no histology or behaviour filter is applied | Full |
| myocardial_infarction | Myocardial infarction | Self-report, HES, Death | Zisou et al. 2026, Int J Epidemiol | Partial — see notes |
| myocardial_infarction_mu | Myocardial infarction | HES, Death | Mu et al. 2026, BMC Medicine | Full |
| myocardial_infarction_yun | Myocardial infarction | HES, HES (ICD-9) | Yun et al. 2026, eClinicalMedicine | Full |
| non_alcoholic_fatty_liver_disease | Non-alcoholic fatty liver disease | HES, Death | Zhang et al. 2026, Am J Epidemiol | Full |
| osteoarthritis | Osteoarthritis | Self-report, HES, HES (ICD-9) | Vazquez-Fernandez et al. 2026, BMC Medicine | Full |
| parkinsons | Parkinson’s disease | Algorithm | Vazquez-Fernandez et al. 2026, BMC Medicine | Full |
| psoriasis | Psoriasis | Self-report, First Occurrence | Self-report (p20002) matches the UKB code ‘psoriasis’ exactly | Full |
| pulmonary_embolism | Pulmonary embolism | First Occurrence | He et al. 2026, BMC Medicine | Partial — see notes |
| severe_asthma | Severe asthma | HES, HES (ICD-9), Death | Nyberg et al. 2025, Lancet Public Health | Full |
| stroke | Stroke | HES, Death | Zisou et al. 2026, Int J Epidemiol | Full |
| stroke_lu | Stroke | Self-report, HES, Death, First Occurrence | Lu et al. 2026, BMC Medicine | Full |
| stroke_mu | Stroke | HES, Death | Mu et al. 2026, BMC Medicine | Full |
| stroke_nyberg | Stroke | HES, HES (ICD-9), Death | Nyberg et al. 2025, Lancet Public Health | Full |
| stroke_qin | Stroke | HES, Death | Qin et al. 2025, BMC Medicine | Full |
| stroke_vazquez | Stroke | Algorithm | Vazquez-Fernandez et al. 2026, BMC Medicine | Full |
| stroke_yun | Stroke | HES, HES (ICD-9) | Yun et al. 2026, eClinicalMedicine | Full |
| type_1_diabetes | Type 1 diabetes | Self-report, HES, Death, First Occurrence | Lu et al. 2026, BMC Medicine | Full |
| type_2_diabetes | Type 2 diabetes | Self-report, HES, Death | Zhang et al. 2026, Eur J Epidemiol | Full |
| type_2_diabetes_chong | Type 2 diabetes | HES, GP (Read v2), GP (CTV3), Death | Chong et al. 2026, Diabetes Care | Full |
| type_2_diabetes_feng | Type 2 diabetes | Self-report, HES, Death | Feng et al. 2026, Diabetes Care | Partial — see notes |
| type_2_diabetes_lu | Type 2 diabetes | Self-report, HES, Death, First Occurrence | Lu et al. 2026, BMC Medicine | Full |
| type_2_diabetes_nyberg | Type 2 diabetes | HES, HES (ICD-9), Death | Nyberg et al. 2025, Lancet Public Health | Full |
| type_2_diabetes_thompson | Type 2 diabetes | HES, Death | Thompson et al. 2026, Lancet Regional Health - Europe | Full |
| type_2_diabetes_wirler | Type 2 diabetes | HES | Wirler et al. 2026, BMC Medicine | Partial — see notes |
| venous_thromboembolism | Venous thromboembolism | First Occurrence | He et al. 2026, BMC Medicine | Partial — see notes |
| ventricular_arrhythmias | Ventricular arrhythmias | HES, Death | Qin et al. 2025, BMC Medicine | Full |

67 phenotype recipes currently in the library. {.table}

*Coverage* is **Full** when every arm of the published definition is
executable in `ukbflow`, and **Partial** when one or more reported
components are documented in the recipe notes but are not executable.
See
[`vignette("phenotype-scope")`](https://evanbio.github.io/ukbflow/articles/phenotype-scope.md)
for the current support boundaries.

## Same Phenotype, Multiple Definitions

A deliberate feature of the library is **comparable duplicates**: the
same phenotype curated from different published studies, so their
definitions can be compared side by side. These appear as repeated
entries in the `Phenotype` column above.

``` r

dup <- names(which(table(catalog$Phenotype) > 1L))

for (ph in dup) {
  ids <- catalog$ID[catalog$Phenotype == ph]
  cat(sprintf("- %s: %s\n", ph, paste(ids, collapse = ", ")))
}
#> - All-cause dementia: dementia, dementia_algorithmic, dementia_vazquez, dementia_yiallourou
#> - Atrial fibrillation: atrial_fibrillation, atrial_fibrillation_qin
#> - Cancer: cancer, cancer_thompson, cancer_vazquez
#> - Cardiovascular disease: cardiovascular_disease, cardiovascular_disease_mu, cardiovascular_disease_thompson, cvd
#> - Cardiovascular disease mortality: cvd_mortality, cvd_mortality_yun
#> - Chronic kidney disease: chronic_kidney_disease, chronic_kidney_disease_lu
#> - Chronic obstructive pulmonary disease: copd, copd_chen, copd_vazquez
#> - Coronary heart disease: coronary_heart_disease, coronary_heart_disease_first_occurrence, coronary_heart_disease_nyberg, coronary_heart_disease_vazquez
#> - Heart failure: heart_failure, heart_failure_qin
#> - Myocardial infarction: myocardial_infarction, myocardial_infarction_mu, myocardial_infarction_yun
#> - Stroke: stroke, stroke_lu, stroke_mu, stroke_nyberg, stroke_qin, stroke_vazquez, stroke_yun
#> - Type 2 diabetes: type_2_diabetes, type_2_diabetes_chong, type_2_diabetes_feng, type_2_diabetes_lu, type_2_diabetes_nyberg, type_2_diabetes_thompson, type_2_diabetes_wirler
```

Comparing these entries with
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
/
[`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md)
exposes where published definitions of the “same” disease actually
diverge — the core motivation for the recipe library.

## Related Articles

- [`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md)
  covers how to browse and inspect recipes with the `recipe_*`
  functions, and how
  [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md)
  applies one to data.
- [`vignette("phenotype-scope")`](https://evanbio.github.io/ukbflow/articles/phenotype-scope.md)
  covers the data sources and code systems these recipes draw on, and
  their current limitations.
