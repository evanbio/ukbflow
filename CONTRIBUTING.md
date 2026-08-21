# Contributing to ukbflow

Thanks for your interest in contributing! There are **two distinct
ways** to contribute, with different workflows:

|  | Code contribution | Recipe contribution |
|----|----|----|
| You change | `R/` + tests + roxygen2 docs | one `inst/extdata/recipes/*.yaml` file |
| Bar to clear | `devtools::check()` — 0 errors, 0 warnings | `recipe_get("<id>")` loads + tests pass |
| Reviewed for | API design, correctness | code provenance, honest caveats, coverage notes |

If you are adding a **phenotype recipe**, follow the dedicated guide:
**[CONTRIBUTING_RECIPE.md](https://evanbio.github.io/ukbflow/CONTRIBUTING_RECIPE.md)**.
The rest of this document covers code, bugs, and feature requests.

## Bug reports

Open a [bug
report](https://github.com/evanbio/ukbflow/issues/new/choose) with a
minimal reproducible example:

``` r

reprex::reprex()
sessionInfo()
packageVersion("ukbflow")
```

## Feature requests

Open a [feature
request](https://github.com/evanbio/ukbflow/issues/new/choose)
describing the use case and the proposed API.

## Code pull requests

1.  Fork the repo and create a feature branch from `main`.
2.  Make your changes, add tests, and update roxygen2 docs.
3.  Run `devtools::document()` so `man/` and `NAMESPACE` stay in sync.
4.  Run `devtools::check()` — 0 errors, 0 warnings expected.
5.  Open a PR against `main`.

## Development setup

``` r

devtools::load_all()
devtools::test()
devtools::document()
devtools::check()
```

## Questions

Open an issue or email <evanzhou.bio@gmail.com>.
