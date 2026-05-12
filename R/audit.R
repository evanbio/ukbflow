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


#' @export
print.ukbflow_audit <- function(x, ...) {

  cli::cli_h1("ukbflow audit")
  cli::cli_inform("name: {.val {x$name}}")
  cli::cli_inform("start_time: {.val {x$start_time}}")
  cli::cli_inform("ukbflow_version: {.val {x$ukbflow_version}}")
  cli::cli_inform("dx_user: {.val {if (is.na(x$dx_user)) 'NA' else x$dx_user}}")
  cli::cli_inform("dx_project: {.val {if (is.na(x$dx_project)) 'NA' else x$dx_project}}")
  cli::cli_inform("session_info: recorded")

  invisible(x)
}
