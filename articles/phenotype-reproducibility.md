# One Phenotype, Many Definitions: A Reproducibility and Comparability Case Study

## The problem

UK Biobank studies routinely report an outcome by name — “stroke”, “type
2 diabetes” — and describe how it was ascertained in a sentence or two,
or in a supplementary table. Yet when several studies define the *same*
named phenotype, their operational definitions frequently disagree:
which codes, which data sources, which matching rule, whether fatal
events count, whether self-report or primary-care records are included.
These choices are often implicit, scattered across supplements, or
simply not stated.

This creates a reproducibility and comparability problem with two
related forms:

- **Documented-but-divergent** — the definitions *are* written down
  (usually in supplementary tables), and they genuinely differ. The
  definition can be reproduced within its own study, but it is not
  interchangeable with the others; this is a cross-study comparability
  problem, not sloppy reporting.
- **Under-documented** — the definition cannot be recovered from the
  paper at all: a data source is named but its field/codes are not
  published, so even within-study reproduction is limited.

The distinction matters. Documented divergence does not necessarily
prevent within-study reproduction; instead, it prevents readers from
treating identically named outcomes as harmonised across studies.
Under-documentation is the stronger reproducibility failure, because the
original definition itself cannot be reconstructed.

This vignette works through both, using the bundled `recipe_*` library
as the evidence base. Everything here is computed offline from the
shipped recipe files — no UK Biobank data is accessed, and no published
result is recomputed. This case study does not reproduce published
findings. It demonstrates that **the same phenotype name can refer to
non-interchangeable definitions.**

> A recipe records *how a phenotype was operationally defined* — its
> sources, codes, matching rules, and caveats. A recipe may encode a
> fully reported definition, document an incomplete one, or include an
> explicitly labelled curator inference where the publication is
> under-specified. Recipes are read-only and versioned; see
> [`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md)
> for the schema and
> [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
> for applying one to data with
> [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md).

## Same name, different recipes: stroke

7 studies in the bundled library define a UK Biobank phenotype labelled
simply **“Stroke”**. The list is not hand-maintained: it is every recipe
carrying that label, so it stays current as recipes are added.
[`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
shows them side by side — same label, different `id`, different
provenance:

``` r

# every bundled recipe whose label is "Stroke"
recipe_list()[label == "Stroke", .(id, label, short_label)]
#> ✔ recipe_list: 67 recipes.
#>                id  label short_label
#>            <char> <char>      <char>
#> 1:         stroke Stroke      Stroke
#> 2:      stroke_lu Stroke      Stroke
#> 3:      stroke_mu Stroke      Stroke
#> 4:  stroke_nyberg Stroke      Stroke
#> 5:     stroke_qin Stroke      Stroke
#> 6: stroke_vazquez Stroke      Stroke
#> 7:     stroke_yun Stroke      Stroke
```

Each `id` traces to a specific publication. The citation shown is read
straight from the recipe’s own provenance note, not typed in here:

``` r

data.table(
  id     = stroke_ids,
  source = vapply(stroke_ids, provenance_of, character(1))
)
#>                id
#>            <char>
#> 1:         stroke
#> 2:      stroke_lu
#> 3:      stroke_mu
#> 4:  stroke_nyberg
#> 5:     stroke_qin
#> 6: stroke_vazquez
#> 7:     stroke_yun
#>                                                                                         source
#>                                                                                         <char>
#> 1:                                 Zisou et al. 2026, Int J Epidemiol, DOI 10.1093/ije/dyag014
#> 2:                                Lu et al. 2026, BMC Medicine, DOI 10.1186/s12916-026-04909-6
#> 3:                                Mu et al. 2026, BMC Medicine, DOI 10.1186/s12916-026-04701-6
#> 4: Nyberg et al. 2025, Lancet Public Health, DOI 10.1016/S2468-2667(24)00300-1 (PMID 39909687)
#> 5:                               Qin et al. 2025, BMC Medicine, DOI 10.1186/s12916-025-04546-5
#> 6:                 Vazquez-Fernandez et al. 2026, BMC Medicine, DOI 10.1186/s12916-026-05010-8
#> 7:        Yun et al. 2026, eClinicalMedicine, DOI 10.1016/j.eclinm.2026.103769 (PMID 41660364)
```

## Comparing the definitions

The comparison below is built directly from the recipe files with
[`recipe_sources()`](https://evanbio.github.io/ukbflow/reference/recipe_sources.md),
which flattens a recipe into one row per rule. For each stroke recipe we
extract the data sources it uses, its ICD-10 matching mode, whether it
includes ICD-9, and whether the code list reaches **I62** (other
non-traumatic intracranial haemorrhage) — a boundary on which the
studies openly disagree.

``` r

summarise_def <- function(id) {
  src <- suppressMessages(recipe_sources(id))

  icd10 <- unlist(strsplit(stats::na.omit(src$icd10), ","))
  icd9  <- unlist(strsplit(stats::na.omit(src$icd9),  ","))

  data.table(
    id         = id,
    sources    = paste(sort(unique(src$source)), collapse = " + "),
    icd10_match = paste(unique(stats::na.omit(src$match)), collapse = "/"),
    includes_I62 = any(grepl("^I62", icd10)),
    n_icd10_codes = length(unique(icd10)),
    icd9 = if (length(icd9)) paste(unique(icd9), collapse = ",") else "—"
  )
}

comparison <- rbindlist(lapply(stroke_ids, summarise_def))
comparison[]
#>                id                                     sources icd10_match
#>            <char>                                      <char>      <char>
#> 1:         stroke                                 death + hes      prefix
#> 2:      stroke_lu death + first_occurrence + hes + selfreport      prefix
#> 3:      stroke_mu                                 death + hes       exact
#> 4:  stroke_nyberg                      death + hes + hes_icd9      prefix
#> 5:     stroke_qin                                 death + hes      prefix
#> 6: stroke_vazquez                                   algorithm            
#> 7:     stroke_yun                              hes + hes_icd9      prefix
#>    includes_I62 n_icd10_codes                    icd9
#>          <lgcl>         <int>                  <char>
#> 1:        FALSE             4                       —
#> 2:         TRUE            32                       —
#> 3:        FALSE            35                       —
#> 4:        FALSE             4     430,431,433,434,436
#> 5:         TRUE             5                       —
#> 6:        FALSE             0                       —
#> 7:         TRUE             5 430,431,432,433,434,436
```

The table shows substantive differences among studies that describe the
outcome as “stroke” in UK Biobank:

- **Which data sources define a case differs.** Most use hospital
  inpatient (HES) plus death-registry ICD-10. `stroke_lu` adds baseline
  self-report and five First Occurrence fields. `stroke_yun` uses HES
  only. Within the coded sources represented by the recipe, this would
  not identify a fatal stroke recorded only in the death registry and
  never in an inpatient record. `stroke_vazquez` uses none of these
  codes: it takes the UK Biobank *algorithmically-defined* stroke
  outcome (field 42006), so its case set is whatever the UKB Outcomes
  Adjudication Group’s algorithm returns.
- **Whether I62 counts as stroke differs.** `stroke_lu`, `stroke_qin`,
  and `stroke_yun` include I62; `stroke`, `stroke_mu`, and
  `stroke_nyberg` do not.
- **The matching rule differs.** `stroke_mu` enumerates parent *and*
  child codes and matches them **exactly**; the others match by ICD-10
  **prefix**. Applied to the same records these can select different
  rows — an easily missed reproducibility trap.
- **The ICD-9 back-history differs.** `stroke_nyberg` adds ICD-9
  `430,431,433,434,436`; `stroke_yun` adds `430,431,432,433,434,436` —
  the same idea, but not the same code set (Yun also counts 432). The
  remaining recipes do not encode ICD-9, so earlier hospital history
  captured only through ICD-9 would not be included by those recipe
  definitions.

These differences are not necessarily errors. Many may reflect
defensible choices tied to each study’s design and research question —
and a reader who sees only “stroke (HES/death records)” in a methods
section cannot tell which one was used.

## What each difference does to *who* is a case

Because the definitions select different records, applied to the *same*
cohort they would classify different people as cases. Qualitatively:

| Divergence | Effect on the case set |
|----|----|
| Include vs. exclude I62 | Adds/removes intracranial-haemorrhage cases |
| HES-only vs. + death registry | HES-only drops fatal strokes never admitted |
| `exact` vs. `prefix` matching | Changes which boundary codes are captured |
| \+ self-report / First Occurrence | Adds earlier and self-reported cases |
| Code list vs. algorithm (42006) | A different case set entirely, set by UKB’s algorithm |
| ICD-9 included vs. not | Adds/omits pre-ICD-10 hospital history |

So the case count — and, more importantly, *which individuals* are cases
— depends on the definition, before any exposure or model enters the
picture.

## Why case counts (n) cannot simply be compared

It is tempting to line up the reported number of stroke cases across
these studies to quantify the effect of definition. That comparison is
**not clean**, and the recipe library makes clear why: each study also
applies its own cohort restrictions and exposure-specific sub-sampling
*before* the phenotype is even counted. Across these 7 papers the
analysed cohort ranges from roughly 80,000 to over 500,000 participants
— Vazquez-Fernandez works within a dietary sub-cohort, Lu within an
air-pollution sub-cohort, Mu within the accelerometry sub-sample, and so
on.

A difference in reported case counts therefore **conflates two things**
— a different base cohort and a different case definition — and cannot
be attributed to the phenotype definition alone. The supported
conclusion is qualitative: *these definitions do not select the same
cases, and their counts are not interchangeable.* (Exact per-study
figures would need to be read back from each paper against its stated
exclusions before being quoted.)

## A second phenotype: type 2 diabetes

Stroke diverges loudly because it has haemorrhagic/ischaemic subtypes
and a dedicated UKB algorithm. Does the problem disappear for a
“simpler” phenotype?

7 studies define **type 2 diabetes** — again selected by label, not by a
fixed id list — and here they *do* agree on the core code, ICD-10
**E11**, everywhere:

``` r

# every bundled recipe whose label is "Type 2 diabetes"
rbindlist(lapply(t2d_ids, summarise_def))[]
#>                          id                                     sources
#>                      <char>                                      <char>
#> 1:          type_2_diabetes                    death + hes + selfreport
#> 2:    type_2_diabetes_chong            death + gp_ctv3 + gp_read2 + hes
#> 3:     type_2_diabetes_feng                    death + hes + selfreport
#> 4:       type_2_diabetes_lu death + first_occurrence + hes + selfreport
#> 5:   type_2_diabetes_nyberg                      death + hes + hes_icd9
#> 6: type_2_diabetes_thompson                                 death + hes
#> 7:   type_2_diabetes_wirler                                         hes
#>     icd10_match includes_I62 n_icd10_codes   icd9
#>          <char>       <lgcl>         <int> <char>
#> 1:       prefix        FALSE             1      —
#> 2: prefix/exact        FALSE             1      —
#> 3:       prefix        FALSE             1      —
#> 4:       prefix        FALSE             1      —
#> 5:       prefix        FALSE             1    250
#> 6:       prefix        FALSE             1      —
#> 7:       prefix        FALSE             1      —
```

The agreement on E11 is real, but the definitions still diverge at the
edges — and, unlike stroke, part of the divergence is
**under-documentation** rather than documented choice:

- **Self-report** is included by some (`type_2_diabetes`,
  `type_2_diabetes_feng`) and not others — but the studies that use it
  **do not publish which UKB field or code** they used. The recipe
  records this as a reasonable inference (mapping to the p20002
  non-cancer-illness value), and flags it as such.
- **ICD-9** appears only in `type_2_diabetes_nyberg`.
  `type_2_diabetes_wirler` mentions ICD-9 but gives only a single
  illustrative example (“e.g., 250.00”), which is not a complete
  definition — so its recipe leaves the ICD-9 slot empty rather than
  fabricating one.
- **Primary care** (Read v2 / CTV3) is used by `type_2_diabetes_chong`
  and `type_2_diabetes_feng`. Those code lists exist (Chong’s run to 60+
  codes in a supplementary table), but **ukbflow cannot execute them** —
  there is no general-practice pipeline — so that arm cannot be
  reproduced by this tool at all.

Type 2 diabetes therefore shows the *other* face of the problem: even
where everyone agrees on the headline code, the reproducible definition
is incomplete, either because the paper never specified it or because it
depends on data arms no RAP-native tool currently covers.

## What the recipe library provides

The comparisons above were possible only because each definition is
written down once, in a fixed, machine-readable form. That is the point
of the `recipe_*` library:

- **Explicit about what is known** — each recipe records the reported
  sources, codes, and matching rules where available, while making
  inferred, incomplete, or unsupported components visible rather than
  silently filling them in. `recipe_get(id)` returns the whole
  definition, notes and all; `recipe_sources(id)` flattens the
  executable rules for comparison.
- **Versioned and citable** — recipes ship as YAML in
  `inst/extdata/recipes/*.yaml`, each with a version and provenance
  note, so a definition can be referenced exactly.
- **Contributable** — new recipes can be proposed by pull request; see
  `CONTRIBUTING_RECIPE.md` and `RECIPE_TEMPLATE.yaml`.

Reproducing one of these studies by hand means independently getting
every one of those choices right — sources, code lists, matching mode,
ICD-9 back-history, diagnosis position, follow-up window, prevalent-case
exclusion. A recipe collapses that to a single, inspectable object:

``` r

# The full Nyberg stroke definition, ready to inspect or apply
recipe_get("stroke_nyberg")
```

## In closing

Recipes do not impose a single “correct” definition of stroke or
diabetes. Their value is that they make the choice **inspectable,
reusable, and comparable**: a researcher can deliberately adopt a
published definition, modify it transparently, or run sensitivity
analyses across plausible alternatives. The library is therefore not a
phenotype ontology, and not a claim that any one definition is
universally preferred — it is a way to make the definitional choice
explicit and to see how much that choice matters.

## Session information

    #> R version 4.6.1 (2026-06-24)
    #> Platform: x86_64-pc-linux-gnu
    #> Running under: Ubuntu 24.04.4 LTS
    #> 
    #> Matrix products: default
    #> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    #> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    #> 
    #> locale:
    #>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    #>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    #>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    #> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    #> 
    #> time zone: UTC
    #> tzcode source: system (glibc)
    #> 
    #> attached base packages:
    #> [1] stats     graphics  grDevices utils     datasets  methods   base     
    #> 
    #> other attached packages:
    #> [1] data.table_1.18.4 ukbflow_0.4.0    
    #> 
    #> loaded via a namespace (and not attached):
    #>  [1] Matrix_1.7-5       gtable_0.3.6       jsonlite_2.0.0     dplyr_1.2.1       
    #>  [5] compiler_4.6.1     tidyselect_1.2.1   xml2_1.6.0         gtsummary_2.5.1   
    #>  [9] gridExtra_2.3.1    tidyr_1.3.2        jquerylib_0.1.4    splines_4.6.1     
    #> [13] systemfonts_1.3.2  textshaping_1.0.5  yaml_2.3.12        fastmap_1.2.0     
    #> [17] lattice_0.22-9     R6_2.6.1           generics_0.1.4     knitr_1.51        
    #> [21] htmlwidgets_1.6.4  backports_1.5.1    tibble_3.3.1       desc_1.4.3        
    #> [25] bslib_0.12.0       pillar_1.11.1      rlang_1.3.0        cachem_1.1.0      
    #> [29] broom_1.0.13       xfun_0.60          fs_2.1.0           sass_0.4.10       
    #> [33] otel_0.2.0         cli_3.6.6          pkgdown_2.2.1      magrittr_2.0.5    
    #> [37] digest_0.6.39      grid_4.6.1         lifecycle_1.0.5    forestploter_1.1.4
    #> [41] vctrs_0.7.3        evaluate_1.0.5     glue_1.8.1         ragg_1.5.2        
    #> [45] survival_3.8-6     gt_1.3.0           rmarkdown_2.31     purrr_1.2.2       
    #> [49] tools_4.6.1        pkgconfig_2.0.3    htmltools_0.5.9
