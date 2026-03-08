# Contributing to ukbflow

Thanks for your interest in contributing!

## Bug reports

Open an [issue](https://github.com/evanbio/ukbflow/issues) with a
minimal reproducible example:

``` r
reprex::reprex()
sessionInfo()
packageVersion("ukbflow")
```

## Feature requests

Open an issue describing the use case and proposed API.

## Pull requests

1.  Fork the repo and create a feature branch from `main`
2.  Make your changes, add tests, update roxygen2 docs
3.  Run `devtools::check()` — 0 errors, 0 warnings expected
4.  Submit a PR against `main`

## Development setup

``` r
devtools::load_all()
devtools::test()
devtools::document()
devtools::check()
```

## Questions

Open an issue or email <evanzhou.bio@gmail.com>.
