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
| HES inpatient diagnoses | `41270` with dates from `41280` | ICD-10 any-position diagnosis field | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) | Treats any matching ICD-10 code in `41270` as a case; primary / secondary diagnosis position is not currently configurable |
| First Occurrence | `p131xxx` date fields | UKB precomputed first occurrence fields | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) | Uses the supplied First Occurrence date field as an event source |
| Cancer registry | `40006`, `40011`, `40012`, `40005` | ICD-10, histology, behaviour, diagnosis date | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) | Supports ICD-10 matching with optional histology and behaviour filters |
| Death registry | `40001`, `40002`, `40000` | ICD-10 primary / secondary cause of death | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) | Searches primary and secondary death-cause fields and returns status plus death date |
| Multi-source ICD-10 phenotype | HES, First Occurrence, cancer registry, death registry | ICD-10-derived sources | [`derive_icd10()`](https://evanbio.github.io/ukbflow/reference/derive_icd10.md) | Combines selected source-specific helpers into one ICD-10-derived status and earliest date |
| Final case definition | Self-report plus ICD-10-derived status/date | Source reconciliation | [`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md) | Uses an any-source OR rule by default: self-report or ICD-10-derived status can define a case |

## Default Reconciliation

[`derive_case()`](https://evanbio.github.io/ukbflow/reference/derive_case.md)
applies an any-source reconciliation rule by default. The final status
is `TRUE` if either the ICD-10-derived status or the self-report status
is `TRUE`. The final date is the earliest available date across included
sources.

This default is a workflow convention, not a medical-record confirmation
rule. For stricter case definitions, users should construct
source-specific phenotypes explicitly, for example by using an
ICD-10-derived `name` without matching self-report columns, or by
controlling the sources passed to `derive_icd10(source = ...)`.

## Not Currently Supported

The following code systems and source types are not part of the current
public API:

| Source or code system | Current status |
|----|----|
| ICD-9 | Not currently supported |
| OPCS-4 procedure codes | Not currently supported |
| Read v2 primary-care codes | Not currently supported |
| CTV3 primary-care codes | Not currently supported |
| General GP / primary-care phenotype parsing | Not currently supported |
| HES primary / secondary diagnosis-position selection | Not currently exposed as a public argument |

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
