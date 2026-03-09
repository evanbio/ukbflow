# =============================================================================
# utils_ops.R — Internal helpers for ops_ series
# =============================================================================


#' Check dx CLI installation
#'
#' @return Named list: ok, path, version.
#' @keywords internal
#' @noRd
.ops_check_dx <- function() {
  path <- Sys.which("dx")
  if (!nzchar(path)) {
    return(list(ok = FALSE, path = NA_character_, version = NA_character_))
  }

  ver_res <- processx::run(
    command          = unname(path),
    args             = "--version",
    error_on_status  = FALSE
  )
  version <- trimws(ver_res$stdout)
  if (!nzchar(version)) version <- trimws(ver_res$stderr)

  list(ok = TRUE, path = unname(path), version = version)
}


#' Check RAP authentication status
#'
#' @return Named list: ok, logged_in, user, project.
#' @keywords internal
#' @noRd
.ops_check_auth <- function() {
  # Guard: if dx is not on PATH, skip silently
  if (!nzchar(Sys.which("dx"))) {
    return(list(ok = FALSE, logged_in = FALSE, user = NA_character_, project = NA_character_))
  }

  whoami <- .dx_run(c("whoami"))
  if (!whoami$success) {
    return(list(ok = FALSE, logged_in = FALSE, user = NA_character_, project = NA_character_))
  }

  project <- .dx_get_project_id()
  list(
    ok        = TRUE,
    logged_in = TRUE,
    user      = whoami$stdout,
    project   = project
  )
}


#' Check R package dependencies
#'
#' Returns a list of check results for all Imports and key Suggests.
#'
#' @return A list of named lists, each with: package, required, group,
#'   installed, version.
#' @keywords internal
#' @noRd
.ops_check_deps <- function() {
  # Each entry: package name, required (TRUE = Imports), module group label
  deps <- list(
    # Core
    list(pkg = "cli",          required = TRUE,  group = "core"),
    list(pkg = "data.table",   required = TRUE,  group = "core"),
    list(pkg = "processx",     required = TRUE,  group = "core"),
    list(pkg = "rlang",        required = TRUE,  group = "core"),
    list(pkg = "tools",        required = TRUE,  group = "core"),
    # Extract / Fetch
    list(pkg = "curl",         required = TRUE,  group = "extract / fetch"),
    list(pkg = "jsonlite",     required = TRUE,  group = "extract / fetch"),
    # Analysis
    list(pkg = "survival",     required = TRUE,  group = "assoc_coxph"),
    list(pkg = "dplyr",        required = TRUE,  group = "assoc / derive"),
    list(pkg = "tidyselect",   required = TRUE,  group = "assoc / derive"),
    # Visualisation
    list(pkg = "forestploter", required = TRUE,  group = "plot_forest"),
    list(pkg = "gt",           required = TRUE,  group = "plot_tableone"),
    list(pkg = "gtsummary",    required = TRUE,  group = "plot_tableone"),
    # Optional / Suggests
    list(pkg = "pROC",         required = FALSE, group = "assoc (optional)"),
    list(pkg = "knitr",        required = FALSE, group = "vignettes"),
    list(pkg = "rmarkdown",    required = FALSE, group = "vignettes")
  )

  lapply(deps, function(d) {
    inst    <- requireNamespace(d$pkg, quietly = TRUE)
    version <- if (inst) as.character(utils::packageVersion(d$pkg)) else NA_character_
    list(
      package   = d$pkg,
      required  = d$required,
      group     = d$group,
      installed = inst,
      version   = version
    )
  })
}
