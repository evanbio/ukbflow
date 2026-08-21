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
  returned `group` column: `"demographics"`, `"genetics"`,
  `"self_report"`, `"hes"`, `"opcs"`, `"death"`, `"cancer_registry"`,
  `"lifestyle"`, `"early_life"`, `"family_history"`, `"reproductive"`,
  `"blood_count"`, `"blood_biochemistry"`, or `"nmr"`.

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

## Details

Most groups are hand-picked selections. The three assay panels are not:
they carry every field of their UK Biobank Showcase category, and are
therefore complete references for it.

- `"blood_count"`:

  All 31 haematology measures of category 100081 (field IDs
  `30000`-`30300` in steps of 10, each instanced 0-2).

- `"blood_biochemistry"`:

  All 30 serum and plasma assays of category 17518 (field IDs
  `30600`-`30890` in steps of 10, each instanced 0-1). The four urine
  assays sit in a separate category and are not included.

- `"nmr"`:

  All 249 Nightingale NMR metabolomics biomarkers of category 220 (field
  IDs `23400`-`23648`, each instanced 0-1). Each `description` names the
  measurement unit and the Showcase biomarker group, neither of which
  can be read off the title, and for a lipoprotein subclass the particle
  diameter that defines it.

Titles are verbatim from the RAP field list, including UK Biobank's own
`"Neutrophill"` / `"Eosinophill"` / `"Basophill"` spelling, so searching
for the correctly spelled `"eosinophil"` matches on the description
instead.

The full table is always returned; `group` and `pattern` only subset it.
Console output reports what came back – one line per group for an
unfiltered call, a single line otherwise – and is independent of how the
returned `data.table` prints.

## Examples

``` r
ops_fields_common()
#> 
#> ── ukbflow common fields ───────────────────────────────────────────────────────
#> demographics: 8
#> genetics: 6
#> self_report: 7
#> hes: 8
#> opcs: 4
#> death: 3
#> cancer_registry: 5
#> lifestyle: 8
#> early_life: 2
#> family_history: 3
#> reproductive: 9
#> blood_count: 31
#> blood_biochemistry: 30
#> nmr: 249
#> total: 373
#>      field_id                                                      title
#>         <int>                                                     <char>
#>   1:       31                                                        Sex
#>   2:       34                                              Year of birth
#>   3:       53                        Date of attending assessment centre
#>   4:       54                               UK Biobank assessment centre
#>   5:    21022                                         Age at recruitment
#>  ---                                                                    
#> 369:    23644      Phospholipids to Total Lipids in Small HDL percentage
#> 370:    23645        Cholesterol to Total Lipids in Small HDL percentage
#> 371:    23646 Cholesteryl Esters to Total Lipids in Small HDL percentage
#> 372:    23647   Free Cholesterol to Total Lipids in Small HDL percentage
#> 373:    23648      Triglycerides to Total Lipids in Small HDL percentage
#>                                                                                                           description
#>                                                                                                                <char>
#>   1:                                                                                                 Participant sex.
#>   2:                                                                                       Participant year of birth.
#>   3:                                                                                           Assessment visit date.
#>   4:                                                                   Assessment centre attended by the participant.
#>   5:                                                                                              Age at recruitment.
#>  ---                                                                                                                 
#> 369:            Phospholipids as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 370:              Cholesterol as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 371:       Cholesteryl esters as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 372: Unesterified cholesterol as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 373:            Triglycerides as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#>             group structure
#>            <char>    <char>
#>   1: demographics    single
#>   2: demographics    single
#>   3: demographics  instance
#>   4: demographics  instance
#>   5: demographics    single
#>  ---                       
#> 369:          nmr  instance
#> 370:          nmr  instance
#> 371:          nmr  instance
#> 372:          nmr  instance
#> 373:          nmr  instance
ops_fields_common("sex")
#> ✔ ops_fields_common: 3 fields matching "sex".
#>    field_id       title                            description
#>       <int>      <char>                                 <char>
#> 1:       31         Sex                       Participant sex.
#> 2:    22001 Genetic sex        Genetic sex from genotype data.
#> 3:    30830        SHBG Sex hormone-binding globulin (nmol/L).
#>                 group structure
#>                <char>    <char>
#> 1:       demographics    single
#> 2:           genetics    single
#> 3: blood_biochemistry  instance
ops_fields_common(group = "genetics")
#> ✔ ops_fields_common: 6 fields in group "genetics".
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
ops_fields_common(group = "blood_count")
#> ✔ ops_fields_common: 31 fields in group "blood_count".
#>     field_id                                           title
#>        <int>                                          <char>
#>  1:    30000              White blood cell (leukocyte) count
#>  2:    30010              Red blood cell (erythrocyte) count
#>  3:    30020                       Haemoglobin concentration
#>  4:    30030                          Haematocrit percentage
#>  5:    30040                         Mean corpuscular volume
#>  6:    30050                    Mean corpuscular haemoglobin
#>  7:    30060      Mean corpuscular haemoglobin concentration
#>  8:    30070 Red blood cell (erythrocyte) distribution width
#>  9:    30080                                  Platelet count
#> 10:    30090                                   Platelet crit
#> 11:    30100              Mean platelet (thrombocyte) volume
#> 12:    30110                     Platelet distribution width
#> 13:    30120                                Lymphocyte count
#> 14:    30130                                  Monocyte count
#> 15:    30140                               Neutrophill count
#> 16:    30150                               Eosinophill count
#> 17:    30160                                 Basophill count
#> 18:    30170                  Nucleated red blood cell count
#> 19:    30180                           Lymphocyte percentage
#> 20:    30190                             Monocyte percentage
#> 21:    30200                          Neutrophill percentage
#> 22:    30210                          Eosinophill percentage
#> 23:    30220                            Basophill percentage
#> 24:    30230             Nucleated red blood cell percentage
#> 25:    30240                         Reticulocyte percentage
#> 26:    30250                              Reticulocyte count
#> 27:    30260                        Mean reticulocyte volume
#> 28:    30270                        Mean sphered cell volume
#> 29:    30280                  Immature reticulocyte fraction
#> 30:    30290      High light scatter reticulocyte percentage
#> 31:    30300           High light scatter reticulocyte count
#>     field_id                                           title
#>        <int>                                          <char>
#>                                                                    description
#>                                                                         <char>
#>  1:                           Total white blood cell count (10^9 cells/Litre).
#>  2:                            Total red blood cell count (10^12 cells/Litre).
#>  3:                Haemoglobin concentration in whole blood (grams/decilitre).
#>  4:           Packed red cell volume as a percentage of whole blood (percent).
#>  5:                             Mean volume of a red blood cell (femtolitres).
#>  6:                   Mean mass of haemoglobin per red blood cell (picograms).
#>  7: Mean haemoglobin concentration per unit red cell volume (grams/decilitre).
#>  8:             Variability in red blood cell size, or anisocytosis (percent).
#>  9:                                   Total platelet count (10^9 cells/Litre).
#> 10:                  Platelet volume as a percentage of whole blood (percent).
#> 11:                                   Mean volume of a platelet (femtolitres).
#> 12:                                    Variability in platelet size (percent).
#> 13:                              Absolute lymphocyte count (10^9 cells/Litre).
#> 14:                                Absolute monocyte count (10^9 cells/Litre).
#> 15:                              Absolute neutrophil count (10^9 cells/Litre).
#> 16:                              Absolute eosinophil count (10^9 cells/Litre).
#> 17:                                Absolute basophil count (10^9 cells/Litre).
#> 18:                Absolute nucleated red blood cell count (10^9 cells/Litre).
#> 19:                Lymphocytes as a percentage of white blood cells (percent).
#> 20:                  Monocytes as a percentage of white blood cells (percent).
#> 21:                Neutrophils as a percentage of white blood cells (percent).
#> 22:                Eosinophils as a percentage of white blood cells (percent).
#> 23:                  Basophils as a percentage of white blood cells (percent).
#> 24:    Nucleated red blood cells as a percentage of red blood cells (percent).
#> 25:                Reticulocytes as a percentage of red blood cells (percent).
#> 26:                           Absolute reticulocyte count (10^12 cells/Litre).
#> 27:                               Mean volume of a reticulocyte (femtolitres).
#> 28:          Mean volume of osmotically sphered red blood cells (femtolitres).
#> 29:                     Proportion of reticulocytes that are immature (ratio).
#> 30:   Least mature reticulocytes as a percentage of red blood cells (percent).
#> 31:      Absolute count of the least mature reticulocytes (10^12 cells/Litre).
#>                                                                    description
#>                                                                         <char>
#>           group structure
#>          <char>    <char>
#>  1: blood_count  instance
#>  2: blood_count  instance
#>  3: blood_count  instance
#>  4: blood_count  instance
#>  5: blood_count  instance
#>  6: blood_count  instance
#>  7: blood_count  instance
#>  8: blood_count  instance
#>  9: blood_count  instance
#> 10: blood_count  instance
#> 11: blood_count  instance
#> 12: blood_count  instance
#> 13: blood_count  instance
#> 14: blood_count  instance
#> 15: blood_count  instance
#> 16: blood_count  instance
#> 17: blood_count  instance
#> 18: blood_count  instance
#> 19: blood_count  instance
#> 20: blood_count  instance
#> 21: blood_count  instance
#> 22: blood_count  instance
#> 23: blood_count  instance
#> 24: blood_count  instance
#> 25: blood_count  instance
#> 26: blood_count  instance
#> 27: blood_count  instance
#> 28: blood_count  instance
#> 29: blood_count  instance
#> 30: blood_count  instance
#> 31: blood_count  instance
#>           group structure
#>          <char>    <char>
ops_fields_common(group = "blood_biochemistry")
#> ✔ ops_fields_common: 30 fields in group "blood_biochemistry".
#>     field_id                        title
#>        <int>                       <char>
#>  1:    30600                      Albumin
#>  2:    30610         Alkaline phosphatase
#>  3:    30620     Alanine aminotransferase
#>  4:    30630             Apolipoprotein A
#>  5:    30640             Apolipoprotein B
#>  6:    30650   Aspartate aminotransferase
#>  7:    30660             Direct bilirubin
#>  8:    30670                         Urea
#>  9:    30680                      Calcium
#> 10:    30690                  Cholesterol
#> 11:    30700                   Creatinine
#> 12:    30710           C-reactive protein
#> 13:    30720                   Cystatin C
#> 14:    30730    Gamma glutamyltransferase
#> 15:    30740                      Glucose
#> 16:    30750 Glycated haemoglobin (HbA1c)
#> 17:    30760              HDL cholesterol
#> 18:    30770                        IGF-1
#> 19:    30780                   LDL direct
#> 20:    30790                Lipoprotein A
#> 21:    30800                   Oestradiol
#> 22:    30810                    Phosphate
#> 23:    30820            Rheumatoid factor
#> 24:    30830                         SHBG
#> 25:    30840              Total bilirubin
#> 26:    30850                 Testosterone
#> 27:    30860                Total protein
#> 28:    30870                Triglycerides
#> 29:    30880                        Urate
#> 30:    30890                    Vitamin D
#>     field_id                        title
#>        <int>                       <char>
#>                                                                            description
#>                                                                                 <char>
#>  1:                             Serum albumin, the most abundant plasma protein (g/L).
#>  2:                               Alkaline phosphatase, a liver and bone enzyme (U/L).
#>  3:                             Alanine aminotransferase or ALT, a liver enzyme (U/L).
#>  4:                       Apolipoprotein A1, the main structural protein of HDL (g/L).
#>  5:                              Apolipoprotein B, one per atherogenic particle (g/L).
#>  6:                Aspartate aminotransferase or AST, a liver and muscle enzyme (U/L).
#>  7:                                                     Conjugated bilirubin (umol/L).
#>  8:                                   Blood urea, a marker of renal function (mmol/L).
#>  9:                                                            Serum calcium (mmol/L).
#> 10:                                                  Total serum cholesterol (mmol/L).
#> 11:                           Serum creatinine, a marker of renal filtration (umol/L).
#> 12:              C-reactive protein or CRP, an acute-phase inflammation marker (mg/L).
#> 13:           Cystatin C, a renal filtration marker independent of muscle mass (mg/L).
#> 14:    Gamma glutamyltransferase or GGT, a biliary and alcohol-sensitive enzyme (U/L).
#> 15:                          Serum glucose, non-fasting in most participants (mmol/L).
#> 16: Glycated haemoglobin or HbA1c, mean glycaemia over two to three months (mmol/mol).
#> 17:                                     High-density lipoprotein cholesterol (mmol/L).
#> 18:                                             Insulin-like growth factor 1 (nmol/L).
#> 19:                   Low-density lipoprotein cholesterol, measured directly (mmol/L).
#> 20:    Lipoprotein(a), a largely genetically determined atherogenic particle (nmol/L).
#> 21:                                                         Serum oestradiol (pmol/L).
#> 22:                                                          Serum phosphate (mmol/L).
#> 23:                                        Rheumatoid factor, an autoantibody (IU/ml).
#> 24:                                             Sex hormone-binding globulin (nmol/L).
#> 25:                             Total bilirubin, conjugated and unconjugated (umol/L).
#> 26:                                                       Serum testosterone (nmol/L).
#> 27:                                                         Total serum protein (g/L).
#> 28:                                                      Serum triglycerides (mmol/L).
#> 29:                                                              Serum urate (umol/L).
#> 30:                                                      25-hydroxyvitamin D (nmol/L).
#>                                                                            description
#>                                                                                 <char>
#>                  group structure
#>                 <char>    <char>
#>  1: blood_biochemistry  instance
#>  2: blood_biochemistry  instance
#>  3: blood_biochemistry  instance
#>  4: blood_biochemistry  instance
#>  5: blood_biochemistry  instance
#>  6: blood_biochemistry  instance
#>  7: blood_biochemistry  instance
#>  8: blood_biochemistry  instance
#>  9: blood_biochemistry  instance
#> 10: blood_biochemistry  instance
#> 11: blood_biochemistry  instance
#> 12: blood_biochemistry  instance
#> 13: blood_biochemistry  instance
#> 14: blood_biochemistry  instance
#> 15: blood_biochemistry  instance
#> 16: blood_biochemistry  instance
#> 17: blood_biochemistry  instance
#> 18: blood_biochemistry  instance
#> 19: blood_biochemistry  instance
#> 20: blood_biochemistry  instance
#> 21: blood_biochemistry  instance
#> 22: blood_biochemistry  instance
#> 23: blood_biochemistry  instance
#> 24: blood_biochemistry  instance
#> 25: blood_biochemistry  instance
#> 26: blood_biochemistry  instance
#> 27: blood_biochemistry  instance
#> 28: blood_biochemistry  instance
#> 29: blood_biochemistry  instance
#> 30: blood_biochemistry  instance
#>                  group structure
#>                 <char>    <char>
ops_fields_common(group = "nmr")
#> ✔ ops_fields_common: 249 fields in group "nmr".
#>      field_id                                                      title
#>         <int>                                                     <char>
#>   1:    23400                                          Total Cholesterol
#>   2:    23401                              Total Cholesterol Minus HDL-C
#>   3:    23402        Remnant Cholesterol (Non-HDL, Non-LDL -Cholesterol)
#>   4:    23403                                           VLDL Cholesterol
#>   5:    23404                                   Clinical LDL Cholesterol
#>  ---                                                                    
#> 245:    23644      Phospholipids to Total Lipids in Small HDL percentage
#> 246:    23645        Cholesterol to Total Lipids in Small HDL percentage
#> 247:    23646 Cholesteryl Esters to Total Lipids in Small HDL percentage
#> 248:    23647   Free Cholesterol to Total Lipids in Small HDL percentage
#> 249:    23648      Triglycerides to Total Lipids in Small HDL percentage
#>                                                                                                           description
#>                                                                                                                <char>
#>   1:                                              Cholesterol across all lipoprotein particles (Cholesterol, mmol/l).
#>   2:                              Non-HDL cholesterol: total cholesterol less the HDL fraction (Cholesterol, mmol/l).
#>   3:                          Cholesterol in triglyceride-rich remnant particles, VLDL and IDL (Cholesterol, mmol/l).
#>   4:                                     Cholesterol in very low-density lipoprotein particles (Cholesterol, mmol/l).
#>   5:                                      LDL cholesterol as reported clinically, IDL included (Cholesterol, mmol/l).
#>  ---                                                                                                                 
#> 245:            Phospholipids as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 246:              Cholesterol as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 247:       Cholesteryl esters as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 248: Unesterified cholesterol as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 249:            Triglycerides as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#>       group structure
#>      <char>    <char>
#>   1:    nmr  instance
#>   2:    nmr  instance
#>   3:    nmr  instance
#>   4:    nmr  instance
#>   5:    nmr  instance
#>  ---                 
#> 245:    nmr  instance
#> 246:    nmr  instance
#> 247:    nmr  instance
#> 248:    nmr  instance
#> 249:    nmr  instance
ops_fields_common("eosinophill")
#> ✔ ops_fields_common: 2 fields matching "eosinophill".
#>    field_id                  title
#>       <int>                 <char>
#> 1:    30150      Eosinophill count
#> 2:    30210 Eosinophill percentage
#>                                                    description       group
#>                                                         <char>      <char>
#> 1:               Absolute eosinophil count (10^9 cells/Litre). blood_count
#> 2: Eosinophils as a percentage of white blood cells (percent). blood_count
#>    structure
#>       <char>
#> 1:  instance
#> 2:  instance
ops_fields_common("cholesterol")
#> ✔ ops_fields_common: 71 fields matching "cholesterol".
#>     field_id
#>        <int>
#>  1:    30690
#>  2:    30760
#>  3:    30780
#>  4:    23400
#>  5:    23401
#>  6:    23402
#>  7:    23403
#>  8:    23404
#>  9:    23405
#> 10:    23406
#> 11:    23415
#> 12:    23419
#> 13:    23420
#> 14:    23421
#> 15:    23422
#> 16:    23484
#> 17:    23486
#> 18:    23491
#> 19:    23493
#> 20:    23498
#> 21:    23500
#> 22:    23505
#> 23:    23507
#> 24:    23512
#> 25:    23514
#> 26:    23519
#> 27:    23521
#> 28:    23526
#> 29:    23528
#> 30:    23533
#> 31:    23535
#> 32:    23540
#> 33:    23542
#> 34:    23547
#> 35:    23549
#> 36:    23554
#> 37:    23556
#> 38:    23561
#> 39:    23563
#> 40:    23568
#> 41:    23570
#> 42:    23575
#> 43:    23577
#> 44:    23580
#> 45:    23582
#> 46:    23585
#> 47:    23587
#> 48:    23590
#> 49:    23592
#> 50:    23595
#> 51:    23597
#> 52:    23600
#> 53:    23602
#> 54:    23605
#> 55:    23607
#> 56:    23610
#> 57:    23612
#> 58:    23615
#> 59:    23617
#> 60:    23620
#> 61:    23622
#> 62:    23625
#> 63:    23627
#> 64:    23630
#> 65:    23632
#> 66:    23635
#> 67:    23637
#> 68:    23640
#> 69:    23642
#> 70:    23645
#> 71:    23647
#>     field_id
#>        <int>
#>                                                                                    title
#>                                                                                   <char>
#>  1:                                                                          Cholesterol
#>  2:                                                                      HDL cholesterol
#>  3:                                                                           LDL direct
#>  4:                                                                    Total Cholesterol
#>  5:                                                        Total Cholesterol Minus HDL-C
#>  6:                                  Remnant Cholesterol (Non-HDL, Non-LDL -Cholesterol)
#>  7:                                                                     VLDL Cholesterol
#>  8:                                                             Clinical LDL Cholesterol
#>  9:                                                                      LDL Cholesterol
#> 10:                                                                      HDL Cholesterol
#> 11:                                                         Total Esterified Cholesterol
#> 12:                                                               Total Free Cholesterol
#> 13:                                                             Free Cholesterol in VLDL
#> 14:                                                              Free Cholesterol in LDL
#> 15:                                                              Free Cholesterol in HDL
#> 16:                                 Cholesterol in Chylomicrons and Extremely Large VLDL
#> 17:                            Free Cholesterol in Chylomicrons and Extremely Large VLDL
#> 18:                                                       Cholesterol in Very Large VLDL
#> 19:                                                  Free Cholesterol in Very Large VLDL
#> 20:                                                            Cholesterol in Large VLDL
#> 21:                                                       Free Cholesterol in Large VLDL
#> 22:                                                           Cholesterol in Medium VLDL
#> 23:                                                      Free Cholesterol in Medium VLDL
#> 24:                                                            Cholesterol in Small VLDL
#> 25:                                                       Free Cholesterol in Small VLDL
#> 26:                                                       Cholesterol in Very Small VLDL
#> 27:                                                  Free Cholesterol in Very Small VLDL
#> 28:                                                                   Cholesterol in IDL
#> 29:                                                              Free Cholesterol in IDL
#> 30:                                                             Cholesterol in Large LDL
#> 31:                                                        Free Cholesterol in Large LDL
#> 32:                                                            Cholesterol in Medium LDL
#> 33:                                                       Free Cholesterol in Medium LDL
#> 34:                                                             Cholesterol in Small LDL
#> 35:                                                        Free Cholesterol in Small LDL
#> 36:                                                        Cholesterol in Very Large HDL
#> 37:                                                   Free Cholesterol in Very Large HDL
#> 38:                                                             Cholesterol in Large HDL
#> 39:                                                        Free Cholesterol in Large HDL
#> 40:                                                            Cholesterol in Medium HDL
#> 41:                                                       Free Cholesterol in Medium HDL
#> 42:                                                             Cholesterol in Small HDL
#> 43:                                                        Free Cholesterol in Small HDL
#> 44:      Cholesterol to Total Lipids in Chylomicrons and Extremely Large VLDL percentage
#> 45: Free Cholesterol to Total Lipids in Chylomicrons and Extremely Large VLDL percentage
#> 46:                            Cholesterol to Total Lipids in Very Large VLDL percentage
#> 47:                       Free Cholesterol to Total Lipids in Very Large VLDL percentage
#> 48:                                 Cholesterol to Total Lipids in Large VLDL percentage
#> 49:                            Free Cholesterol to Total Lipids in Large VLDL percentage
#> 50:                                Cholesterol to Total Lipids in Medium VLDL percentage
#> 51:                           Free Cholesterol to Total Lipids in Medium VLDL percentage
#> 52:                                 Cholesterol to Total Lipids in Small VLDL percentage
#> 53:                            Free Cholesterol to Total Lipids in Small VLDL percentage
#> 54:                            Cholesterol to Total Lipids in Very Small VLDL percentage
#> 55:                       Free Cholesterol to Total Lipids in Very Small VLDL percentage
#> 56:                                        Cholesterol to Total Lipids in IDL percentage
#> 57:                                   Free Cholesterol to Total Lipids in IDL percentage
#> 58:                                  Cholesterol to Total Lipids in Large LDL percentage
#> 59:                             Free Cholesterol to Total Lipids in Large LDL percentage
#> 60:                                 Cholesterol to Total Lipids in Medium LDL percentage
#> 61:                            Free Cholesterol to Total Lipids in Medium LDL percentage
#> 62:                                  Cholesterol to Total Lipids in Small LDL percentage
#> 63:                             Free Cholesterol to Total Lipids in Small LDL percentage
#> 64:                             Cholesterol to Total Lipids in Very Large HDL percentage
#> 65:                        Free Cholesterol to Total Lipids in Very Large HDL percentage
#> 66:                                  Cholesterol to Total Lipids in Large HDL percentage
#> 67:                             Free Cholesterol to Total Lipids in Large HDL percentage
#> 68:                                 Cholesterol to Total Lipids in Medium HDL percentage
#> 69:                            Free Cholesterol to Total Lipids in Medium HDL percentage
#> 70:                                  Cholesterol to Total Lipids in Small HDL percentage
#> 71:                             Free Cholesterol to Total Lipids in Small HDL percentage
#>                                                                                    title
#>                                                                                   <char>
#>                                                                                                                                      description
#>                                                                                                                                           <char>
#>  1:                                                                                                            Total serum cholesterol (mmol/L).
#>  2:                                                                                               High-density lipoprotein cholesterol (mmol/L).
#>  3:                                                                             Low-density lipoprotein cholesterol, measured directly (mmol/L).
#>  4:                                                                          Cholesterol across all lipoprotein particles (Cholesterol, mmol/l).
#>  5:                                                          Non-HDL cholesterol: total cholesterol less the HDL fraction (Cholesterol, mmol/l).
#>  6:                                                      Cholesterol in triglyceride-rich remnant particles, VLDL and IDL (Cholesterol, mmol/l).
#>  7:                                                                 Cholesterol in very low-density lipoprotein particles (Cholesterol, mmol/l).
#>  8:                                                                  LDL cholesterol as reported clinically, IDL included (Cholesterol, mmol/l).
#>  9:                                                                      Cholesterol in low-density lipoprotein particles (Cholesterol, mmol/l).
#> 10:                                                                     Cholesterol in high-density lipoprotein particles (Cholesterol, mmol/l).
#> 11:                                                        Esterified cholesterol across all lipoprotein particles (Cholesteryl esters, mmol/l).
#> 12:                                                        Unesterified cholesterol across all lipoprotein particles (Free cholesterol, mmol/l).
#> 13:                                                        Unesterified cholesterol in very low-density lipoproteins (Free cholesterol, mmol/l).
#> 14:                                                             Unesterified cholesterol in low-density lipoproteins (Free cholesterol, mmol/l).
#> 15:                                                            Unesterified cholesterol in high-density lipoproteins (Free cholesterol, mmol/l).
#> 16:                                              Cholesterol, chylomicrons and extremely large VLDL from 75 nm (Lipoprotein subclasses, mmol/l).
#> 17:                                 Unesterified cholesterol, chylomicrons and extremely large VLDL from 75 nm (Lipoprotein subclasses, mmol/l).
#> 18:                                                        Cholesterol, very large VLDL of mean diameter 64 nm (Lipoprotein subclasses, mmol/l).
#> 19:                                           Unesterified cholesterol, very large VLDL of mean diameter 64 nm (Lipoprotein subclasses, mmol/l).
#> 20:                                                           Cholesterol, large VLDL of mean diameter 53.6 nm (Lipoprotein subclasses, mmol/l).
#> 21:                                              Unesterified cholesterol, large VLDL of mean diameter 53.6 nm (Lipoprotein subclasses, mmol/l).
#> 22:                                                          Cholesterol, medium VLDL of mean diameter 44.5 nm (Lipoprotein subclasses, mmol/l).
#> 23:                                             Unesterified cholesterol, medium VLDL of mean diameter 44.5 nm (Lipoprotein subclasses, mmol/l).
#> 24:                                                           Cholesterol, small VLDL of mean diameter 36.8 nm (Lipoprotein subclasses, mmol/l).
#> 25:                                              Unesterified cholesterol, small VLDL of mean diameter 36.8 nm (Lipoprotein subclasses, mmol/l).
#> 26:                                                      Cholesterol, very small VLDL of mean diameter 31.3 nm (Lipoprotein subclasses, mmol/l).
#> 27:                                         Unesterified cholesterol, very small VLDL of mean diameter 31.3 nm (Lipoprotein subclasses, mmol/l).
#> 28:                                                                  Cholesterol, IDL of mean diameter 28.6 nm (Lipoprotein subclasses, mmol/l).
#> 29:                                                     Unesterified cholesterol, IDL of mean diameter 28.6 nm (Lipoprotein subclasses, mmol/l).
#> 30:                                                            Cholesterol, large LDL of mean diameter 25.5 nm (Lipoprotein subclasses, mmol/l).
#> 31:                                               Unesterified cholesterol, large LDL of mean diameter 25.5 nm (Lipoprotein subclasses, mmol/l).
#> 32:                                                             Cholesterol, medium LDL of mean diameter 23 nm (Lipoprotein subclasses, mmol/l).
#> 33:                                                Unesterified cholesterol, medium LDL of mean diameter 23 nm (Lipoprotein subclasses, mmol/l).
#> 34:                                                            Cholesterol, small LDL of mean diameter 18.7 nm (Lipoprotein subclasses, mmol/l).
#> 35:                                               Unesterified cholesterol, small LDL of mean diameter 18.7 nm (Lipoprotein subclasses, mmol/l).
#> 36:                                                       Cholesterol, very large HDL of mean diameter 14.3 nm (Lipoprotein subclasses, mmol/l).
#> 37:                                          Unesterified cholesterol, very large HDL of mean diameter 14.3 nm (Lipoprotein subclasses, mmol/l).
#> 38:                                                            Cholesterol, large HDL of mean diameter 12.1 nm (Lipoprotein subclasses, mmol/l).
#> 39:                                               Unesterified cholesterol, large HDL of mean diameter 12.1 nm (Lipoprotein subclasses, mmol/l).
#> 40:                                                           Cholesterol, medium HDL of mean diameter 10.9 nm (Lipoprotein subclasses, mmol/l).
#> 41:                                              Unesterified cholesterol, medium HDL of mean diameter 10.9 nm (Lipoprotein subclasses, mmol/l).
#> 42:                                                             Cholesterol, small HDL of mean diameter 8.7 nm (Lipoprotein subclasses, mmol/l).
#> 43:                                                Unesterified cholesterol, small HDL of mean diameter 8.7 nm (Lipoprotein subclasses, mmol/l).
#> 44:              Cholesterol as a share of lipids in chylomicrons and extremely large VLDL (Relative lipoprotein lipid concentrations, percent).
#> 45: Unesterified cholesterol as a share of lipids in chylomicrons and extremely large VLDL (Relative lipoprotein lipid concentrations, percent).
#> 46:                                    Cholesterol as a share of lipids in very large VLDL (Relative lipoprotein lipid concentrations, percent).
#> 47:                       Unesterified cholesterol as a share of lipids in very large VLDL (Relative lipoprotein lipid concentrations, percent).
#> 48:                                         Cholesterol as a share of lipids in large VLDL (Relative lipoprotein lipid concentrations, percent).
#> 49:                            Unesterified cholesterol as a share of lipids in large VLDL (Relative lipoprotein lipid concentrations, percent).
#> 50:                                        Cholesterol as a share of lipids in medium VLDL (Relative lipoprotein lipid concentrations, percent).
#> 51:                           Unesterified cholesterol as a share of lipids in medium VLDL (Relative lipoprotein lipid concentrations, percent).
#> 52:                                         Cholesterol as a share of lipids in small VLDL (Relative lipoprotein lipid concentrations, percent).
#> 53:                            Unesterified cholesterol as a share of lipids in small VLDL (Relative lipoprotein lipid concentrations, percent).
#> 54:                                    Cholesterol as a share of lipids in very small VLDL (Relative lipoprotein lipid concentrations, percent).
#> 55:                       Unesterified cholesterol as a share of lipids in very small VLDL (Relative lipoprotein lipid concentrations, percent).
#> 56:                                                Cholesterol as a share of lipids in IDL (Relative lipoprotein lipid concentrations, percent).
#> 57:                                   Unesterified cholesterol as a share of lipids in IDL (Relative lipoprotein lipid concentrations, percent).
#> 58:                                          Cholesterol as a share of lipids in large LDL (Relative lipoprotein lipid concentrations, percent).
#> 59:                             Unesterified cholesterol as a share of lipids in large LDL (Relative lipoprotein lipid concentrations, percent).
#> 60:                                         Cholesterol as a share of lipids in medium LDL (Relative lipoprotein lipid concentrations, percent).
#> 61:                            Unesterified cholesterol as a share of lipids in medium LDL (Relative lipoprotein lipid concentrations, percent).
#> 62:                                          Cholesterol as a share of lipids in small LDL (Relative lipoprotein lipid concentrations, percent).
#> 63:                             Unesterified cholesterol as a share of lipids in small LDL (Relative lipoprotein lipid concentrations, percent).
#> 64:                                     Cholesterol as a share of lipids in very large HDL (Relative lipoprotein lipid concentrations, percent).
#> 65:                        Unesterified cholesterol as a share of lipids in very large HDL (Relative lipoprotein lipid concentrations, percent).
#> 66:                                          Cholesterol as a share of lipids in large HDL (Relative lipoprotein lipid concentrations, percent).
#> 67:                             Unesterified cholesterol as a share of lipids in large HDL (Relative lipoprotein lipid concentrations, percent).
#> 68:                                         Cholesterol as a share of lipids in medium HDL (Relative lipoprotein lipid concentrations, percent).
#> 69:                            Unesterified cholesterol as a share of lipids in medium HDL (Relative lipoprotein lipid concentrations, percent).
#> 70:                                          Cholesterol as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#> 71:                             Unesterified cholesterol as a share of lipids in small HDL (Relative lipoprotein lipid concentrations, percent).
#>                                                                                                                                      description
#>                                                                                                                                           <char>
#>                  group structure
#>                 <char>    <char>
#>  1: blood_biochemistry  instance
#>  2: blood_biochemistry  instance
#>  3: blood_biochemistry  instance
#>  4:                nmr  instance
#>  5:                nmr  instance
#>  6:                nmr  instance
#>  7:                nmr  instance
#>  8:                nmr  instance
#>  9:                nmr  instance
#> 10:                nmr  instance
#> 11:                nmr  instance
#> 12:                nmr  instance
#> 13:                nmr  instance
#> 14:                nmr  instance
#> 15:                nmr  instance
#> 16:                nmr  instance
#> 17:                nmr  instance
#> 18:                nmr  instance
#> 19:                nmr  instance
#> 20:                nmr  instance
#> 21:                nmr  instance
#> 22:                nmr  instance
#> 23:                nmr  instance
#> 24:                nmr  instance
#> 25:                nmr  instance
#> 26:                nmr  instance
#> 27:                nmr  instance
#> 28:                nmr  instance
#> 29:                nmr  instance
#> 30:                nmr  instance
#> 31:                nmr  instance
#> 32:                nmr  instance
#> 33:                nmr  instance
#> 34:                nmr  instance
#> 35:                nmr  instance
#> 36:                nmr  instance
#> 37:                nmr  instance
#> 38:                nmr  instance
#> 39:                nmr  instance
#> 40:                nmr  instance
#> 41:                nmr  instance
#> 42:                nmr  instance
#> 43:                nmr  instance
#> 44:                nmr  instance
#> 45:                nmr  instance
#> 46:                nmr  instance
#> 47:                nmr  instance
#> 48:                nmr  instance
#> 49:                nmr  instance
#> 50:                nmr  instance
#> 51:                nmr  instance
#> 52:                nmr  instance
#> 53:                nmr  instance
#> 54:                nmr  instance
#> 55:                nmr  instance
#> 56:                nmr  instance
#> 57:                nmr  instance
#> 58:                nmr  instance
#> 59:                nmr  instance
#> 60:                nmr  instance
#> 61:                nmr  instance
#> 62:                nmr  instance
#> 63:                nmr  instance
#> 64:                nmr  instance
#> 65:                nmr  instance
#> 66:                nmr  instance
#> 67:                nmr  instance
#> 68:                nmr  instance
#> 69:                nmr  instance
#> 70:                nmr  instance
#> 71:                nmr  instance
#>                  group structure
#>                 <char>    <char>
```
