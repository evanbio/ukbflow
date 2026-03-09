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
#' @param scenario (character) Data structure to generate:
#'   - `"cohort"`: wide participant-level table for the full
#'     `derive_*` → `assoc_*` → `plot_*` pipeline.
#'   - `"forest"`: association results table matching `assoc_coxph()` output,
#'     for testing `plot_forest()`. `n` = number of exposures (default 8).
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
  scenario <- match.arg(scenario, choices = c("cohort", "forest"))

  # Reason: sensible defaults differ by scenario — cohort needs many rows,
  # forest needs a small number of exposures
  if (missing(n)) n <- if (scenario == "cohort") 1000L else 8L
  n <- as.integer(n)

  if (n < 1L) stop("n must be a positive integer.", call. = FALSE)
  if (!is.null(seed)) set.seed(as.integer(seed))

  dt <- switch(scenario,
    cohort = .ops_toy_cohort(n),
    forest = .ops_toy_forest(n)
  )

  seed_info <- if (!is.null(seed)) paste0(" | seed = ", seed) else ""
  unit <- switch(scenario, cohort = "participants", forest = "rows")
  cli::cli_alert_success(
    "ops_toy: {nrow(dt)} {unit} | {ncol(dt)} columns | scenario = {.val {scenario}}{seed_info}"
  )

  dt
}


#' Summarise missing values by column
#'
#' Scans each column of a data.frame or data.table and returns the count and
#' percentage of missing values (NA or empty string `""`). Results are sorted
#' by missingness in descending order. Columns above 10\% are flagged in red;
#' those between 0\% and 10\% in yellow. A summary block is always printed
#' regardless of `threshold`.
#'
#' @param data A data.frame or data.table to scan.
#' @param threshold (numeric) Columns with `pct_na <= threshold` are silenced
#'   from the per-column CLI output. The summary block is always shown.
#'   Default `0`: every column with any missing value is listed.
#' @param verbose (logical) Print the CLI report. Default `TRUE`.
#'
#' @return An invisible data.table with columns `column`, `n_na`, and `pct_na`,
#'   sorted by `pct_na` descending. Always contains all columns regardless of
#'   `threshold` (which only affects CLI output).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dt <- ops_toy()
#'
#' # Show all columns with any missing value
#' ops_na(dt)
#'
#' # Only list columns with > 10% missing in the CLI output
#' ops_na(dt, threshold = 10)
#'
#' # Programmatic use — retrieve result silently
#' result <- ops_na(dt, verbose = FALSE)
#' result[pct_na > 50]
#' }
ops_na <- function(data, threshold = 0, verbose = TRUE) {

  # ── Validation ──────────────────────────────────────────────────────────────
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  }
  if (nrow(data) == 0L) {
    cli::cli_abort("{.arg data} has 0 rows.")
  }
  if (!is.numeric(threshold) || length(threshold) != 1L ||
      is.na(threshold) || threshold < 0 || threshold >= 100) {
    cli::cli_abort(
      "{.arg threshold} must be a single numeric value in [0, 100)."
    )
  }
  if (!is.logical(verbose) || length(verbose) != 1L || is.na(verbose)) {
    cli::cli_abort("{.arg verbose} must be a single logical value.")
  }

  n_row <- nrow(data)
  n_col <- ncol(data)
  dt    <- data.table::as.data.table(data)

  # ── Count NA + "" per column ──────────────────────────────────────────────
  # Reason: vapply over data.table columns is fast; is.character() guard avoids
  # unnecessary coercion overhead on numeric/integer/logical columns.
  n_na_vec <- vapply(dt, function(col) {
    sum(is.na(col) | (is.character(col) & !is.na(col) & col == ""))
  }, integer(1L))

  result <- data.table::data.table(
    column = names(n_na_vec),
    n_na   = n_na_vec,
    pct_na = round(n_na_vec / n_row * 100, 2)
  )
  data.table::setorder(result, -pct_na)

  # ── Summary counts (all columns, unaffected by threshold) ─────────────────
  n_high     <- sum(result$pct_na >= 10)
  n_mid      <- sum(result$pct_na > 0 & result$pct_na < 10)
  n_complete <- sum(result$pct_na == 0)

  # ── CLI output ─────────────────────────────────────────────────────────────
  if (verbose) {
    cli::cli_rule(left = "ops_na")
    cli::cli_inform(c(
      "i" = "{n_row} rows | {n_col} columns | threshold = {threshold}%"
    ))

    # Per-column lines: only for pct_na > threshold
    to_print <- result[pct_na > threshold]

    if (nrow(to_print) > 0L) {
      # Reason: pre-format widths so columns align neatly
      max_col_w <- max(nchar(to_print$column))
      max_n_w   <- nchar(as.character(n_row))

      for (i in seq_len(nrow(to_print))) {
        col_name <- formatC(to_print$column[i], width = max_col_w, flag = "-")
        n_str    <- formatC(to_print$n_na[i],   width = max_n_w,   format = "d")
        pct_str  <- formatC(to_print$pct_na[i], width = 6, format = "f", digits = 2)
        line     <- "{col_name}  {n_str} / {n_row}  ({pct_str}%)"

        if (to_print$pct_na[i] >= 10) {
          cli::cli_alert_danger(line)
        } else {
          cli::cli_alert_warning(line)
        }
      }
    }

    # Summary block — always shown
    cli::cli_rule()
    if (n_high > 0L) cli::cli_inform(c("x" = "{n_high} column{?s} \u2265 10% missing"))
    if (n_mid  > 0L) cli::cli_inform(c("!" = "{n_mid} column{?s} > 0% and < 10% missing"))
    cli::cli_inform(c("v" = "{n_complete} column{?s} complete (0% missing)"))
  }

  invisible(result)
}


#' Record and review dataset pipeline snapshots
#'
#' Captures a lightweight summary of a data.frame at a given pipeline stage
#' and stores it in the session cache. Subsequent calls automatically compute
#' deltas (Δ) against the previous snapshot, making it easy to track how data
#' changes through `derive_*`, `assoc_*`, and other processing steps.
#'
#' @param data A data.frame or data.table to snapshot. Pass `NULL` (or omit)
#'   to print the full snapshot history without recording a new entry.
#' @param label (character) A short name for this pipeline stage, e.g.
#'   `"raw"`, `"after_derive_missing"`. Defaults to `"snapshot_N"` where N
#'   is the sequential index.
#' @param reset (logical) If `TRUE`, clears the entire snapshot history and
#'   returns invisibly. Default `FALSE`.
#' @param verbose (logical) Print the CLI report. Default `TRUE`.
#'
#' @return When `data` is supplied, returns the new snapshot row invisibly
#'   (a one-row data.table). When called with no `data`, returns the full
#'   history data.table invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dt <- ops_toy()
#' ops_snapshot(dt, label = "raw")
#'
#' dt <- derive_missing(dt)
#' ops_snapshot(dt, label = "after_derive_missing")
#'
#' # View full history
#' ops_snapshot()
#'
#' # Reset history
#' ops_snapshot(reset = TRUE)
#' }
ops_snapshot <- function(data = NULL, label = NULL, reset = FALSE, verbose = TRUE) {

  # ── Validation ──────────────────────────────────────────────────────────────
  if (!is.logical(reset)  || length(reset)  != 1L || is.na(reset))
    cli::cli_abort("{.arg reset} must be a single logical value.")
  if (!is.logical(verbose) || length(verbose) != 1L || is.na(verbose))
    cli::cli_abort("{.arg verbose} must be a single logical value.")

  # ── Reset ───────────────────────────────────────────────────────────────────
  if (reset) {
    .ukbflow_cache$snapshots <- NULL
    if (verbose) cli::cli_alert_success("Snapshot history cleared.")
    return(invisible(NULL))
  }

  # ── View history (no data supplied) ─────────────────────────────────────────
  if (is.null(data)) {
    history <- .ukbflow_cache$snapshots
    if (is.null(history) || nrow(history) == 0L) {
      cli::cli_alert_warning("No snapshots recorded yet.")
      return(invisible(NULL))
    }
    if (verbose) {
      cli::cli_rule(left = "ops_snapshot history")
      print(history)
      cli::cli_rule()
    }
    return(invisible(history))
  }

  # ── Record new snapshot ──────────────────────────────────────────────────────
  if (!is.data.frame(data))
    cli::cli_abort("{.arg data} must be a data.frame or data.table.")
  if (!is.null(label) &&
      (!is.character(label) || length(label) != 1L || is.na(label) || !nzchar(label)))
    cli::cli_abort("{.arg label} must be a single non-empty character string.")

  history <- .ukbflow_cache$snapshots
  idx     <- if (is.null(history)) 1L else nrow(history) + 1L

  if (is.null(label)) label <- paste0("snapshot_", idx)

  # Reason: count NA + "" consistently with ops_na()
  dt_tmp   <- data.table::as.data.table(data)
  n_na_cols <- sum(vapply(dt_tmp, function(col) {
    any(is.na(col) | (is.character(col) & !is.na(col) & col == ""))
  }, logical(1L)))

  size_mb <- round(as.numeric(object.size(data)) / 1024^2, 2)

  new_row <- data.table::data.table(
    idx       = idx,
    label     = label,
    timestamp = format(Sys.time(), "%H:%M:%S"),
    nrow      = nrow(data),
    ncol      = ncol(data),
    n_na_cols = n_na_cols,
    size_mb   = size_mb
  )

  # Append to cache
  .ukbflow_cache$snapshots <- if (is.null(history)) {
    new_row
  } else {
    data.table::rbindlist(list(history, new_row))
  }

  # ── CLI output ───────────────────────────────────────────────────────────────
  if (verbose) {
    prev <- if (idx > 1L) history[nrow(history)] else NULL

    cli::cli_rule(left = "snapshot: {label}")

    .fmt_delta <- function(curr, prev_val, unit = "") {
      curr_str <- paste0(formatC(curr, format = "fg", big.mark = ","), unit)
      if (is.null(prev_val)) return(curr_str)
      delta <- curr - prev_val
      delta_str <- if (delta == 0) {
        "(= 0)"
      } else if (delta > 0) {
        paste0("(+", formatC(delta, format = "fg", big.mark = ","), unit, ")")
      } else {
        paste0("(", formatC(delta, format = "fg", big.mark = ","), unit, ")")
      }
      paste0(curr_str, "  ", delta_str)
    }

    s_row  <- .fmt_delta(nrow(data),  prev$nrow,      "")
    s_col  <- .fmt_delta(ncol(data),  prev$ncol,      "")
    s_na   <- .fmt_delta(n_na_cols,   prev$n_na_cols, "")
    s_size <- .fmt_delta(size_mb,     prev$size_mb,   " MB")

    # Reason: individual cli_inform calls avoid duplicate-key merging in cli
    cli::cli_inform("  rows      {s_row}")
    cli::cli_inform("  cols      {s_col}")
    cli::cli_inform("  NA cols   {s_na}")
    cli::cli_inform("  size      {s_size}")
    cli::cli_rule()
  }

  invisible(new_row)
}
