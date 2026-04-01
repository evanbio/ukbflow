## CRAN Comments for ukbflow 0.3.3

## Changes since v0.3.2

- Added `skip_if_not_installed("pROC")` guard to all `grs_validate()` logistic
  tests to ensure the suite passes cleanly when `pROC` is absent
- Removed hardcoded default paths across all modules; examples refactored to
  use `ops_toy()` data where possible — runnable examples unwrapped,
  long-running examples (>5s) wrapped in `\donttest{}`, network-dependent
  examples remain in `\dontrun{}`
- Corrected `VignetteBuilder` field in `DESCRIPTION`
- Rd files regenerated after example and parameter updates

## Test environments

- Local Windows 11 x64 (build 26200), R 4.5.1
- GitHub Actions (ubuntu-latest): R-release, R-devel
- GitHub Actions (windows-latest): R-release
- GitHub Actions (macOS-latest): R-release

## R CMD check results

Duration: 6m 33.6s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## R CMD check results (DEPENDS_ONLY — Suggests packages absent)

Duration: 3m 45.9s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## Downstream dependencies

There are currently no downstream dependencies for this package.
