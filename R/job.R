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
#' if (s == "failed") message(attr(s, "failure_message"))
#' }
job_status <- function(job_id) {
  if (!grepl("^job-", job_id)) {
    stop("job_id must be a 'job-XXXX' string.", call. = FALSE)
  }

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
#' # Download immediately after completion
#' job_wait(job_id)
#' df <- job_result(job_id, dest = "data/pheno.csv")
#' }
job_wait <- function(job_id, interval = 30, timeout = Inf, verbose = TRUE) {
  if (!grepl("^job-", job_id)) {
    stop("job_id must be a 'job-XXXX' string.", call. = FALSE)
  }

  terminal <- c("done", "failed", "terminated")
  start    <- proc.time()[["elapsed"]]

  repeat {
    elapsed <- as.integer(proc.time()[["elapsed"]] - start)

    # Reason: guard with is.finite() so timeout = Inf never triggers this branch
    if (is.finite(timeout) && elapsed >= timeout) {
      stop(
        sprintf("Timed out after %.0f seconds waiting for %s.", timeout, job_id),
        call. = FALSE
      )
    }

    desc  <- .dx_job_describe(job_id)
    state <- desc$state
    hms   <- sprintf(
      "%02d:%02d:%02d",
      elapsed %/% 3600L, (elapsed %% 3600L) %/% 60L, elapsed %% 60L
    )

    if (verbose) {
      symbol <- if (state == "done") "\u2714" else if (state == "failed") "\u2716" else "\u25cb"
      cli::cli_inform("{symbol} [{hms}] {job_id} \u2014 {state}")
    }

    if (state %in% terminal) break

    Sys.sleep(interval)
  }

  if (state == "failed") {
    msg <- if (!is.null(desc$failureMessage)) desc$failureMessage else
           if (!is.null(desc$failureReason))  desc$failureReason  else
           "(no message)"
    stop(sprintf("Job %s failed: %s", job_id, msg), call. = FALSE)
  }

  if (state == "terminated") {
    stop(sprintf("Job %s was terminated.", job_id), call. = FALSE)
  }

  invisible(state)
}


#' Download and load the result CSV of a completed DNAnexus job
#'
#' Retrieves the output CSV produced by a \code{extract_batch()} job.
#' Reuses the \code{fetch_} download infrastructure: generates a
#' pre-authenticated URL via \code{dx make_download_url} and downloads
#' with \code{curl}, supporting resume and overwrite.
#'
#' @param job_id (character) Job ID returned by \code{extract_batch()}.
#' @param dest (character) Local path to save the CSV, e.g.
#'   \code{"data/pheno.csv"}. Default: \code{NULL} (auto-generate as
#'   \code{"data/<output_name>.csv"}).
#' @param overwrite (logical) Overwrite an existing local file. Default:
#'   \code{FALSE}.
#' @param resume (logical) Resume an interrupted download. Default:
#'   \code{FALSE}.
#' @param read (logical) Read the downloaded CSV into R with
#'   \code{data.table::fread()} and return a \code{data.table}. Set to
#'   \code{FALSE} to download only. Default: \code{TRUE}.
#'
#' @return If \code{read = TRUE}, a \code{data.table} with one row per
#'   participant. If \code{read = FALSE}, invisibly returns \code{dest}.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download and load
#' df <- job_result(job_id)
#'
#' # Download to a specific path, load later
#' job_result(job_id, dest = "data/ad_pheno.csv", read = FALSE)
#' df <- data.table::fread("data/ad_pheno.csv")
#'
#' # Resume a partially downloaded large file
#' job_result(job_id, dest = "data/pheno.csv", resume = TRUE)
#' }
job_result <- function(job_id, dest = NULL, overwrite = FALSE,
                       resume = FALSE, read = TRUE) {
  if (!grepl("^job-", job_id)) {
    stop("job_id must be a 'job-XXXX' string.", call. = FALSE)
  }

  desc  <- .dx_job_describe(job_id)
  state <- desc$state

  if (state != "done") {
    stop(
      sprintf(
        "Job %s is '%s', not 'done'. Use job_wait() to wait for completion.",
        job_id, state
      ),
      call. = FALSE
    )
  }

  file_id  <- .dx_job_output_id(desc)
  out_name <- .dx_job_output_name(desc)

  # Auto-generate dest from job output name
  if (is.null(dest)) {
    if (!dir.exists("data")) dir.create("data", recursive = TRUE)
    dest <- file.path("data", paste0(out_name, ".csv"))
  } else {
    dest_dir <- dirname(dest)
    if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  }

  cli::cli_inform("Downloading {.val {paste0(out_name, '.csv')}} \u2192 {.file {dest}}")

  # Reason: reuse fetch_ download infrastructure — .dx_make_url() accepts
  # file IDs directly (not just paths), and .dx_download_file() provides
  # resume/overwrite/progress support via curl
  url <- .dx_make_url(file_id)
  .dx_download_file(url, dest, overwrite = overwrite, resume = resume,
                    verbose = TRUE)

  cli::cli_inform("Saved: {.file {dest}}")

  if (!read) return(invisible(dest))

  # Reason: integer64 = "double" avoids bit64 dependency; UKB eids are
  # 7-digit integers, well within double precision range
  dt <- data.table::fread(dest, data.table = TRUE, integer64 = "double")
  cli::cli_inform("\u2714 {nrow(dt)} rows \u00d7 {ncol(dt)} cols (incl. eid)")
  dt
}


#' List recent DNAnexus jobs in the current project
#'
#' Returns a summary of the most recent jobs, optionally filtered by state.
#' Useful for quickly reviewing which jobs have completed, failed, or are
#' still running.
#'
#' @param n (integer) Maximum number of recent jobs to return. Default:
#'   \code{20}.
#' @param state (character) Filter by state(s), e.g. \code{"failed"} or
#'   \code{c("done", "failed")}. Default: \code{NULL} (return all).
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
  result <- .dx_find_jobs_raw(n)
  if (!result$success) {
    stop("Failed to list jobs: ", result$stderr, call. = FALSE)
  }

  df <- .dx_parse_jobs(result$stdout)

  if (!is.null(state) && nrow(df) > 0) {
    df <- df[df$state %in% state, , drop = FALSE]
  }

  df
}
