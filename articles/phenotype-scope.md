# Supported Phenotype Sources and Current Limitations

## Purpose

This scope note describes the phenotype sources currently supported by
`ukbflow`, the default reconciliation rules used by the
disease-derivation helpers, and the code systems that are outside the
current public API.

`ukbflow` provides workflow helpers for common UK Biobank phenotype
extraction and derivation tasks. It does not replace study-specific
phenotype validation, clinical case-definition decisions, or the UK
Biobank Showcase.

## Supported Sources

`ukbflow` currently focuses on common disease-phenotype sources that are
routinely available in UK Biobank phenotype extraction workflows.

| Source | UKB field(s) / structure | Code system or field type | Main function(s) | Current behavior |
|----|----|----|----|----|
| Self-reported illness | `20002` with corresponding report dates | UKB self-report coding | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) | Matches user-supplied labels / regex and returns status plus earliest report date |
| Self-reported cancer | `20001` with corresponding report dates | UKB self-report cancer coding | `derive_selfreport(field = "cancer")` | Matches user-supplied labels / regex and returns status plus earliest report date |
| HES inpatient diagnoses | `41270` / `41280` (any), `41202` / `41262` (main) | ICD-10 diagnosis fields | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) | Counts a matching ICD-10 code in any diagnosis position by default; `position = "main"` restricts to primary diagnoses. Secondary-only is not offered (UKB has no aligned date field for it) |
| HES inpatient diagnoses (ICD-9) | `41271` / `41281` (any), `41203` / `41263` (main) | ICD-9 diagnosis fields (legacy minority, mostly pre-1996 Scottish records) | [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) | Same matching / `position` semantics as [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md), on the parallel ICD-9 field pair. Secondary-only is not offered (UKB has no aligned date field for `41205` either) |
| HES inpatient procedures (OPCS-4) | `41272` / `41282` (any), `41200` / `41260` (main) | OPCS-4 operation / procedure fields | [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) | Same matching / `position` semantics as [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md), on the OPCS-4 operative field pair. OPCS-4 is stored dotted like ICD-10 (`K40`, `K23.4`). Secondary-only is not offered (`41210` has no aligned date field) |
| GP primary-care diagnoses (Read v2) | `gp_clinical` record table (field `42040`), `read_2` column | Read v2 primary-care codes | [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) | Matches a Read v2 code list against the `gp_clinical` long table (~118M rows, ~45% of the cohort; Read v2 = England Vision, Scotland, Wales). The table is fetched with [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md) and passed in as `gp` (loaded once, reused). Matches with hashed `%chin%`, `case-sensitive`; default `match = "exact"` (prefix is valid for Read v2’s positional hierarchy). UKB placeholder dates (Coding 819) count for status but supply no date |
| GP primary-care diagnoses (CTV3) | `gp_clinical` record table (field `42040`), `read_3` column | CTV3 (Read v3) primary-care codes | [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) | CTV3 counterpart of [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) (CTV3 = England TPP, the largest GP source). CTV3 codes are opaque identifiers, so `match = "exact"` is required — a shared prefix is not a hierarchy relationship, unlike Read v2 |
| First Occurrence | `p131xxx` date fields | UKB precomputed first occurrence fields | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) | Uses the supplied First Occurrence date field as an event source. No ICD-9 counterpart exists: UKB computes this field from multiple linked sources internally |
| Cancer registry | `40006`, `40011`, `40012`, `40005` | ICD-10, histology, behaviour, diagnosis date | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) | Supports ICD-10 matching with optional histology and behaviour filters |
| Cancer registry (ICD-9) | `40013` (code); shares `40011` / `40012` / `40005` with the ICD-10 arm | ICD-9 cancer-type code, plus the same histology / behaviour / diagnosis-date fields | [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) | Same histology / behaviour filtering as [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md). A registration instance carries a code in *either* `40006` or `40013`; instances are matched by registration number, not array position, so `40013`’s smaller instance range (UKB caps it lower than `40006`) does not cause a mismatch |
| Death registry | `40001`, `40002`, `40000` | ICD-10 primary / secondary cause of death | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) | Searches primary and secondary death-cause fields by default; `cause = "primary"` / `"secondary"` restricts to the underlying or contributory cause. Returns status plus death date. No ICD-9 counterpart exists: UK death certification has used ICD-10 exclusively since 2001 |
| Algorithmically-defined outcomes | `p420xx` date fields (Category 42) | UKB adjudicated outcome date fields | [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md) | Uses a UKB algorithmically-defined outcome date as an event source; filters the `1900-01-01` self-report sentinel to `NA`. No ICD-9 counterpart exists: an ADO already reconciles HES (both code systems), self-report, and death internally into one date field |
| Multi-source ICD-10 phenotype | HES, First Occurrence, cancer registry, death registry | ICD-10-derived sources | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) | Combines selected source-specific helpers into one ICD-10-derived status and earliest date |
| Multi-source ICD-9 phenotype | HES (ICD-9), cancer registry (ICD-9) | ICD-9-derived sources | [`derive_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_icd9.md) | Combines the two ICD-9-capable source helpers into one ICD-9-derived status and earliest date. Only two sources are offered (vs. four for [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md)), since death registry and First Occurrence have no ICD-9 counterpart in UKB |
| ICD-9 rules in bundled recipes | `hes_icd9` / `cancer_registry_icd9` recipe source slots, dispatching to [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) / [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) | Recipe-level ICD-9 | [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md) | The recipe schema supports ICD-9 rules exactly like the ICD-10 slots. A recipe’s ICD-9 codes are populated only where the published definition specifies them precisely enough to reproduce (e.g. `dementia`); where a paper only gives an illustrative example rather than a full code list, the recipe records that example in `notes` instead of guessing a rule (e.g. `type_2_diabetes_wirler`) |
| OPCS-4 rules in bundled recipes | `opcs` recipe source slot, dispatching to [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) | Recipe-level OPCS-4 | [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md) | The recipe schema supports an `opcs` slot like the diagnosis slots. Populated where a published definition specifies procedure codes precisely enough to reproduce (e.g. the coronary revascularisation arm of the `coronary_heart_disease` recipes) |
| GP rules in bundled recipes | `gp_read2` / `gp_ctv3` recipe source slots, dispatching to [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) / [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) | Recipe-level primary care | [`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md) | The recipe schema carries the Read v2 and CTV3 code lists as two separate slots (like ICD-10 vs ICD-9). A GP recipe requires the `gp_clinical` table to be passed to `derive_recipe(gp = ...)`; it errors early if absent. Populated where a paper gives explicit code lists (e.g. `dementia`, `type_2_diabetes_chong`) |
| Final case definition | Self-report plus ICD-10-derived plus optional ICD-9-, OPCS-4- and GP (Read v2 / CTV3)-derived status/date | Source reconciliation | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) | Uses an any-source OR rule by default: self-report, ICD-10-derived, ICD-9-derived, OPCS-4-derived, or GP-derived status can define a case. The optional ICD-9 (`icd9_col`), OPCS-4 (`opcs_col`) and GP (`read2_col` / `ctv3_col`) arms are folded in only when present — their absence is expected for most phenotypes and produces no warning |

## Default Reconciliation

[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
applies an any-source reconciliation rule by default. The final status
is `TRUE` if any of the ICD-10-derived, ICD-9-derived, OPCS-4-derived,
GP (Read v2 / CTV3)-derived, or self-report status is `TRUE`. The final
date is the earliest available date across included sources.

This default is a workflow convention, not a medical-record confirmation
rule. For stricter case definitions, users should construct
source-specific phenotypes explicitly, for example by using an
ICD-10-derived `name` without matching self-report columns, or by
controlling the sources passed to `derive_icd10(source = ...)` /
`derive_icd9(source = ...)`.

## Not Currently Supported

The following code systems and source types are not part of the current
public API:

| Source or code system | Current status |
|----|----|
| GP clinical diagnoses (Read v2 / CTV3) | Supported: fetch `gp_clinical` with [`extract_gp()`](https://evanbio.github.io/ukbflow/reference/extract_gp.md), then [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) / [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) |
| GP prescriptions (`gp_scripts`, BNF / dm+d codes) | Not currently supported |
| GP numeric measurement values (`value1`-`value3`) | Not currently supported |
| HES secondary-only diagnosis position (ICD-10 or ICD-9) | Not offered: UKB has no aligned date field for secondary diagnoses (`41204` / `41205`). Any-position (default) and `position = "main"` are supported |

These exclusions are intentional scope boundaries for the current
release. Users can still derive custom variables outside `ukbflow` and
then use
[`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md),
[`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md),
and the `assoc_*` functions once analysis-ready status and date columns
have been constructed.

## Design Principle

The phenotype helpers are intentionally explicit and source-aware.
`ukbflow` prioritizes tested helpers for common UKB sources over broad,
under-specified parsing of every possible clinical coding system.

For complex phenotypes, the recommended workflow is:

1.  Identify approved fields in the active RAP project.
2.  Extract the required fields with
    [`extract_batch()`](https://evanbio.github.io/ukbflow/reference/extract_batch.md)
    or related helpers.
3.  Use source-specific `derive_*` helpers where supported.
4.  Build custom status/date columns for sources outside the current
    public API.
5.  Use
    [`derive_timing()`](https://evanbio.github.io/ukbflow/reference/derive_timing.md)
    and
    [`derive_followup()`](https://evanbio.github.io/ukbflow/reference/derive_followup.md)
    to construct analysis-ready survival variables.
6.  Pass explicit covariates and model choices to the `assoc_*`
    functions.

## Related Articles

- [`vignette("derive")`](https://evanbio.github.io/ukbflow/articles/derive.md)
  covers disease phenotype derivation examples.
- [`vignette("derive-survival")`](https://evanbio.github.io/ukbflow/articles/derive-survival.md)
  covers timing, age at event, and follow-up.
- [`vignette("decode")`](https://evanbio.github.io/ukbflow/articles/decode.md)
  covers UKB column-name and value decoding.
- [`vignette("recipe")`](https://evanbio.github.io/ukbflow/articles/recipe.md)
  covers the library of reproducible phenotype definitions, which
  records definitions built from these same sources, and how to write
  one.
