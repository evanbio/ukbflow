# =============================================================================
# auth.R — Authentication & connection to DNAnexus RAP
# =============================================================================


#' Login to DNAnexus with a token
#'
#' Authenticates with the DNAnexus Research Analysis Platform using an API
#' token. Equivalent to running `dx login --token` on the command line.
#'
#' @param token (character) DNAnexus API token. If NULL, reads from the
#'   environment variable `DX_API_TOKEN`.
#'
#' @return Invisible TRUE on success.
#' @export
#'
#' @examples
#' \dontrun{
#' # Supply token directly
#' auth_login(token = "your_token_here")
#'
#' # Or store token in ~/.Renviron (recommended):
#' # usethis::edit_r_environ()
#' # Add: DX_API_TOKEN=your_token_here
#' # Save and restart R, then call:
#' auth_login()
#' }
auth_login <- function(token = NULL) {
  if (is.null(token)) {
    token <- Sys.getenv("DX_API_TOKEN")
    if (!nzchar(token)) {
      stop(
        "No token provided. Supply a token or set DX_API_TOKEN environment variable.",
        call. = FALSE
      )
    }
  } else {
    .assert_scalar_string(token)
  }

  result <- .dx_run(c("login", "--token", token, "--noprojects"))

  if (!result$success) {
    stop("Login failed: ", result$stderr, call. = FALSE)
  }

  # Reason: dx login may return status 0 even with invalid token if a session
  # already exists. Verify by calling whoami to confirm actual authentication.
  verify <- .dx_run(c("whoami"))
  if (!verify$success) {
    stop("Login failed: token invalid or expired.", call. = FALSE)
  }

  cli::cli_alert_success("Logged in to DNAnexus as: {.val {verify$stdout}}")
  invisible(TRUE)
}


#' Check current DNAnexus authentication status
#'
#' Returns the current logged-in user and selected project.
#'
#' @return A named list with `user` and `project`.
#' @export
#'
#' @examples
#' \dontrun{
#' auth_status()
#' }
auth_status <- function() {
  whoami <- .dx_run(c("whoami"))

  if (!whoami$success) {
    stop("Not logged in. Run auth_login() first.", call. = FALSE)
  }

  status <- list(
    user    = whoami$stdout,
    project = .dx_get_project_id()
  )

  cli::cli_inform(c(
    "*" = "User:    {.val {status$user}}",
    "*" = "Project: {.val {if (is.na(status$project)) 'None selected' else status$project}}"
  ))

  invisible(status)
}


#' Logout from DNAnexus
#'
#' Invalidates the current DNAnexus session on the remote platform. The local
#' token file is not removed but becomes invalid. A new token must be generated
#' from the DNAnexus platform before calling [auth_login()] again.
#'
#' @return Invisible TRUE on success.
#' @export
#'
#' @examples
#' \dontrun{
#' auth_logout()
#' }
auth_logout <- function() {
  result <- .dx_run(c("logout"))

  if (!result$success) {
    stop("Logout failed: ", result$stderr, call. = FALSE)
  }

  cli::cli_alert_success("Logged out from DNAnexus.")
  invisible(TRUE)
}


#' List available DNAnexus projects
#'
#' Returns a list of all projects accessible to the current user.
#'
#' @return A character vector of project names and IDs.
#' @export
#'
#' @examples
#' \dontrun{
#' auth_list_projects()
#' }
auth_list_projects <- function() {
  result <- .dx_run(c("find", "projects", "--level", "VIEW"))

  if (!result$success) {
    stop("Failed to list projects: ", result$stderr, call. = FALSE)
  }

  if (!nzchar(result$stdout)) {
    cli::cli_inform("No projects found.")
    return(invisible(character(0)))
  }

  projects <- strsplit(result$stdout, "\n")[[1]]
  cli::cli_inform(paste(projects, collapse = "\n"))
  invisible(projects)
}


#' Select a DNAnexus project
#'
#' Switches the active project context on the DNAnexus platform. Only project
#' IDs (e.g. `"project-XXXXXXXXXXXX"`) are accepted. Run
#' [auth_list_projects()] to find your project ID.
#'
#' @param project (character) Project ID in the form `"project-XXXXXXXXXXXX"`.
#'
#' @return Invisible TRUE on success.
#' @export
#'
#' @examples
#' \dontrun{
#' auth_select_project("project-XXXXXXXXXXXX")
#' }
auth_select_project <- function(project) {
  if (missing(project)) {
    stop(
      "Please provide a project ID. Run auth_list_projects() to see available projects.",
      call. = FALSE
    )
  }
  .assert_scalar_string(project)

  # Reason: only accept project IDs (project-XXXX) to avoid name/ID ambiguity;
  # names are not unique and can cause silent mismatches.
  if (!grepl("^project-[A-Za-z0-9]+$", project)) {
    stop(
      "Invalid project ID format. Expected 'project-XXXXXXXXXXXX'. ",
      "Run auth_list_projects() to see available IDs.",
      call. = FALSE
    )
  }

  result <- .dx_run(c("select", project))

  if (!result$success) {
    stop("Failed to select project: ", result$stderr, call. = FALSE)
  }

  # Reason: verify project was actually switched
  confirmed <- .dx_get_project_id()

  if (is.na(confirmed) || !identical(confirmed, project)) {
    stop(
      "Project selection failed: expected ", project,
      ", got ", ifelse(is.na(confirmed), "NA", confirmed),
      call. = FALSE
    )
  }

  cli::cli_alert_success("Project selected: {.val {confirmed}}")
  invisible(TRUE)
}
