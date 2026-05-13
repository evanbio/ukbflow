# =============================================================================
# utils_audit.R — Internal helpers for audit_ series
# =============================================================================


#' Assert that an object is a ukbflow audit record
#'
#' @keywords internal
#' @noRd
.assert_audit <- function(x, arg = deparse(substitute(x))) {
  if (!inherits(x, "ukbflow_audit")) {
    cli::cli_abort(
      "{.arg {arg}} must be a ukbflow_audit object created by {.fn audit_start}.",
      call = NULL
    )
  }
  invisible(x)
}


#' Convert a ukbflow audit object to a JSON-safe manifest list
#'
#' @keywords internal
#' @noRd
.audit_as_manifest <- function(audit) {
  .assert_audit(audit)

  extraction <- if (is.null(audit$extraction)) {
    list()
  } else {
    lapply(audit$extraction, function(record) {
      if (length(record$field_id) == 1L) {
        record$field_id <- list(record$field_id)
      }
      record
    })
  }

  snapshots <- if (is.null(audit$snapshots)) {
    list()
  } else {
    lapply(audit$snapshots, function(record) {
      if (length(record$columns) == 1L) {
        record$columns <- list(record$columns)
      }
      record
    })
  }

  session_info <- capture.output(print(audit$session_info))
  if (length(session_info) == 1L) {
    session_info <- list(session_info)
  }

  phenotypes <- if (is.null(audit$phenotypes)) {
    list()
  } else {
    audit$phenotypes
  }

  models <- if (is.null(audit$models)) {
    list()
  } else {
    audit$models
  }

  list(
    name            = audit$name,
    start_time      = audit$start_time,
    ukbflow_version = audit$ukbflow_version,
    dx_user         = audit$dx_user,
    dx_project      = audit$dx_project,
    session_info    = session_info,
    extraction      = extraction,
    snapshots       = snapshots,
    phenotypes      = phenotypes,
    models          = models
  )
}


#' @keywords internal
#' @noRd
.audit_status_date_record <- function(data, name, status_suffix,
                                      date_suffix = paste0(status_suffix, "_date")) {
  status_col <- paste0(name, "_", status_suffix)
  date_col   <- paste0(name, "_", date_suffix)

  has_status <- status_col %in% names(data)
  has_date   <- date_col %in% names(data)

  list(
    present    = has_status || has_date,
    status_col = if (has_status) status_col else NA_character_,
    date_col   = if (has_date) date_col else NA_character_,
    n_cases    = if (has_status) .audit_count_true(data[[status_col]]) else NA_integer_,
    n_dated    = if (has_date) sum(!is.na(data[[date_col]])) else NA_integer_
  )
}


#' @keywords internal
#' @noRd
.audit_count_true <- function(x) {
  if (is.logical(x)) {
    return(sum(x, na.rm = TRUE))
  }
  sum(as.character(x) %in% c("TRUE", "True", "true", "1"))
}


#' @keywords internal
#' @noRd
.audit_timing_record <- function(data, name) {
  timing_col <- paste0(name, "_timing")
  if (!timing_col %in% names(data)) {
    return(list(
      present    = FALSE,
      timing_col = NA_character_,
      no_disease = NA_integer_,
      prevalent  = NA_integer_,
      incident   = NA_integer_,
      missing    = NA_integer_
    ))
  }

  timing <- data[[timing_col]]
  list(
    present    = TRUE,
    timing_col = timing_col,
    no_disease = sum(timing == 0L, na.rm = TRUE),
    prevalent  = sum(timing == 1L, na.rm = TRUE),
    incident   = sum(timing == 2L, na.rm = TRUE),
    missing    = sum(is.na(timing))
  )
}


#' @keywords internal
#' @noRd
.audit_followup_record <- function(data, name) {
  end_col   <- paste0(name, "_followup_end")
  years_col <- paste0(name, "_followup_years")

  has_end   <- end_col %in% names(data)
  has_years <- years_col %in% names(data)

  if (!has_end && !has_years) {
    return(list(
      present       = FALSE,
      end_col       = NA_character_,
      years_col     = NA_character_,
      n_end         = NA_integer_,
      n_non_missing = NA_integer_,
      mean          = NA_real_,
      median        = NA_real_,
      min           = NA_real_,
      max           = NA_real_
    ))
  }

  years <- if (has_years) data[[years_col]] else NULL
  n_years <- if (has_years) sum(!is.na(years)) else NA_integer_
  list(
    present       = TRUE,
    end_col       = if (has_end) end_col else NA_character_,
    years_col     = if (has_years) years_col else NA_character_,
    n_end         = if (has_end) sum(!is.na(data[[end_col]])) else NA_integer_,
    n_non_missing = n_years,
    mean          = if (has_years && n_years > 0L) mean(years, na.rm = TRUE) else NA_real_,
    median        = if (has_years && n_years > 0L) stats::median(years, na.rm = TRUE) else NA_real_,
    min           = if (has_years && n_years > 0L) min(years, na.rm = TRUE) else NA_real_,
    max           = if (has_years && n_years > 0L) max(years, na.rm = TRUE) else NA_real_
  )
}


#' @keywords internal
#' @noRd
.audit_result_as_data_frame <- function(result) {
  out <- as.data.frame(result, stringsAsFactors = FALSE)
  for (col in names(out)) {
    if (is.factor(out[[col]])) {
      out[[col]] <- as.character(out[[col]])
    }
  }
  rownames(out) <- NULL
  out
}


#' @keywords internal
#' @noRd
.audit_infer_model_method <- function(result) {
  cols <- names(result)
  if ("SHR" %in% cols) {
    "competing"
  } else if ("HR" %in% cols) {
    "coxph"
  } else if ("OR" %in% cols) {
    "logistic"
  } else if ("beta" %in% cols) {
    "linear"
  } else {
    "unknown"
  }
}
