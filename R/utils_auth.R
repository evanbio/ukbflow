#' @keywords internal
#' @noRd
.dx_run <- function(args, timeout = 30) {
  # Check dx is available
  dx_path <- Sys.which("dx")
  if (dx_path == "") {
    stop(
      "dx-toolkit not found. Please install dxpy: pip install dxpy",
      call. = FALSE
    )
  }

  result <- processx::run(
    command = dx_path,
    args = args,
    error_on_status = FALSE,
    timeout = timeout
  )

  list(
    stdout  = trimws(result$stdout),
    stderr  = trimws(result$stderr),
    status  = result$status,
    success = result$status == 0
  )
}


#' @keywords internal
#' @noRd
.dx_get_project_id <- function() {
  result <- .dx_run(c("env", "--bash"))
  project_id <- regmatches(
    result$stdout,
    regexpr("(?<=DX_PROJECT_CONTEXT_ID=)[^\n]+", result$stdout, perl = TRUE)
  )
  if (length(project_id) == 0) NA_character_ else project_id
}
