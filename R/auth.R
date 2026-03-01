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
#' auth_login(token = "your_token_here")
#' }
auth_login <- function(token = NULL) {
  if (is.null(token) || !nzchar(token)) {
    token <- Sys.getenv("DX_API_TOKEN")
    if (!nzchar(token)) {
      stop(
        "No token provided. Supply a token or set DX_API_TOKEN environment variable.",
        call. = FALSE
      )
    }
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

  message("Logged in to DNAnexus successfully as: ", verify$stdout)
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

  message("User:    ", status$user)
  message("Project: ", if (is.na(status$project)) "None selected" else status$project)

  invisible(status)
}


#' Logout from DNAnexus
#'
#' Clears the local DNAnexus authentication token and session.
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

  message("Logged out from DNAnexus.")
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
    message("No projects found.")
    return(invisible(character(0)))
  }

  projects <- strsplit(result$stdout, "\n")[[1]]
  message(paste(projects, collapse = "\n"))
  invisible(projects)
}


#' Select a DNAnexus project
#'
#' Switches the active project context on the DNAnexus platform.
#'
#' @param project (character) Project ID or name to select.
#'
#' @return Invisible TRUE on success.
#' @export
#'
#' @examples
#' \dontrun{
#' auth_select_project("project-XXXXXXXXXXXX")
#' }
auth_select_project <- function(project) {
  if (missing(project) || !nzchar(project)) {
    stop("Please provide a project ID or name.", call. = FALSE)
  }

  result <- .dx_run(c("select", project))

  if (!result$success) {
    stop("Failed to select project: ", result$stderr, call. = FALSE)
  }

  # Reason: verify project was actually switched by checking env after select
  confirmed <- .dx_get_project_id()

  if (is.na(confirmed) || confirmed != project) {
    stop("Project selection failed: context was not updated.", call. = FALSE)
  }

  message("Project selected: ", confirmed)
  invisible(TRUE)
}
