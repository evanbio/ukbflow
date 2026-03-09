# =============================================================================
# zzz.R — Package startup and initialisation
# =============================================================================


# ── .onAttach ─────────────────────────────────────────────────────────────────

.onAttach <- function(libname, pkgname) {
  if (!interactive()) return()
  version <- utils::packageVersion(pkgname)

  # Reason: cli_inform() routes through message(), so users can suppress with
  # suppressPackageStartupMessages(). cli_text() uses cat() and cannot be suppressed.
  cli::cli_inform(c(
    "i" = "Welcome to {.pkg {pkgname}} v{version}",
    "i" = "Streamlined workflow for UK Biobank data analysis",
    "i" = "Run {.run ops_setup()} to check your environment"
  ))
}


# ── R CMD check — data.table NSE ──────────────────────────────────────────────

utils::globalVariables(c(".SD", ".N", ".I", ".GRP", ".BY", ".EACHI"))
