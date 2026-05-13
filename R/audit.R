# =============================================================================
# audit.R — Analysis audit records for ukbflow
# =============================================================================


#' Start a ukbflow audit record
#'
#' Creates a minimal S3 audit object for one analysis. The object records only
#' the root metadata needed to identify and reproduce the analysis context:
#' analysis name, start time, ukbflow version, R session information, and the
#' current DNAnexus user / project when available. Later audit helpers can
#' append fields, snapshots, exclusions, models, and jobs to this object.
#'
#' DNAnexus context is captured opportunistically. If the dx CLI is unavailable,
#' the user is not logged in, or no project is selected, the corresponding
#' fields are recorded as \code{NA} without failing.
#'
#' @param name (character) User-defined analysis name, e.g.
#'   \code{"ad_nmsc_analysis"}. This is not a DNAnexus project ID.
#'
#' @return An S3 object with class \code{c("ukbflow_audit", "list")}.
#' @export
#'
#' @examples
#' aud <- audit_start("example_analysis")
#' aud
audit_start <- function(name) {

  .assert_scalar_string(name)

  dx_user <- tryCatch({
    whoami <- .dx_run(c("whoami"))
    if (isTRUE(whoami$success)) whoami$stdout else NA_character_
  }, error = function(e) NA_character_)

  dx_project <- tryCatch(.dx_get_project_id(), error = function(e) NA_character_)
  if (length(dx_project) != 1L || is.na(dx_project) || !nzchar(dx_project)) {
    dx_project <- NA_character_
  }

  out <- list(
    name            = name,
    start_time      = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    ukbflow_version = as.character(utils::packageVersion("ukbflow")),
    session_info    = utils::sessionInfo(),
    dx_user         = dx_user,
    dx_project      = dx_project
  )

  class(out) <- c("ukbflow_audit", "list")
  out
}


#' Record UKB field IDs used for extraction
#'
#' Appends one extraction record to a \code{\link{audit_start}} object. The
#' function records the declared UKB field IDs, optional dataset name, optional
#' label, number of fields, and timestamp. It does not validate field
#' availability against RAP; use \code{\link{ops_fields}} or
#' \code{\link{extract_ls}} separately for project-specific field discovery.
#'
#' @param audit A \code{ukbflow_audit} object created by
#'   \code{\link{audit_start}}.
#' @param field_id (integer) UKB field IDs used for extraction.
#' @param dataset (character or NULL) Optional RAP dataset file name.
#'   Default: \code{NULL}.
#' @param label (character or NULL) Optional label for this extraction record.
#'   Default: \code{NULL}.
#'
#' @return The updated \code{ukbflow_audit} object.
#' @export
#'
#' @examples
#' aud <- audit_start("example_analysis")
#' aud <- audit_fields(aud, c(31, 53, 21022), label = "core_fields")
audit_fields <- function(audit, field_id, dataset = NULL, label = NULL) {

  .assert_audit(audit)
  field_id <- unique(.assert_integer_ids(field_id))
  if (!is.null(dataset)) .assert_scalar_string(dataset)
  if (!is.null(label)) .assert_scalar_string(label)

  record <- list(
    field_id    = field_id,
    dataset     = if (is.null(dataset)) NA_character_ else dataset,
    label       = if (is.null(label)) NA_character_ else label,
    n_fields    = length(field_id),
    recorded_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )

  if (is.null(audit$extraction)) audit$extraction <- list()
  audit$extraction[[length(audit$extraction) + 1L]] <- record
  audit
}


#' Record a data snapshot in a ukbflow audit object
#'
#' Captures a lightweight structural snapshot of a data.frame at a named
#' analysis stage and appends it to the \code{snapshots} layer of a
#' \code{ukbflow_audit} object. This function mirrors the core behavior of
#' \code{\link{ops_snapshot}} but stores records inside the explicit audit
#' object rather than a session cache.
#'
#' @param audit A \code{ukbflow_audit} object created by
#'   \code{\link{audit_start}}.
#' @param data A data.frame or data.table to snapshot. Required unless
#'   \code{reset = TRUE}.
#' @param label (character) A unique label for this snapshot, e.g.
#'   \code{"raw_extracted"} or \code{"analysis_ready"}. Required unless
#'   \code{reset = TRUE}.
#' @param reset (logical) If \code{TRUE}, clears only the
#'   \code{audit$snapshots} layer and returns the updated audit object.
#'   Default: \code{FALSE}.
#' @param check_na (logical) Whether to count columns with any \code{NA} or
#'   blank string values. Set to \code{FALSE} to avoid scanning large datasets.
#'   Default: \code{TRUE}.
#' @param verbose (logical) Print a short status message. Default:
#'   \code{TRUE}.
#'
#' @return The updated \code{ukbflow_audit} object.
#' @export
#'
#' @examples
#' aud <- audit_start("example_analysis")
#' dt <- data.frame(eid = 1:3, x = c(1, NA, 3))
#' aud <- audit_snapshot(aud, dt, "raw")
audit_snapshot <- function(audit, data = NULL, label = NULL, reset = FALSE,
                           check_na = TRUE, verbose = TRUE) {

  .assert_audit(audit)
  .assert_flag(reset)
  .assert_flag(check_na)
  .assert_flag(verbose)

  if (reset) {
    audit$snapshots <- NULL
    if (verbose) cli::cli_alert_success("audit snapshots cleared.")
    return(audit)
  }

  if (is.null(data)) {
    cli::cli_abort("{.arg data} is required unless {.code reset = TRUE}.", call = NULL)
  }
  .assert_data_frame(data)
  if (is.null(label)) {
    cli::cli_abort("{.arg label} is required unless {.code reset = TRUE}.", call = NULL)
  }
  .assert_scalar_string(label)

  snapshot_records <- if (is.null(audit$snapshots)) list() else audit$snapshots
  existing_labels <- vapply(snapshot_records, `[[`, "", "label")
  if (label %in% existing_labels) {
    cli::cli_abort("Snapshot label {.val {label}} already exists.", call = NULL)
  }

  if (check_na) {
    dt_tmp <- data.table::as.data.table(data)
    n_na_cols <- sum(vapply(dt_tmp, function(col) {
      any(is.na(col) | (is.character(col) & !is.na(col) & col == ""))
    }, logical(1L)))
  } else {
    n_na_cols <- NA_integer_
  }

  record <- list(
    label          = label,
    nrow           = nrow(data),
    ncol           = ncol(data),
    n_na_cols      = n_na_cols,
    columns        = names(data),
    object_size_mb = round(as.numeric(utils::object.size(data)) / 1024^2, 2),
    recorded_at    = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )

  if (is.null(audit$snapshots)) audit$snapshots <- list()
  audit$snapshots[[length(audit$snapshots) + 1L]] <- record

  if (verbose) {
    cli::cli_alert_success(
      "audit snapshot {.val {label}}: {nrow(data)} rows x {ncol(data)} cols."
    )
  }

  audit
}


#' Write a ukbflow audit manifest
#'
#' Writes a \code{ukbflow_audit} object to a JSON manifest. The manifest is a
#' plain-list representation of the audit object: session information is
#' converted to character lines, and record layers such as \code{extraction}
#' and \code{snapshots} are written as JSON arrays.
#'
#' @param audit A \code{ukbflow_audit} object created by
#'   \code{\link{audit_start}}.
#' @param file (character) Output JSON file path. Default:
#'   \code{"ukbflow-audit.json"}.
#' @param overwrite (logical) Overwrite \code{file} if it already exists.
#'   Default: \code{FALSE}.
#'
#' @return Invisibly returns the normalized output path.
#' @export
#'
#' @examples
#' aud <- audit_start("example_analysis")
#' outfile <- tempfile(fileext = ".json")
#' audit_write(aud, outfile)
audit_write <- function(audit, file = "ukbflow-audit.json", overwrite = FALSE) {

  .assert_audit(audit)
  .assert_scalar_string(file)
  .assert_flag(overwrite)

  out_dir <- dirname(file)
  if (!dir.exists(out_dir)) {
    cli::cli_abort("Output directory does not exist: {.path {out_dir}}", call = NULL)
  }
  if (file.exists(file) && !overwrite) {
    cli::cli_abort(
      "Output file already exists: {.path {file}}. Use {.code overwrite = TRUE}.",
      call = NULL
    )
  }

  manifest <- .audit_as_manifest(audit)
  jsonlite::write_json(
    manifest,
    path = file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )

  out_path <- normalizePath(file, winslash = "/", mustWork = TRUE)
  cli::cli_alert_success("audit manifest written: {.path {out_path}}")
  invisible(out_path)
}


#' @export
print.ukbflow_audit <- function(x, ...) {

  cli::cli_h1("ukbflow audit")
  cli::cli_inform("name: {.val {x$name}}")
  cli::cli_inform("start_time: {.val {x$start_time}}")
  cli::cli_inform("ukbflow_version: {.val {x$ukbflow_version}}")
  cli::cli_inform("dx_user: {.val {if (is.na(x$dx_user)) 'NA' else x$dx_user}}")
  cli::cli_inform("dx_project: {.val {if (is.na(x$dx_project)) 'NA' else x$dx_project}}")
  n_extraction <- if (is.null(x$extraction)) 0L else length(x$extraction)
  cli::cli_inform("extraction records: {n_extraction}")
  n_snapshots <- if (is.null(x$snapshots)) 0L else length(x$snapshots)
  cli::cli_inform("snapshots: {n_snapshots}")
  cli::cli_inform("session_info: recorded")

  invisible(x)
}


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
