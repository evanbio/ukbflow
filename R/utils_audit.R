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

  list(
    name            = audit$name,
    start_time      = audit$start_time,
    ukbflow_version = audit$ukbflow_version,
    dx_user         = audit$dx_user,
    dx_project      = audit$dx_project,
    session_info    = session_info,
    extraction      = extraction,
    snapshots       = snapshots
  )
}
