# =============================================================================
# job.R — Monitor and retrieve DNAnexus table-exporter job results
# =============================================================================


#' Check the current state of a DNAnexus job
#'
#' Returns the current state of a job submitted by \code{extract_batch()}.
#' For failed jobs, the failure message is attached as an attribute.
#'
#' @param job_id (character) Job ID returned by \code{extract_batch()},
#'   e.g. \code{"job-XXXX"}.
#'
#' @return A named character string — the job state. Possible values:
#'   \describe{
#'     \item{\code{"idle"}}{Queued, waiting to be scheduled.}
#'     \item{\code{"runnable"}}{Resources being allocated.}
#'     \item{\code{"running"}}{Actively executing.}
#'     \item{\code{"done"}}{Completed successfully.}
#'     \item{\code{"failed"}}{Failed; see \code{attr(result, "failure_message")}.}
#'     \item{\code{"terminated"}}{Manually terminated.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' job_id <- extract_batch(c(31, 53, 21022))
#' job_status(job_id)
#'
#' s <- job_status(job_id)
#' if (s == "failed") cli::cli_inform(attr(s, "failure_message"))
#' }
job_status <- function(job_id) {
  .assert_job_id(job_id)

  desc  <- .dx_job_describe(job_id)
  state <- desc$state

  result <- structure(state, names = job_id)

  if (identical(state, "failed")) {
    msg <- if (!is.null(desc$failureMessage)) desc$failureMessage else
           if (!is.null(desc$failureReason))  desc$failureReason  else
           "(no message)"
    attr(result, "failure_message") <- msg
  }

  result
}


#' Wait for a DNAnexus job to finish
#'
#' Polls \code{job_status()} at regular intervals until the job reaches a
#' terminal state (\code{"done"}, \code{"failed"}, or \code{"terminated"}).
#' Stops with an error if the job fails, is terminated, or times out.
#'
#' @param job_id (character) Job ID returned by \code{extract_batch()}.
#' @param interval (integer) Polling interval in seconds. Default: \code{30}.
#' @param timeout (numeric) Maximum wait time in seconds. Default: \code{Inf}
#'   (wait indefinitely). On UKB RAP, jobs can stay in \code{"runnable"} for
#'   several hours during peak times — set a finite value (e.g. \code{7200})
#'   only if you need a hard deadline.
#' @param verbose (logical) Print state and elapsed time at each poll.
#'   Default: \code{TRUE}.
#'
#' @return Invisibly returns the final state string (\code{"done"}).
#' @export
#'
#' @examples
#' \dontrun{
#' job_id <- extract_batch(c(31, 53, 21022))
#' job_wait(job_id)
#'
#' # Read result immediately after completion (RAP only)
#' job_wait(job_id)
#' df <- job_result(job_id)
#' }
job_wait <- function(job_id, interval = 30, timeout = Inf, verbose = TRUE) {
  .assert_job_id(job_id)

  terminal <- c("done", "failed", "terminated")
  start    <- proc.time()[["elapsed"]]

  repeat {
    elapsed <- as.integer(proc.time()[["elapsed"]] - start)

    # Reason: guard with is.finite() so timeout = Inf never triggers this branch
    if (is.finite(timeout) && elapsed >= timeout) {
      cli::cli_abort("Timed out after {timeout} seconds waiting for {job_id}.", call = NULL)
    }

    desc  <- .dx_job_describe(job_id)
    state <- desc$state
    hms   <- sprintf(
      "%02d:%02d:%02d",
      elapsed %/% 3600L, (elapsed %% 3600L) %/% 60L, elapsed %% 60L
    )

    if (verbose) {
      cli::cli_inform("[{hms}] {job_id} - {state}")
    }

    if (state %in% terminal) break

    Sys.sleep(interval)
  }

  if (state == "failed") {
    msg <- if (!is.null(desc$failureMessage)) desc$failureMessage else
           if (!is.null(desc$failureReason))  desc$failureReason  else
           "(no message)"
    cli::cli_abort("Job {job_id} failed: {msg}", call = NULL)
  }

  if (state == "terminated") {
    cli::cli_abort("Job {job_id} was terminated.", call = NULL)
  }

  invisible(state)
}


#' Get the RAP file path of a completed DNAnexus job output
#'
#' Returns the absolute \code{/mnt/project/} path of the CSV produced by
#' \code{extract_batch()}. Use this to read the file directly on the RAP
#' without downloading.
#'
#' @param job_id (character) Job ID returned by \code{extract_batch()}.
#'
#' @return A character string — the absolute path to the output CSV under
#'   \code{/mnt/project/}.
#' @export
#'
#' @examples
#' \dontrun{
#' path <- job_path(job_id)
#' df   <- data.table::fread(path)
#' }
job_path <- function(job_id) {
  .assert_job_id(job_id)

  desc  <- .dx_job_describe(job_id)
  state <- desc$state

  if (state != "done") {
    cli::cli_abort(
      "Job {job_id} is '{state}', not 'done'. Use {.fn job_wait} to wait for completion.",
      call = NULL
    )
  }

  file_id <- .dx_job_output_id(desc)
  .dx_file_path(file_id)
}


#' Load the result of a completed DNAnexus job into R
#'
#' Reads the output CSV produced by \code{extract_batch()} directly from RAP
#' project storage and returns a \code{data.table}. Must be run inside the
#' RAP environment.
#'
#' @param job_id (character) Job ID returned by \code{extract_batch()}.
#'
#' @return A \code{data.table} with one row per participant.
#' @export
#'
#' @examples
#' \dontrun{
#' job_id <- extract_batch(c(31, 53, 21022))
#' job_wait(job_id)
#' df <- job_result(job_id)
#' }
job_result <- function(job_id) {
  .assert_on_rap()

  .assert_job_id(job_id)

  path <- job_path(job_id)
  cli::cli_inform("Reading {.file {path}}")

  # Reason: integer64 = "double" avoids bit64 dependency; UKB eids are
  # 7-digit integers, well within double precision range
  dt <- data.table::fread(path, data.table = TRUE, integer64 = "double")
  cli::cli_inform("{nrow(dt)} rows x {ncol(dt)} cols (incl. eid)")
  dt
}


#' List recent DNAnexus jobs in the current project
#'
#' Returns a summary of the most recent jobs, optionally filtered by state.
#' Useful for quickly reviewing which jobs have completed, failed, or are
#' still running.
#'
#' @param n (integer) Maximum number of recent jobs to return. Must be a
#'   single positive integer. Default: \code{20}.
#' @param state (character) Filter by state(s). Must be \code{NULL} or a
#'   character vector of valid states:
#'   \code{"idle"}, \code{"runnable"}, \code{"running"}, \code{"done"},
#'   \code{"failed"}, \code{"terminated"}.
#'   Default: \code{NULL} (return all).
#'
#' @return A data.frame with columns:
#'   \describe{
#'     \item{job_id}{Job ID string, e.g. \code{"job-XXXX"}.}
#'     \item{name}{Job name (typically \code{"Table exporter"}).}
#'     \item{state}{Current job state.}
#'     \item{created}{Job creation time (\code{POSIXct}).}
#'     \item{runtime}{Runtime string (e.g. \code{"0:04:36"}), \code{NA} if
#'       still running.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' job_ls()
#' job_ls(n = 5)
#' job_ls(state = "failed")
#' job_ls(state = c("done", "failed"))
#' }
job_ls <- function(n = 20, state = NULL) {
  n     <- .assert_count(n)
  state <- .assert_choices(
    state,
    c("idle", "runnable", "running", "done", "failed", "terminated")
  )

  result <- .dx_find_jobs_raw(n)
  if (!result$success) {
    cli::cli_abort("Failed to list jobs: {result$stderr}", call = NULL)
  }

  df <- .dx_parse_jobs(result$stdout)

  if (!is.null(state) && nrow(df) > 0) {
    df <- df[df$state %in% state, , drop = FALSE]
  }

  df
}
