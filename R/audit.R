# =============================================================================
# audit.R — Analysis audit records for ukbflow
# =============================================================================


#' Start a ukbflow audit record
#'
#' Creates a minimal S3 audit object for one analysis. The object records only
#' the root metadata needed to identify and reproduce the analysis context:
#' project ID, start time, ukbflow version, and R session information. Later
#' audit helpers can append fields, snapshots, exclusions, models, and jobs to
#' this object.
#'
#' @param project_id (character) User-defined project or analysis identifier,
#'   e.g. \code{"ad_nmsc_analysis"}. This does not need to be a DNAnexus
#'   project ID.
#'
#' @return An S3 object with class \code{c("ukbflow_audit", "list")}.
#' @export
#'
#' @examples
#' aud <- audit_start("example_analysis")
#' aud
audit_start <- function(project_id) {

  .assert_scalar_string(project_id)

  out <- list(
    project_id      = project_id,
    start_time      = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    ukbflow_version = as.character(utils::packageVersion("ukbflow")),
    session_info    = utils::sessionInfo()
  )

  class(out) <- c("ukbflow_audit", "list")
  out
}


#' @export
print.ukbflow_audit <- function(x, ...) {

  cli::cli_h1("ukbflow audit")
  cli::cli_inform("project_id: {.val {x$project_id}}")
  cli::cli_inform("start_time: {.val {x$start_time}}")
  cli::cli_inform("ukbflow_version: {.val {x$ukbflow_version}}")
  cli::cli_inform("session_info: recorded")

  invisible(x)
}
