# Contributing a phenotype recipe

The recipe library is the contributable core of ukbflow. A recipe is a
**read-only, versioned record** of how a UK Biobank phenotype was
operationally defined — its sources, codes, combination logic, and
caveats — so that an analysis can be reproduced, cited, and compared.

A recipe is **reference material, not an authority**. Each one is drawn
from a published study or carefully checked by the maintainer, but
neither guarantee rules out error, and a faithful reproduction of one
paper’s definition is not automatically the right definition for a
different research question. Using a recipe does not decide a case on
anyone’s behalf — the analyst is responsible for deciding whether a
given definition fits their study before applying it with
[`derive_recipe()`](https://evanbio.github.io/ukbflow/reference/derive_recipe.md).

Adding one is a **single YAML file** under `inst/extdata/recipes/` — no
code changes, no registration step.
[`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
discovers it automatically.

## Three ways to submit one

They all end at the same place: one YAML file, reviewed by a maintainer
before it joins the library. Pick whichever suits you; none is second
class.

**A form, if you would rather not touch YAML or git.** Open a [Recipe
submission](https://github.com/evanbio/ukbflow/issues/new?template=recipe_submission.yml)
issue and fill in the codes. A maintainer reads it, and when it is
accepted a pull request is generated from what you entered — you never
clone the repository. Rules the form cannot express (a cancer-registry
branch combining ICD-10 with histology and behaviour, most often) go in
its *Advanced* box as a YAML fragment. This is the intended route for
clinicians and epidemiologists contributing a definition from their own
work.

**[`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md),
if you already work in R.** Build the definition from plain arguments,
check it with [`print()`](https://rdrr.io/r/base/print.html), and write
the file — the schema is validated as you build, so a mistake is an
error message rather than a file that breaks later:

``` r

rec <- recipe_new(
  id      = "type_2_diabetes_chong",
  label   = "Type 2 diabetes",
  sources = list(
    hes      = recipe_rule(icd10 = c("E11", "E13"), match = "prefix"),
    gp_read2 = recipe_rule(read2 = c("C10F.", "C109."), match = "exact")
  ),
  notes = c("Provenance: Chong et al. 2025, Diabetologia, DOI 10.1007/....",
            "COVERAGE: the HbA1c threshold arm is not executable and is not applied.")
)
print(rec)
recipe_write(rec, "inst/extdata/recipes/type_2_diabetes_chong.yaml")
```

See
[`?recipe_new`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
for the per-slot argument reference: which fields each source accepts,
which take a bare vector, and which expand a vector into one rule per
element.

**The YAML file itself**, if you prefer to write it directly. That is
what the rest of this guide describes, and it stays fully supported —
the bundled library was written this way.

Generated files carry no comments: everything a reader needs goes in
`notes`, which is validated, returned by
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md),
shown by [`print()`](https://rdrr.io/r/base/print.html), and read by the
recipe catalogue. A hand-written file may use comments freely, and
[`recipe_write()`](https://evanbio.github.io/ukbflow/reference/recipe_write.md)
refuses to overwrite an existing file precisely so that commentary is
never silently discarded.

## 1. Copy the template

Copy
[`RECIPE_TEMPLATE.yaml`](https://evanbio.github.io/ukbflow/RECIPE_TEMPLATE.yaml)
to `inst/extdata/recipes/<your_id>.yaml`. Name the file after its `id`.

## 2. Fill the schema

### Header (all required except `short_label`, `description`)

| Field | Type | Notes |
|----|----|----|
| `id` | string | Non-empty, **globally unique**; the recipe key (matched, not the file name). Identifies one *definition*. |
| `label` | string | Human-readable **phenotype** name; the grouping key (see below). |
| `short_label` | string | Optional short/abbreviated name; describes the phenotype, not the variant. |
| `version` | integer | Bump on every change. |
| `created` | `YYYY-MM-DD` | Date the file was first authored. |
| `updated` | `YYYY-MM-DD` | Date of most recent change; bump with `version`. |
| `description` | text | Optional free-text summary of the definition. |

### `id` vs `label` — one phenotype, possibly several definitions

`id` identifies a **definition** and must be globally unique; `label`
names the **phenotype**. Two recipes that operationalise the *same*
phenotype from different sources (e.g. a different paper, or a raw-code
vs algorithmic definition) **share an identical `label`** and are told
apart by their `id`. That is what makes them a comparable pair —
grouping and side-by-side diffing key on `label`. Example: `dementia`
and `dementia_algorithmic` both carry `label: All-cause dementia`. Put
the variant distinction (which study, which method) in `id`,
`description`, and a `notes` item — **never** bake it into `label` or
`short_label`, or the two definitions will not group.

### Sources — a **fixed eleven-slot** schema

The keys are closed and map 1:1 to the `derive_*` functions. An unknown
slot is rejected. Each slot is a **list of rules** (each prefixed with
`-`); rules within a slot combine by **OR**. An unused slot is `[]`.

| Slot | derive function | Rule fields |
|----|----|----|
| `selfreport` | [`derive_selfreport()`](https://evanbio.github.io/ukbflow/reference/derive_selfreport.md) | `field` (`noncancer`/`cancer`), `regex` |
| `hes` | [`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md) | `icd10`, `match` (`prefix`/`exact`/`regex`), `position` (`any`/`main`) |
| `hes_icd9` | [`derive_hes_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_hes_icd9.md) | `icd9`, `match`, `position` — ICD-9 counterpart of `hes`. ICD-9 has no dotted format (unlike ICD-10): codes are written `"2500"`, not `"250.0"`; papers commonly quote ICD-9 in the conventional dotted textbook notation, so transcribe by stripping the dot |
| `opcs` | [`derive_opcs()`](https://evanbio.github.io/ukbflow/reference/derive_opcs.md) | `opcs`, `match`, `position` — OPCS-4 procedure codes on HES operative fields. Stored **dotted** like ICD-10 (`"K40"`, `"K23.4"`), so transcribe as written; a stated range like `K40-49` is expanded to explicit categories. HES-only — no cancer-registry / death / First Occurrence counterpart |
| `gp_read2` | [`derive_gp_read2()`](https://evanbio.github.io/ukbflow/reference/derive_gp_read2.md) | `read2`, `match` — Read v2 primary-care codes (gp_clinical `read_2`). 5-char dot-padded, **case-sensitive**; default `match: exact` (prefix is valid for Read v2’s positional hierarchy). Requires the `gp_clinical` table passed to `derive_recipe(gp = ...)` |
| `gp_ctv3` | [`derive_gp_ctv3()`](https://evanbio.github.io/ukbflow/reference/derive_gp_ctv3.md) | `ctv3`, `match` — CTV3 (Read v3) primary-care codes (gp_clinical `read_3`), the TPP counterpart of `read2`. CTV3 codes are opaque identifiers, so use `match: exact` (a shared prefix is not a hierarchy relationship, unlike Read v2) |
| `death` | [`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md) | `icd10`, `match`, `cause` (`any`/`primary`/`secondary`) |
| `first_occurrence` | [`derive_first_occurrence()`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md) | `field` (e.g. `131720`) |
| `cancer_registry` | [`derive_cancer_registry()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry.md) | `subtype`, `icd10`, `histology`, `behaviour` |
| `cancer_registry_icd9` | [`derive_cancer_registry_icd9()`](https://evanbio.github.io/ukbflow/reference/derive_cancer_registry_icd9.md) | `subtype`, `icd9`, `histology`, `behaviour` — ICD-9 counterpart of `cancer_registry`, sharing its histology/behaviour/date fields |
| `algorithm` | [`derive_algorithm()`](https://evanbio.github.io/ukbflow/reference/derive_algorithm.md) | `field` (UKB algorithmically-defined outcome, e.g. `42018`) |

`death` and `first_occurrence` have no ICD-9 counterpart: UK death
certification has used ICD-10 exclusively since 2001, and First
Occurrence fields are UKB’s own precomputed reconciliation across
multiple sources (already code-system-agnostic).

`position` (HES) and `cause` (death) record a definition’s
diagnosis-position and cause-of-death restrictions. Both are
**optional** and default to `any` (HES: any diagnosis position; death:
underlying or contributory cause). Set `position: main` to count only
the primary HES diagnosis, or `cause: primary` to count only the
underlying cause of death — matching the corresponding
[`derive_hes()`](https://evanbio.github.io/ukbflow/reference/derive_hes.md)
/
[`derive_death_registry()`](https://evanbio.github.io/ukbflow/reference/derive_death_registry.md)
arguments. When a study’s restriction was previously captured only in a
`note`, prefer the field.

### Logic (closed vocabulary; absent → documented defaults)

``` yaml
logic:
  case: any        # any | all       (any = positive in any source, OR)
  date: earliest   # earliest | latest
```

### Notes — one atomic caveat per item

Reproduction gotchas: code-format quirks, position/instance semantics,
deliberate code specificity, etc.

## 3. Document what ukbflow cannot execute — honestly

This is where recipes earn their keep. If the published definition uses
a source ukbflow’s `derive_*` functions cannot run, **do not silently
drop it** — record it in `notes` with the full code list, and add a
`COVERAGE` note stating which arms are executed and which are
documentation-only. With the primary-care Read v2 / CTV3 slots in place,
almost every standard UKB source is now executable via the slots above,
so a documentation-only arm is uncommon (it usually means a bespoke or
expert-consensus definition with no reproducible code list). See
`type_2_diabetes_feng.yaml` for a worked example. A recipe that
under-represents a definition is worse than one that is transparent
about its limits.

**Do not guess a code list from a single illustrative example.** Some
papers give one example code under a phrase like “or equivalent ICD-9
codes (e.g., 250.00)” without stating the full set. Inferring a rule
(say, prefix-matching bare `250`) from one example risks under- or
over-ascertainment relative to what the study actually did. When the
source does not specify a code list precisely enough to reproduce, leave
the corresponding slot empty and record the example in `notes` instead —
see `type_2_diabetes_wirler.yaml`. This is different from a range the
paper states explicitly (e.g. “441.1-441.9” or “ICD-9 code 250” as the
complete definition, as in `stroke_nyberg.yaml`), which *should* be
encoded as an executable rule even if you have to write it as a regex
range rather than an itemised list.

## 4. Validate locally

``` r

devtools::load_all()          # make the new file discoverable
recipe_get("<your_id>")       # hard schema validation + pretty print
recipe_sources("<your_id>")   # flattened rule table — eyeball the codes
```

[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md)
**fails hard** on an unknown id or a malformed recipe.
[`recipe_list()`](https://evanbio.github.io/ukbflow/reference/recipe_list.md)
only warns and skips, so always validate with
[`recipe_get()`](https://evanbio.github.io/ukbflow/reference/recipe_get.md).

## 5. Run the tests

``` r

devtools::test(filter = "recipe")
```

Every bundled recipe is checked against the schema, so a malformed
contribution fails fast.

## 6. Open a pull request

Against `main`. The PR template includes a recipe checklist.

A pull request that touches nothing but `inst/extdata/recipes/` runs
`recipe-check` alone — the schema, id-uniqueness and round-trip tests.
It does not run the six-platform `R-CMD-check` matrix, because a recipe
is a data file and cannot change package behaviour. Adding an R file to
the same pull request brings the full matrix back.

------------------------------------------------------------------------

## Rules of thumb

- **Sources are fixed to the eleven slots.** Each is a *list of rules*
  (note the leading `-`); an unused slot is `[]`. A bare mapping without
  the `-` is a single rule, not a list, and is rejected.
- **`logic` uses a closed vocabulary**: `case` is `any`/`all`, `date` is
  `earliest`/`latest`.
- **Model on an existing recipe** of a similar shape —
  `atopic_dermatitis` (self-report + First Occurrence), `cscc`
  (self-report + cancer registry with histology/behaviour), `dementia`
  (HES ICD-10/ICD-9 + primary-care Read v2/CTV3).
- **Every rule is checked, however the file was written.** A rule may
  only use the fields its slot allows, must carry the one that defines
  it, and must keep `match`, `position` and `cause` inside their
  vocabularies. A misspelled code field (`icd_10` for `icd10`) is
  rejected rather than ignored — silently ignoring it would leave the
  slot with no codes at all.
- **Let
  [`recipe_new()`](https://evanbio.github.io/ukbflow/reference/recipe_new.md)
  write the file** if any of this feels fiddly. It fills the eleven
  slots, orders the fields, keeps all-digit ICD-9 codes as text, and
  applies the same checks while you build rather than when you load.

## Recipe PR checklist

File named after its `id`, placed in `inst/extdata/recipes/`.

Header complete; `version`, `created`, `updated` present.

Only the eleven fixed source slots used; unused slots are `[]`.

Codes verified against the cited source; provenance in `notes`.

Any non-executable source arms recorded in `notes`, not dropped.

`recipe_get("<id>")` loads without error.

`devtools::test(filter = "recipe")` passes.
