# =============================================================================
# utils_extract.R — Internal helpers for extract_ series
# Depends on .dx_run() defined in utils_auth.R
# =============================================================================


# Reason: session-level cache avoids repeated --list-fields network requests
# (29,951 rows, takes several seconds each time)
.ukbflow_cache <- new.env(parent = emptyenv())


#' Detect whether the current session is running inside the RAP environment
#'
#' @keywords internal
#' @noRd
.is_on_rap <- function() {
  on_cloud   <- nzchar(Sys.getenv("DX_PROJECT_CONTEXT_ID")) ||
                nzchar(Sys.getenv("DX_JOB_ID"))
  mount_exists <- dir.exists("/mnt/project")
  on_cloud || mount_exists
}


#' Find the most recent .dataset file in the project root
#'
#' @return Character string — the dataset file name.
#'
#' @keywords internal
#' @noRd
.dx_find_dataset <- function() {
  # Reason: dataset name is stable for the session — cache avoids repeated
  # dx ls network calls (e.g. from extract_ls(), decode_names(), etc.)
  if (!is.null(.ukbflow_cache$dataset)) return(.ukbflow_cache$dataset)

  result <- .dx_run("ls", timeout = 30)
  if (!result$success) {
    cli::cli_abort("Failed to list project files: {result$stderr}", call = NULL)
  }

  lines    <- strsplit(result$stdout, "\n")[[1]]
  lines    <- trimws(lines[nzchar(lines)])
  datasets <- lines[grepl("\\.dataset$", lines)]

  if (length(datasets) == 0) {
    cli::cli_abort(
      c("No {.file .dataset} file found in project root.",
        "i" = "Use {.fn fetch_ls} to verify your project contents."),
      call = NULL
    )
  }

  # Reason: multiple datasets may exist (different dates); take the latest
  dataset <- trimws(datasets[length(datasets)])
  .ukbflow_cache$dataset <- dataset
  dataset
}


#' Run dx extract_dataset --list-fields and return raw output
#'
#' @param dataset (character) Dataset file name.
#' @param timeout (integer) Timeout in seconds. Default: 120.
#' @return Named list with stdout, stderr, status, success.
#'
#' @keywords internal
#' @noRd
.dx_list_fields_raw <- function(dataset, timeout = 120) {
  # Reason: PYTHONIOENCODING=utf-8 is required on Windows — the --list-fields
  # output contains non-ASCII characters that crash colorama under GBK encoding
  .dx_run(
    c("extract_dataset", dataset, "--list-fields", "--entities", "participant"),
    timeout = timeout,
    env     = c(PYTHONIOENCODING = "utf-8")
  )
}


#' Match integer field IDs to exact column names in the dataset
#'
#' @param field_id (integer) Vector of field IDs, e.g. \code{c(31, 53, 22189)}.
#' @param fields_df (data.frame) Output of \code{extract_ls()}.
#' @return A list with:
#'   \itemize{
#'     \item \code{matched} — list of per-field info (field_id, field_names,
#'       title, n_cols)
#'     \item \code{unmatched} — integer vector of field IDs with no match
#'   }
#'
#' @keywords internal
#' @noRd
.dx_match_fields <- function(field_id, fields_df) {
  matched   <- list()
  unmatched <- integer(0)

  for (fid in field_id) {
    # Reason: anchor pattern prevents p31 matching p310xx, p311xx, etc.
    pattern <- paste0("^participant\\.p", fid, "(_|$)")
    hits    <- fields_df[grepl(pattern, fields_df$field_name, perl = TRUE), , drop = FALSE]

    if (nrow(hits) == 0) {
      unmatched <- c(unmatched, fid)
    } else {
      # Strip " | Instance X | Array Y" suffix to get base title
      base_title <- sub("\\s*\\|.*$", "", hits$title[1])
      matched[[length(matched) + 1]] <- list(
        field_id    = fid,
        field_names = hits$field_name,
        title       = trimws(base_title),
        n_cols      = nrow(hits)
      )
    }
  }

  list(matched = matched, unmatched = unmatched)
}


#' Run dx extract_dataset --fields-file and write output CSV
#'
#' @param dataset (character) Dataset file name.
#' @param fields (character) Character vector of full field names to extract,
#'   e.g. \code{c("participant.eid", "participant.p31", "participant.p53_i0")}.
#' @param out_path (character) Local path for the output CSV.
#' @param timeout (integer) Timeout in seconds. Default: 300.
#' @return Named list with stdout, stderr, status, success.
#'
#' @keywords internal
#' @noRd
.dx_extract_run <- function(dataset, fields, out_path, timeout = 300) {
  fields_file <- tempfile(fileext = ".txt")
  on.exit(unlink(fields_file))
  # Reason: same CRLF fix as extract_batch() — dx extract_dataset also rejects
  # Windows-style line endings in the fields file
  con <- file(fields_file, open = "wb")
  writeLines(fields, con = con, sep = "\n")
  close(con)

  .dx_run(
    c("extract_dataset", dataset, "--fields-file", fields_file, "-o", out_path),
    timeout = timeout,
    env     = c(PYTHONIOENCODING = "utf-8")
  )
}


#' Upload a local file to DNAnexus project root
#'
#' @param local_path (character) Path to the local file to upload.
#' @return Character string — the DNAnexus file ID (e.g. \code{"file-XXXX"}).
#'
#' @keywords internal
#' @noRd
.dx_upload_file <- function(local_path) {
  result <- .dx_run(c("upload", local_path, "--brief"), timeout = 60)
  if (!result$success) {
    stop("Failed to upload field list: ", result$stderr, call. = FALSE)
  }
  trimws(result$stdout)
}


#' Submit a table-exporter job on DNAnexus
#'
#' @param dataset (character) Dataset file name.
#' @param file_id (character) DNAnexus file ID of the uploaded fields file.
#' @param output (character) Output file name (without extension).
#' @param instance_type (character) DNAnexus instance type.
#' @param priority (character) Job priority: \code{"low"} or \code{"high"}.
#' @return Character string — the job ID (e.g. \code{"job-XXXX"}).
#'
#' @keywords internal
#' @noRd
.dx_run_table_exporter <- function(dataset, file_id, output, instance_type,
                                   priority = "low") {
  result <- .dx_run(
    c(
      "run", "table-exporter",
      paste0("-idataset_or_cohort_or_dashboard=", dataset),
      "-ientity=participant",
      paste0("-ifield_names_file_txt=", file_id),
      paste0("-ioutput=", output),
      "-ioutput_format=CSV",
      paste0("--instance-type=", instance_type),
      "--priority", priority,
      "--brief", "--yes"
    ),
    timeout = 60
  )
  if (!result$success) {
    stop("Failed to submit table-exporter job: ", result$stderr, call. = FALSE)
  }
  job_id <- trimws(result$stdout)
  # Reason: validate job_id format — a successful submission always returns
  # a "job-XXXX" string; anything else indicates a silent failure
  if (!grepl("^job-", job_id)) {
    stop("Unexpected response from table-exporter: ", job_id, call. = FALSE)
  }
  job_id
}


#' Parse --list-fields tab-separated output into a data.frame
#'
#' @param stdout (character) Raw stdout from dx extract_dataset --list-fields.
#' @return data.frame with columns: field_name, title.
#'
#' @keywords internal
#' @noRd
.dx_parse_fields <- function(stdout) {
  lines <- strsplit(stdout, "\n")[[1]]
  lines <- trimws(lines[nzchar(lines)])

  if (length(lines) == 0) {
    return(data.frame(
      field_name = character(0),
      title      = character(0),
      stringsAsFactors = FALSE
    ))
  }

  parts <- strsplit(lines, "\t")

  data.frame(
    field_name = vapply(parts, `[`, character(1), 1),
    title      = vapply(
      parts,
      function(x) if (length(x) >= 2) x[2] else NA_character_,
      character(1)
    ),
    stringsAsFactors = FALSE
  )
}
