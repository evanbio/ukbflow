# =============================================================================
# utils_job.R — Internal helpers for job_ series
# Depends on .dx_run() defined in utils_auth.R
# Depends on .dx_make_url() / .dx_download_file() defined in utils_fetch.R
# =============================================================================


#' Run dx describe job-XXXX --json and return parsed R list
#'
#' @param job_id (character) Job ID, e.g. \code{"job-XXXX"}.
#' @param timeout (integer) Timeout in seconds. Default: 30.
#' @return Named R list from jsonlite::parse_json().
#'
#' @keywords internal
#' @noRd
.dx_job_describe <- function(job_id, timeout = 30) {
  result <- .dx_run(
    c("describe", job_id, "--json"),
    timeout = timeout,
    env     = c(PYTHONIOENCODING = "utf-8")
  )
  if (!result$success) {
    stop("Failed to describe job '", job_id, "': ", result$stderr, call. = FALSE)
  }
  jsonlite::parse_json(result$stdout)
}


#' Extract the output CSV file ID from a job describe list
#'
#' @param desc Named list returned by \code{.dx_job_describe()}.
#' @return Character string — DNAnexus file ID (e.g. \code{"file-XXXX"}).
#'
#' @keywords internal
#' @noRd
.dx_job_output_id <- function(desc) {
  # Reason: table-exporter puts CSV under output$csv (an array);
  # output is NULL for failed/running jobs so we guard explicitly
  csv <- desc$output$csv
  if (is.null(csv) || length(csv) == 0) {
    stop(
      "Job has no output CSV. ",
      "Check job state with job_status() before calling job_result().",
      call. = FALSE
    )
  }
  csv[[1]]$`$dnanexus_link`
}


#' Extract the output file name (without extension) from a job describe list
#'
#' @param desc Named list returned by \code{.dx_job_describe()}.
#' @return Character string — output file base name, e.g. \code{"ad_pheno"}.
#'
#' @keywords internal
#' @noRd
.dx_job_output_name <- function(desc) {
  desc$runInput$output
}


#' Run dx find jobs and return raw stdout
#'
#' @param n (integer) Maximum number of results. Default: 20.
#' @param timeout (integer) Timeout in seconds. Default: 30.
#' @return Named list with stdout, stderr, status, success.
#'
#' @keywords internal
#' @noRd
.dx_find_jobs_raw <- function(n = 20, timeout = 30) {
  .dx_run(
    c("find", "jobs", "--num-results", as.character(n)),
    timeout = timeout,
    env     = c(PYTHONIOENCODING = "utf-8")
  )
}


#' Parse dx find jobs text output into a data.frame
#'
#' @param stdout (character) Raw stdout from \code{dx find jobs}.
#' @return data.frame with columns: job_id, name, state, created, runtime.
#'
#' @keywords internal
#' @noRd
.dx_parse_jobs <- function(stdout) {

  empty <- data.frame(
    job_id  = character(0),
    name    = character(0),
    state   = character(0),
    created = as.POSIXct(character(0)),
    runtime = character(0),
    stringsAsFactors = FALSE
  )

  lines <- strsplit(stdout, "\n")[[1]]
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) == 0) return(empty)

  rows <- list()
  i    <- 1L

  while (i <= length(lines)) {
    line1 <- lines[i]

    # Only process lines starting with "* " that describe a job
    if (!startsWith(line1, "*")) { i <- i + 1L; next }

    # Line 1 format: * <name> (<exec>:<func>) (<state>) <job-XXXX>
    m1   <- regexec(
      "^\\*\\s+(.+?)\\s+\\(.+?\\)\\s+\\((\\w+)\\)\\s+(job-\\S+)",
      line1, perl = TRUE
    )
    cap1 <- regmatches(line1, m1)[[1]]

    # Skip lines that don't match (e.g. "* More results not shown...")
    if (length(cap1) < 4) { i <- i + 1L; next }

    name   <- cap1[2]
    state  <- cap1[3]
    job_id <- cap1[4]

    # Line 2 format: <user> <YYYY-MM-DD HH:MM:SS> [(runtime <HH:MM:SS>)]
    created <- as.POSIXct(NA_character_)
    runtime <- NA_character_

    if (i + 1L <= length(lines)) {
      line2 <- lines[i + 1L]
      m2    <- regexec(
        "^\\s+\\S+\\s+(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})(?:\\s+\\(runtime (\\S+)\\))?",
        line2, perl = TRUE
      )
      cap2 <- regmatches(line2, m2)[[1]]
      if (length(cap2) >= 2) {
        created <- as.POSIXct(cap2[2], format = "%Y-%m-%d %H:%M:%S")
        if (length(cap2) >= 3 && nzchar(cap2[3])) runtime <- cap2[3]
      }
      i <- i + 2L
    } else {
      i <- i + 1L
    }

    rows[[length(rows) + 1L]] <- data.frame(
      job_id  = job_id,
      name    = name,
      state   = state,
      created = created,
      runtime = runtime,
      stringsAsFactors = FALSE
    )
  }

  if (length(rows) == 0) return(empty)
  do.call(rbind, rows)
}
