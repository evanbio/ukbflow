# =============================================================================
# zzz.R - Package startup and initialization
# =============================================================================

# Package Attach Hook
.onAttach <- function(libname, pkgname) {
  if (!interactive()) return()
  version <- utils::packageVersion(pkgname)

  cli::cli_text("Welcome to {.pkg {pkgname}} v{version}")
  cli::cli_text("Streamlined workflow for UK Biobank data analysis")
  cli::cli_text("See {.code ?ukbflow} for help")
}

# Silence R CMD check notes for data.table NSE
utils::globalVariables(c(".SD", ".N", ".I", ".GRP", ".BY", ".EACHI"))
