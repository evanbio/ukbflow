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
#' ops_setup(check_dx = FALSE, check_auth = FALSE)
#'
#' result <- ops_setup(check_dx = FALSE, check_auth = FALSE, verbose = FALSE)
#' result$summary$fail == 0
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

  # dx-toolkit
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

  # RAP authentication
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

  # R package dependencies
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
#'   - `"cohort"`: wide participant-level table with raw UKB field columns for
#'     the full `derive_*` → `assoc_*` → `plot_*` pipeline.
#'   - `"association"`: analysis-ready table with covariates already as factors,
#'     BMI/TDI binned, and two pre-derived disease outcomes (`dm_*`, `htn_*`)
#'     including status, date, timing, and follow-up columns. Use this for
#'     `assoc_*` examples and testing without running the derive pipeline.
#'   - `"forest"`: association results table matching `assoc_coxph()` output,
#'     for testing `plot_forest()`. `n` = number of exposures (default 8).
#' @param n (integer) Number of participants (or exposures for `"forest"`).
#'   Default `1000L` for `"cohort"`, `2000L` for `"association"`, `8L` for
#'   `"forest"`.
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
#' - **Self-report cancer**: `p20001_i0_a0–a4`, `p20006_i0_a0–a4`
#' - **HES**: `p41270` (JSON array), `p41280_a0–a8`
#' - **Cancer registry**: `p40006_i0–i2`, `p40011_i0–i2`, `p40012_i0–i2`,
#'   `p40005_i0–i2`
#' - **Death registry**: `p40001_i0`, `p40002_i0_a0–a2`, `p40000_i0`
#' - **First occurrence**: `p131742`
#' - **GRS**: `grs_bmi`, `grs_raw`, `grs_finngen`
#' - **Messy columns**: `messy_allna`, `messy_empty`, `messy_label`
#'
#' ## scenario = "association"
#' Analysis-ready table. All derive inputs (raw arrays, HES JSON, registry
#' fields) are omitted; derive outputs are pre-computed with internally
#' consistent relationships:
#' - **Demographics**: `eid`, `p31` (factor), `p53_i0` (IDate), `p21022`
#' - **Covariates**: `p21001_i0`, `bmi_cat` (factor, derived from `p21001_i0`),
#'   `p20116_i0` (factor), `p1558_i0` (factor), `p21000_i0` (factor),
#'   `p22189`, `tdi_cat` (factor, derived from `p22189` quartiles), `p54_i0`
#'   (factor)
#' - **Genetic PCs**: `p22009_a1` – `p22009_a10`
#' - **GRS**: `grs_bmi` (continuous exposure)
#' - **DM outcome**: `dm_status`, `dm_date`, `dm_timing`, `dm_followup_end`,
#'   `dm_followup_years` (type 2 diabetes, ~12% prevalence)
#' - **HTN outcome**: `htn_status`, `htn_date`, `htn_timing`,
#'   `htn_followup_end`, `htn_followup_years` (hypertension, ~28% prevalence)
#'
#' Internal relationships guaranteed:
#' - `bmi_cat` is cut from `p21001_i0` (breaks 18.5 / 25 / 30)
#' - `tdi_cat` is cut from `p22189` quartiles
#' - `dm_date` is `NA` iff `dm_status = FALSE`
#' - `dm_timing`: 0 = no disease, 1 = prevalent, 2 = incident, `NA` = no date
#' - `dm_followup_years` is `NA` for prevalent cases (`dm_timing == 1`)
#'
#' @export
#'
#' @examples
#' # cohort: raw UKB-style columns, feed into derive pipeline
#' dt <- ops_toy(n = 100)
#' dt <- derive_missing(dt)
#'
#' # association: analysis-ready, feed directly into assoc_* functions
#' dt <- ops_toy(scenario = "association", n = 500)
#' dt <- dt[dm_timing != 1L]   # exclude prevalent cases
#'
#' # forest: results table for plot_forest()
#' dt <- ops_toy(scenario = "forest")
ops_toy <- function(
    scenario = "cohort",
    n        = 1000L,
    seed     = 42L
) {
  scenario <- match.arg(scenario, choices = c("cohort", "association", "forest"))

  # Reason: sensible defaults differ by scenario
  if (missing(n)) {
    n <- switch(scenario,
      cohort      = 1000L,
      association = 2000L,
      forest      = 8L
    )
  }
  .assert_count_min(n, 1L)
  n <- as.integer(n)
  if (!is.null(seed)) set.seed(as.integer(seed))

  dt <- switch(scenario,
    cohort      = .ops_toy_cohort(n),
    association = .ops_toy_association(n),
    forest      = .ops_toy_forest(n)
  )

  seed_info <- if (!is.null(seed)) paste0(" | seed = ", seed) else ""
  unit <- if (scenario == "forest") "rows" else "participants"
  cli::cli_alert_success(
    "ops_toy: {nrow(dt)} {unit} | {ncol(dt)} columns | scenario = {.val {scenario}}{seed_info}"
  )

  dt
}


#' Summarise missing values by column
#'
#' Scans each column of a data.frame or data.table and returns the count and
#' percentage of missing values. Results are sorted by missingness in
#' descending order. Columns above 10\% are flagged in red; those between 0\%
#' and 10\% in yellow. A summary block is always printed regardless of
#' `threshold`.
#'
#' **Missing value definition**: a value is counted as missing if it is `NA`
#' *or* an empty string (`""`). Empty strings are treated as missing because
#' UKB exports frequently use `""` as a placeholder for absent text values.
#' This means `n_na` and `pct_na` reflect *effective* missingness, not just
#' `is.na()`. Numeric and logical columns are not affected (they cannot hold
#' `""`).
#'
#' @param data A data.frame or data.table to scan.
#' @param threshold (numeric) Columns with `pct_na <= threshold` are silenced
#'   from the per-column CLI output. The summary block is always shown.
#'   Default `0`: every column with any missing value is listed.
#' @param verbose (logical) Print the CLI report. Default `TRUE`.
#'
#' @return An invisible data.table with columns `column`, `n_na`, and `pct_na`,
#'   sorted by `pct_na` descending. `n_na` counts both `NA` and `""`.
#'   Always contains all columns regardless of `threshold` (which only affects
#'   CLI output).
#'
#' @export
#'
#' @examples
#' dt <- ops_toy(n = 100)
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
ops_na <- function(data, threshold = 0, verbose = TRUE) {

  # ── Validation ──────────────────────────────────────────────────────────────
  .assert_data_frame(data)
  if (nrow(data) == 0L)
    cli::cli_abort("{.arg data} has 0 rows.", call = NULL)
  if (!is.numeric(threshold) || length(threshold) != 1L ||
      is.na(threshold) || threshold < 0 || threshold >= 100)
    cli::cli_abort("{.arg threshold} must be a single numeric value in [0, 100).", call = NULL)
  .assert_flag(verbose)

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
#' deltas against the previous snapshot, making it easy to track how data
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
#' @param check_na (logical) Whether to count columns with any `NA` or blank
#'   string values and include the delta in the report. Set to `FALSE` to skip
#'   the NA scan (useful for large datasets or when NA tracking is not needed).
#'   Default `TRUE`.
#'
#' @return When `data` is supplied, returns the new snapshot row invisibly
#'   (a one-row data.table). When called with no `data`, returns the full
#'   history data.table invisibly.
#'
#' @export
#'
#' @examples
#' dt <- ops_toy(n = 100)
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
ops_snapshot <- function(data = NULL, label = NULL, reset = FALSE, verbose = TRUE,
                         check_na = TRUE) {

  # ── Validation ──────────────────────────────────────────────────────────────
  .assert_flag(reset)
  .assert_flag(verbose)
  .assert_flag(check_na)

  # ── Reset ───────────────────────────────────────────────────────────────────
  if (reset) {
    .ukbflow_cache$snapshots     <- NULL
    .ukbflow_cache$snapshot_cols <- NULL
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
  .assert_data_frame(data)
  if (!is.null(label)) .assert_scalar_string(label)

  history <- .ukbflow_cache$snapshots
  idx     <- if (is.null(history)) 1L else nrow(history) + 1L

  if (is.null(label)) label <- paste0("snapshot_", idx)

  # Reason: count NA + "" consistently with ops_na(); skippable via check_na = FALSE
  if (check_na) {
    dt_tmp    <- data.table::as.data.table(data)
    n_na_cols <- sum(vapply(dt_tmp, function(col) {
      any(is.na(col) | (is.character(col) & !is.na(col) & col == ""))
    }, logical(1L)))
  } else {
    n_na_cols <- NA_integer_
  }

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

  # Store column names separately (negligible overhead, enables diff/drop workflows)
  if (is.null(.ukbflow_cache$snapshot_cols)) .ukbflow_cache$snapshot_cols <- list()
  .ukbflow_cache$snapshot_cols[[label]] <- data.table::copy(colnames(data))

  # ── CLI output ───────────────────────────────────────────────────────────────
  if (verbose) {
    prev <- if (idx > 1L) history[nrow(history)] else NULL

    cli::cli_rule(left = "snapshot: {label}")

    .fmt_delta <- function(curr, prev_val, unit = "") {
      curr_str <- paste0(formatC(curr, format = "fg", big.mark = ","), unit)
      if (is.null(prev_val) || is.na(prev_val) || is.na(curr)) return(curr_str)
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
    s_na   <- if (check_na) .fmt_delta(n_na_cols, prev$n_na_cols, "") else "(skipped)"
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


#' Retrieve column names recorded at a snapshot
#'
#' Returns the column names stored by a previous \code{\link{ops_snapshot}}
#' call, optionally excluding columns you wish to keep.
#'
#' @param label (character) Snapshot label passed to \code{ops_snapshot()}.
#' @param keep (character or NULL) Column names to exclude from the returned
#'   vector (i.e. columns to retain in the data even if they were present at
#'   that snapshot). Default \code{NULL}.
#'
#' @return A character vector of column names.
#' @export
#'
#' @examples
#' dt <- ops_toy(n = 100)
#' ops_snapshot(dt, label = "raw")
#' ops_snapshot_cols("raw")
#' ops_snapshot_cols("raw", keep = "eid")
ops_snapshot_cols <- function(label, keep = NULL) {

  .assert_scalar_string(label)
  if (!is.null(keep)) .assert_character(keep)

  cols <- .ukbflow_cache$snapshot_cols[[label]]
  if (is.null(cols))
    cli::cli_abort("No snapshot found with label {.val {label}}.", call = NULL)

  # Always protect built-in safe cols + user-registered safe cols + explicit keep
  builtin_safe <- c("eid", "sex", "age", "age_at_recruitment")
  user_safe    <- .ukbflow_cache$safe_cols
  protected    <- unique(c(builtin_safe, user_safe, keep))

  setdiff(cols, protected)
}


#' Register additional safe columns protected from snapshot-based drops
#'
#' Adds column names to the session-level safe list. Columns in this list are
#' automatically excluded when \code{\link{ops_snapshot_cols}} is used to
#' build a drop vector, in addition to the built-in protected columns
#' (\code{"eid"}, \code{"sex"}, \code{"age"}, \code{"age_at_recruitment"}).
#'
#' @param cols (character) One or more column names to protect.
#' @param reset (logical) If \code{TRUE}, clear the current user-registered
#'   safe list before adding. Default \code{FALSE}.
#'
#' @return Invisibly returns the updated safe cols vector.
#' @export
#'
#' @examples
#' ops_set_safe_cols(c("date_baseline", "townsend_index"))
#' ops_set_safe_cols(reset = TRUE)  # clear user-registered safe cols
ops_set_safe_cols <- function(cols = NULL, reset = FALSE) {

  .assert_flag(reset)

  if (reset) {
    .ukbflow_cache$safe_cols <- NULL
    cli::cli_alert_success("User-registered safe cols cleared.")
  }

  if (!is.null(cols)) {
    if (!is.character(cols))
      cli::cli_abort("{.arg cols} must be a character vector.", call = NULL)
    .ukbflow_cache$safe_cols <- unique(c(.ukbflow_cache$safe_cols, cols))
    cli::cli_alert_success("Safe cols registered: {.val {cols}}")
  }

  invisible(.ukbflow_cache$safe_cols)
}


#' Remove raw source columns recorded at a snapshot
#'
#' Drops columns that were present at snapshot \code{from} from \code{data},
#' while automatically protecting built-in safe columns
#' (\code{"eid"}, \code{"sex"}, \code{"age"}, \code{"age_at_recruitment"}) and
#' any user-registered safe columns set via \code{\link{ops_set_safe_cols}}.
#' Columns that no longer exist in \code{data} are silently skipped.
#'
#' @param data A data.frame or data.table.
#' @param from (character) Label of the snapshot whose columns should be
#'   dropped (typically \code{"raw"}).
#' @param keep (character or NULL) Additional column names to protect beyond
#'   the built-in and user-registered safe cols. Default \code{NULL}.
#' @param verbose (logical) Print a summary of dropped columns. Default
#'   \code{TRUE}.
#'
#' @return A \code{data.table} with the specified columns removed. For
#'   \code{data.table} input the operation is performed by reference (in-place);
#'   for \code{data.frame} input the data is first converted to a new
#'   \code{data.table} — the original \code{data.frame} is not modified.
#' @export
#'
#' @examples
#' dt <- ops_toy(n = 100)
#' ops_snapshot(dt, label = "raw")
#' dt <- derive_missing(dt)
#' ops_snapshot(dt, label = "derived")
#' ops_snapshot_diff("raw", "derived")
#' dt <- ops_snapshot_remove(dt, from = "raw")
ops_snapshot_remove <- function(data, from, keep = NULL, verbose = TRUE) {

  .assert_data_frame(data)
  .assert_scalar_string(from)

  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  # Build protected set
  builtin_safe <- c("eid", "sex", "age", "age_at_recruitment")
  user_safe    <- .ukbflow_cache$safe_cols
  protected    <- unique(c(builtin_safe, user_safe, keep))

  # Columns to drop: in snapshot but not protected and still present in data
  snap_cols    <- ops_snapshot_cols(from, keep = keep)  # excludes built-in safe + user safe + keep
  cols_to_drop <- intersect(snap_cols, names(data))

  if (length(cols_to_drop) == 0L) {
    if (verbose) cli::cli_alert_info("ops_snapshot_remove: no columns to drop.")
    return(invisible(data))
  }

  data[, (cols_to_drop) := NULL]

  if (verbose) {
    cli::cli_alert_success(
      "ops_snapshot_remove: dropped {length(cols_to_drop)} raw column{?s}, {ncol(data)} remaining."
    )
  }

  invisible(data)
}


#' Compare column names between two snapshots
#'
#' Returns lists of columns added and removed between two recorded snapshots.
#'
#' @param label1 (character) Label of the earlier snapshot.
#' @param label2 (character) Label of the later snapshot.
#'
#' @return A named list with two character vectors: \code{added} (columns
#'   present in \code{label2} but not \code{label1}) and \code{removed}
#'   (columns present in \code{label1} but not \code{label2}).
#' @export
#'
#' @examples
#' dt <- ops_toy(n = 100)
#' ops_snapshot(dt, label = "raw")
#' dt <- derive_missing(dt)
#' ops_snapshot(dt, label = "derived")
#' ops_snapshot_diff("raw", "derived")
#' # $added   — newly derived columns
#' # $removed — columns dropped between snapshots
ops_snapshot_diff <- function(label1, label2) {

  .assert_scalar_string(label1)
  .assert_scalar_string(label2)

  cols1 <- .ukbflow_cache$snapshot_cols[[label1]]
  cols2 <- .ukbflow_cache$snapshot_cols[[label2]]

  if (is.null(cols1))
    cli::cli_abort("No snapshot found with label {.val {label1}}.", call = NULL)
  if (is.null(cols2))
    cli::cli_abort("No snapshot found with label {.val {label2}}.", call = NULL)

  result <- list(
    added   = setdiff(cols2, cols1),
    removed = setdiff(cols1, cols2)
  )

  cli::cli_inform("Columns added ({length(result$added)}):   {.val {result$added}}")
  cli::cli_inform("Columns removed ({length(result$removed)}): {.val {result$removed}}")

  invisible(result)
}


#' Exclude withdrawn participants from a dataset
#'
#' Reads a UK Biobank withdrawal list (a headerless single-column CSV of
#' anonymised participant IDs) and removes the corresponding rows from
#' `data`. A pair of [ops_snapshot()] calls is made automatically so the
#' before/after row counts are recorded in the session snapshot history.
#'
#' @param data A data.frame or data.table containing a participant ID column.
#' @param file (character) Path to the UKB withdrawal CSV file. The file must
#'   be a single-column, **header-free** CSV as supplied by UK Biobank
#'   (e.g. `w854944_20260310.csv`).
#' @param eid_col (character) Name of the participant ID column in `data`.
#'   Default `"eid"`.
#' @param verbose (logical) Print the CLI report. Default `TRUE`.
#'
#' @return A data.table with withdrawn participants removed.
#'
#' @export
#'
#' @examples
#' dt <- ops_toy(n = 100)
#' withdraw_file <- tempfile(fileext = ".csv")
#' writeLines(as.character(dt$eid[1:5]), withdraw_file)
#' dt <- ops_withdraw(dt, file = withdraw_file)
ops_withdraw <- function(data, file, eid_col = "eid", verbose = TRUE) {

  # ── Validation ──────────────────────────────────────────────────────────────
  .assert_data_frame(data)
  .assert_scalar_string(file)
  if (!file.exists(file))
    cli::cli_abort("Withdrawal file not found: {.path {file}}", call = NULL)
  .assert_scalar_string(eid_col)
  if (!eid_col %in% names(data))
    cli::cli_abort("Column {.val {eid_col}} not found in {.arg data}.", call = NULL)
  .assert_flag(verbose)

  dt <- data.table::as.data.table(data)

  # ── Read withdrawal list ─────────────────────────────────────────────────────
  # Reason: UKB withdrawal files are headerless single-column CSVs; fread
  # auto-detects integer type so no coercion is needed.
  withdraw_ids <- data.table::fread(file, header = FALSE)[[1L]]
  n_withdraw   <- length(withdraw_ids)

  # ── Snapshot before ──────────────────────────────────────────────────────────
  ops_snapshot(dt, label = "before_withdraw", verbose = verbose, check_na = FALSE)

  # ── Exclude ──────────────────────────────────────────────────────────────────
  n_found <- sum(dt[[eid_col]] %in% withdraw_ids)
  dt      <- dt[!get(eid_col) %in% withdraw_ids]

  # ── Snapshot after ───────────────────────────────────────────────────────────
  ops_snapshot(dt, label = "after_withdraw", verbose = verbose, check_na = FALSE)

  # ── Extra CLI summary ────────────────────────────────────────────────────────
  if (verbose) {
    fname <- basename(file)
    cli::cli_inform(c(
      "i" = "Withdrawal file: {.file {fname}} ({n_withdraw} IDs)",
      "x" = "Excluded: {n_found} participant{?s} found in data",
      "v" = "Remaining: {format(nrow(dt), big.mark = ',')} participants"
    ))
  }

  dt
}
