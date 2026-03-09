# =============================================================================
# ops.R — Operational utilities for ukbflow
# =============================================================================


#' Check the ukbflow operating environment
#'
#' Runs a four-block health check covering the dx CLI, dxpy (Python), RAP
#' authentication, and R package dependencies. Designed to be the first
#' function a new user runs after installation.
#'
#' The function is **read-only**: it never modifies system state, installs
#' packages, or authenticates. Auth failures are reported as warnings, not
#' errors, because the check itself does not require a live RAP connection.
#'
#' @param check_dx   (logical) Check dx CLI installation (dxpy is implied by dx).
#' @param check_auth (logical) Check RAP login status.
#' @param check_deps (logical) Check R package dependencies.
#' @param verbose    (logical) Print the formatted report. Set to `FALSE` for
#'   programmatic use (results are still returned invisibly).
#'
#' @return An invisible named list with elements `dx`, `dxpy`, `auth`, `deps`,
#'   and `summary`. Each element reflects the result of its respective check
#'   block and can be inspected programmatically.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ops_setup()
#'
#' # Programmatic use — check if environment is ready
#' result <- ops_setup(verbose = FALSE)
#' result$summary$fail == 0
#' }
ops_setup <- function(
    check_dx   = TRUE,
    check_auth = TRUE,
    check_deps = TRUE,
    verbose    = TRUE
) {
  results <- list()

  r_ver <- paste0(R.version$major, ".", R.version$minor)

  if (verbose) {
    cli::cli_rule(left = "ukbflow environment check")
    cli::cli_inform(c(
      "i" = "ukbflow {utils::packageVersion('ukbflow')}  |  R {r_ver}  |  {Sys.Date()}"
    ))
  }

  # ── Block 1: dx-toolkit ───────────────────────────────────────────────────
  if (check_dx) {
    if (verbose) cli::cli_rule(left = "1. dx-toolkit")

    dx <- .ops_check_dx()
    results$dx <- dx

    if (verbose) {
      if (dx$ok) {
        # Reason: dx CLI is a dxpy entry point — if dx works, dxpy is present.
        cli::cli_alert_success("dx: {.path {dx$path}}  ({dx$version})")
      } else {
        cli::cli_alert_danger(
          "dx not found. Install dxpy: {.code pip install dxpy}"
        )
      }
    }
  }

  # ── Block 3: RAP authentication ───────────────────────────────────────────
  if (check_auth) {
    if (verbose) cli::cli_rule(left = "2. RAP authentication")

    auth <- .ops_check_auth()
    results$auth <- auth

    if (verbose) {
      if (auth$logged_in) {
        cli::cli_alert_success("user: {.val {auth$user}}")
        if (!is.na(auth$project)) {
          cli::cli_alert_success("project: {.val {auth$project}}")
        } else {
          cli::cli_alert_warning(
            "No project selected. Run {.fn auth_select_project}"
          )
        }
      } else if (!check_dx || results$dx$ok) {
        # Only warn about auth if dx itself is available
        cli::cli_alert_warning(
          "Not logged in. Run {.fn auth_login}"
        )
      } else {
        cli::cli_alert_warning("Skipped (dx not available).")
      }
    }
  }

  # ── Block 4: R package dependencies ──────────────────────────────────────
  if (check_deps) {
    if (verbose) cli::cli_rule(left = "3. R packages")

    deps <- .ops_check_deps()
    results$deps <- deps

    if (verbose) {
      for (d in deps) {
        if (d$installed) {
          cli::cli_alert_success(
            "{.pkg {d$package}}  {d$version}  [{d$group}]"
          )
        } else if (d$required) {
          cli::cli_alert_danger(
            "{.pkg {d$package}}  not installed  [{d$group}]"
          )
        } else {
          cli::cli_alert_warning(
            "{.pkg {d$package}}  not installed  [{d$group}] (optional)"
          )
        }
      }
    }
  }

  # ── Summary ───────────────────────────────────────────────────────────────
  n_pass <- 0L
  n_warn <- 0L
  n_fail <- 0L

  if (check_dx) {
    if (results$dx$ok) n_pass <- n_pass + 1L else n_fail <- n_fail + 1L
  }
  if (check_auth) {
    if (results$auth$logged_in) {
      n_pass <- n_pass + 1L
    } else {
      # Auth failure = warning, not a hard fail (tools may still be usable)
      n_warn <- n_warn + 1L
    }
  }
  if (check_deps) {
    for (d in results$deps) {
      if (d$installed) {
        n_pass <- n_pass + 1L
      } else if (d$required) {
        n_fail <- n_fail + 1L
      } else {
        n_warn <- n_warn + 1L
      }
    }
  }

  results$summary <- list(pass = n_pass, warn = n_warn, fail = n_fail)

  if (verbose) {
    cli::cli_rule()
    msg <- character(0)
    msg <- c(msg, "v" = "{n_pass} passed")
    if (n_warn > 0L) msg <- c(msg, "!" = "{n_warn} optional / warning")
    if (n_fail > 0L) msg <- c(msg, "x" = "{n_fail} required missing")
    cli::cli_inform(msg)

    # Suggest install command for missing required R packages
    if (check_deps && n_fail > 0L) {
      missing_pkgs <- Filter(
        function(d) !d$installed && d$required, results$deps
      )
      if (length(missing_pkgs) > 0L) {
        pkg_str <- paste0(
          '"', paste(vapply(missing_pkgs, `[[`, "", "package"), collapse = '", "'), '"'
        )
        cli::cli_inform(c(
          "i" = "Fix with: {.code install.packages(c({pkg_str}))}"
        ))
      }
    }
  }

  invisible(results)
}


#' Generate toy UKB-like data for testing and development
#'
#' Creates a small, synthetic dataset that mimics the structure of UK Biobank
#' phenotype data on the RAP. Useful for developing and testing `derive_*`,
#' `assoc_*`, and `plot_*` functions without requiring real UKB data access.
#'
#' This dataset is entirely synthetic. Column names follow RAP conventions
#' (e.g. `p41270`, `p20002_i0_a0`).
#'
#' @param scenario (character) Data structure to generate. Currently supports
#'   `"cohort"`: a wide participant-level table suitable for the full
#'   `derive_*` → `assoc_*` → `plot_*` pipeline.
#' @param n (integer) Number of participants. Default `1000L`.
#' @param seed (integer or NULL) Random seed for reproducibility. Pass `NULL`
#'   for a different dataset on every call. Default `42L`.
#'
#' @return A `data.table` with UKB-style column names. See Details for the
#'   columns included in each scenario.
#'
#' @details
#' ## scenario = "cohort"
#' Includes the following column groups:
#' - **Demographics**: `eid`, `p31`, `p34`, `p53_i0`, `p21022`
#' - **Covariates**: `p21001_i0`, `p20116_i0`, `p1558_i0`, `p21000_i0`,
#'   `p22189`, `p54_i0`
#' - **Genetic PCs**: `p22009_a1` – `p22009_a10`
#' - **Self-report disease**: `p20002_i0_a0–a4`, `p20008_i0_a0–a4`
#' - **HES**: `p41270` (JSON array), `p41280_a0–a9`
#' - **Cancer registry**: `p40006_i0`, `p40005_i0`
#' - **Death registry**: `p40001_i0`, `p40002_i0_a0–a1`, `p40000_i0`
#' - **First occurrence**: `p131742`
#' - **Messy columns**: `messy_allna`, `messy_empty`, `messy_label`
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dt <- ops_toy()
#' dt <- ops_toy(n = 500, seed = 1)
#'
#' # Dynamic dataset (different every call)
#' dt <- ops_toy(seed = NULL)
#'
#' # Feed directly into derive pipeline
#' dt <- ops_toy()
#' dt <- derive_missing(dt)
#' }
ops_toy <- function(
    scenario = "cohort",
    n        = 1000L,
    seed     = 42L
) {
  scenario <- match.arg(scenario, choices = "cohort")
  n        <- as.integer(n)

  if (n < 1L) stop("n must be a positive integer.", call. = FALSE)
  if (!is.null(seed)) set.seed(as.integer(seed))

  dt <- switch(scenario,
    cohort = .ops_toy_cohort(n)
  )

  seed_info <- if (!is.null(seed)) paste0(" | seed = ", seed) else ""
  cli::cli_alert_success(
    "ops_toy: {n} participants | {ncol(dt)} columns | scenario = {.val {scenario}}{seed_info}"
  )

  dt
}
