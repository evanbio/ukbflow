## CRAN Comments for ukbflow 0.3.2

Resubmission — addressing issues from the v0.3.1 pre-test check.

## Changes since v0.3.1

- Removed Unicode character `Δ` from `ops_snapshot()` documentation to fix
  LaTeX PDF manual build (WARNING + ERROR on Debian)
- Added `inst/WORDLIST` with `Biobank` to resolve spelling NOTE in DESCRIPTION
- Updated Codecov badge URL in README.md (301 → `app.codecov.io`)
- Replaced relative file URIs (`CONTRIBUTING.md`, `README_zh.md`) in README.md
  with full GitHub URLs
- Added `skip_on_cran()` to two `plot_tableone()` rendering tests that caused
  a 20-minute hang on Windows CRAN
- Freed `plot_forest()` and `plot_tableone()` examples from `\dontrun{}`
  (all examples use `save = FALSE`)
- Moved `broom` usage from undeclared to `@importFrom broom tidy` in
  `plot_tableone()` to resolve Imports NOTE

## Test environments

- Local Windows 11 x64 (build 26200), R 4.5.1
- GitHub Actions (ubuntu-latest): R-release, R-devel
- GitHub Actions (windows-latest): R-release
- GitHub Actions (macOS-latest): R-release

## R CMD check results

Duration: 6m 54.6s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## Downstream dependencies

There are currently no downstream dependencies for this package.
