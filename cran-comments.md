## CRAN Comments for ukbflow 0.3.4

## Changes since v0.3.3

This is a patch release to resolve the CHECK ERROR reported by CRAN on
2026-04-08 (r-devel-linux-x86_64-fedora-clang and fedora-gcc).

- All `test-integration-*.R` files now call `skip_on_cran()` at file scope
  before any data generation code. Integration tests use large simulated
  datasets (n = 2000) intended for local pre-release validation and are not
  suitable for automated CRAN checking.
- `RNGkind()` is now explicitly set before `set.seed()` in integration tests
  that simulate random data, ensuring cross-platform RNG reproducibility
  across R versions.

## Test environments

- Local Windows 11 x64 (build 26200), R 4.5.1
- GitHub Actions (ubuntu-latest): R-release, R-devel, R-oldrel
- GitHub Actions (windows-latest): R-release
- GitHub Actions (macOS-latest): R-release
- r-hub container `clang-asan`: Ubuntu 22.04, clang 22, R-devel r89803
- r-hub container `gcc-asan`: Fedora Linux 42, GCC 15, R-devel r89795

## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## R CMD check results (DEPENDS_ONLY — Suggests packages absent)

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

## Downstream dependencies

There are currently no downstream dependencies for this package.
