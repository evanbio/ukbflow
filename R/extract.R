# =============================================================================
# extract.R — Dataset field listing and phenotype data extraction
# =============================================================================


#' List all approved fields in the UKB dataset
#'
#' Returns a data.frame of all fields available for extraction in the current
#' UKB project dataset. Fields reflect what has been approved for your project
#' — not all UKB fields are present.
#'
#' Results are cached in the session after the first call. Subsequent calls
#' return instantly from cache. Use \code{refresh = TRUE} to force a new
#' network request (e.g. after switching projects).
#'
#' @param dataset (character) Dataset file name, e.g.
#'   \code{"app12345_20260101.dataset"}. Default: \code{NULL} (auto-detect).
#' @param pattern (character) Optional regex to filter results by
#'   \code{field_name} or \code{title}. Default: \code{NULL}.
#' @param refresh (logical) Force re-fetch from cloud, ignoring cache.
#'   Default: \code{FALSE}.
#'
#' @return A data.frame with columns:
#'   \describe{
#'     \item{field_name}{Full field name as used in extraction, e.g.
#'       \code{"participant.p31"}, \code{"participant.p53_i0"}.}
#'     \item{title}{Human-readable field description, e.g.
#'       \code{"Sex"}, \code{"Date of attending assessment centre | Instance 0"}.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' # List all approved fields
#' extract_ls()
#'
#' # Search by keyword
#' extract_ls(pattern = "cancer")
#' extract_ls(pattern = "p31|p53|p22009")
#'
#' # Force refresh after switching projects
#' extract_ls(refresh = TRUE)
#' }
extract_ls <- function(dataset = NULL, pattern = NULL, refresh = FALSE) {

  # Reason: auto-detect before cache check so cache is keyed by dataset name —
  # prevents returning stale fields after switching datasets or projects
  if (is.null(dataset)) {
    dataset <- .dx_find_dataset()
    cli::cli_inform("Using dataset: {.val {dataset}}")
  }

  # Return from per-dataset cache if available and refresh not requested
  if (!is.null(.ukbflow_cache$fields[[dataset]]) && !refresh) {
    df <- .ukbflow_cache$fields[[dataset]]
    if (!is.null(pattern)) {
      return(df[
        grepl(pattern, df$field_name, perl = TRUE) |
        grepl(pattern, df$title,      perl = TRUE, ignore.case = TRUE),
        , drop = FALSE
      ])
    }
    cli::cli_inform("{nrow(df)} fields available. Assign to a variable or use pattern= to search.")
    return(invisible(df))
  }

  cli::cli_inform("Fetching approved fields... (cached after first call)")

  result <- .dx_list_fields_raw(dataset)
  if (!result$success) {
    cli::cli_abort("Failed to list fields: {result$stderr}", call = NULL)
  }

  df <- .dx_parse_fields(result$stdout)

  # Store in per-dataset cache slot
  .ukbflow_cache$fields[[dataset]] <- df

  if (!is.null(pattern)) {
    df <- df[
      grepl(pattern, df$field_name, perl = TRUE) |
      grepl(pattern, df$title,      perl = TRUE, ignore.case = TRUE),
      , drop = FALSE
    ]
    return(df)
  }

  # Reason: returning all 29,000+ rows visibly floods the console;
  # return invisibly and show a summary message instead
  cli::cli_inform("{nrow(df)} fields available. Assign to a variable or use pattern= to search.")
  invisible(df)
}


#' Extract phenotype data from a UKB dataset
#'
#' Extracts phenotypic fields from the UKB Research Analysis Platform dataset
#' and returns a \code{data.table}. All instances and arrays are returned for
#' each requested field. Column names are kept as-is (e.g.
#' \code{participant.p53_i0}); use the \code{clean_} series for renaming.
#'
#' @param field_id (integer) Vector of UKB Field IDs to extract, e.g.
#'   \code{c(31, 53, 22189)}. \code{eid} is always included automatically.
#' @param dataset (character) Dataset file name. Default: \code{NULL}
#'   (auto-detect from project root).
#' @param timeout (integer) Extraction timeout in seconds. Default: \code{300}.
#'
#' @return A \code{data.table} with one row per participant. Column names
#'   follow the \code{participant.p<id>_i<n>_a<m>} convention.
#'   Fields not found are skipped with a warning.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(31, 53, 21022))
#' df <- extract_pheno(c(31, 53, 20002), dataset = "app12345_20260101.dataset")
#' }
extract_pheno <- function(field_id, dataset = NULL, timeout = 300) {

  if (!.is_on_rap()) {
    cli::cli_abort(
      c("extract_pheno() must be run inside the RAP environment.",
        "i" = "For large-scale extraction, use extract_batch() instead."),
      call = NULL
    )
  }

  field_id <- .assert_integer_ids(field_id)

  dest <- tempfile(fileext = ".csv")
  on.exit(unlink(dest), add = TRUE)

  # Auto-detect dataset
  if (is.null(dataset)) {
    dataset <- .dx_find_dataset()
  }
  cli::cli_inform("Using dataset: {.val {dataset}}")

  # Get approved fields list (uses session cache after first call)
  fields_df <- extract_ls(dataset = dataset)

  # Match field IDs to exact column names
  match_result <- .dx_match_fields(field_id, fields_df)
  matched      <- match_result$matched
  unmatched    <- match_result$unmatched

  if (length(matched) == 0) {
    cli::cli_abort(
      "No matching fields found. Run extract_ls() to see available fields.",
      call = NULL
    )
  }

  # Report matched fields
  n_cols_total <- sum(vapply(matched, `[[`, integer(1), "n_cols"))
  cli::cli_inform(
    "Matched {length(matched)}/{length(field_id)} field{?s} ({n_cols_total} column{?s})"
  )

  # Reason: cap per-field listing to avoid console flood on large extractions
  show_all    <- length(matched) <= 10
  preview_n   <- if (show_all) length(matched) else 5

  for (m in matched[seq_len(preview_n)]) {
    col_label <- if (m$n_cols == 1) "1 col" else paste0(m$n_cols, " cols")
    cli::cli_inform("  p{m$field_id}  {m$title}  [{col_label}]")
  }
  if (!show_all) {
    cli::cli_inform(
      "  ... and {length(matched) - preview_n} more fields. Use extract_ls() to review all."
    )
  }

  # Warn about unmatched fields
  if (length(unmatched) > 0) {
    cli::cli_warn(
      "Field ID{?s} not found and skipped: {.val {unmatched}}"
    )
  }

  # Build final field list (eid always first)
  all_fields <- c(
    "participant.eid",
    unlist(lapply(matched, `[[`, "field_names"))
  )

  # Run extraction — output saved to disk
  cli::cli_inform("Extracting data...")
  result <- .dx_extract_run(dataset, all_fields, dest, timeout = timeout)

  if (!result$success) {
    cli::cli_abort("Extraction failed: {result$stderr}", call = NULL)
  }

  cli::cli_inform("Saved: {.file {dest}}")

  # Read with data.table for performance on large UKB files
  # Reason: integer64 = "double" avoids bit64 compatibility issues;
  # UKB eids are 7-digit integers, well within double precision range
  dt <- data.table::fread(dest, data.table = TRUE, integer64 = "double")

  cli::cli_inform(
    "{nrow(dt)} rows x {ncol(dt)} cols (incl. eid)"
  )

  dt
}


#' Submit a large-scale phenotype extraction job via table-exporter
#'
#' Submits an asynchronous table-exporter job on the DNAnexus Research
#' Analysis Platform for large-scale phenotype extraction. Use this instead
#' of \code{extract_pheno()} when extracting many fields (e.g. 50+).
#'
#' The job runs on the cloud and typically completes in 20-40 minutes.
#' Monitor progress and retrieve results using the \code{job_} series.
#'
#' @param field_id (integer) Vector of UKB Field IDs to extract.
#'   \code{eid} is always included automatically.
#' @param dataset (character) Dataset file name. Default: \code{NULL}
#'   (auto-detect from project root).
#' @param file (character) Output file name on the cloud (without extension),
#'   e.g. \code{"ad_cscc_pheno"}. Default: \code{NULL} (auto-generate as
#'   \code{"ukb_pheno_YYYYMMDD_HHMMSS"} to avoid same-day collisions).
#' @param instance_type (character) DNAnexus instance type, e.g.
#'   \code{"mem1_ssd1_v2_x16"}. Default: \code{NULL} (auto-select:
#'   \code{x4} for up to 20 cols, \code{x8} for up to 100 cols,
#'   \code{x16} for up to 500 cols, \code{x36} for more than 500 cols).
#' @param priority (character) Job scheduling priority. \code{"low"}
#'   (recommended, cheaper) or \code{"high"} (faster queue). Default:
#'   \code{"low"}.
#'
#' @return Invisibly returns the job ID string (e.g. \code{"job-XXXX"}).
#' @export
#'
#' @examples
#' \dontrun{
#' job_id <- extract_batch(core_field_ids)
#' job_id <- extract_batch(core_field_ids, file = "ad_cscc_pheno")
#' job_id <- extract_batch(core_field_ids, priority = "high")
#' # Monitor: job_status(job_id)
#' # Download: job_result(job_id, dest = "data/pheno.csv")
#' }
extract_batch <- function(field_id, dataset = NULL, file = NULL,
                          instance_type = NULL, priority = c("low", "high")) {
  priority <- match.arg(priority)

  field_id <- .assert_integer_ids(field_id)

  # Auto-detect dataset
  if (is.null(dataset)) {
    dataset <- .dx_find_dataset()
  }
  cli::cli_inform("Using dataset: {.val {dataset}}")

  # Get approved fields list (uses session cache)
  fields_df <- extract_ls(dataset = dataset)

  # Match field IDs to exact column names
  match_result <- .dx_match_fields(field_id, fields_df)
  matched      <- match_result$matched
  unmatched    <- match_result$unmatched

  if (length(matched) == 0) {
    cli::cli_abort(
      "No matching fields found. Run extract_ls() to see available fields.",
      call = NULL
    )
  }

  # Report matched fields
  n_cols_total <- sum(vapply(matched, `[[`, integer(1), "n_cols"))
  cli::cli_inform(
    "Matched {length(matched)}/{length(field_id)} field{?s} ({n_cols_total} column{?s})"
  )

  show_all  <- length(matched) <= 10
  preview_n <- if (show_all) length(matched) else 5
  for (m in matched[seq_len(preview_n)]) {
    col_label <- if (m$n_cols == 1) "1 col" else paste0(m$n_cols, " cols")
    cli::cli_inform("  p{m$field_id}  {m$title}  [{col_label}]")
  }
  if (!show_all) {
    cli::cli_inform(
      "  ... and {length(matched) - preview_n} more fields. Use extract_ls() to review all."
    )
  }
  if (length(unmatched) > 0) {
    cli::cli_warn("Field ID{?s} not found and skipped: {.val {unmatched}}")
  }

  # Build field names: strip participant. prefix (table-exporter format)
  # Reason: table-exporter expects "eid", "p31", "p53_i0" without entity prefix
  all_fields <- c(
    "eid",
    gsub("^participant\\.", "", unlist(lapply(matched, `[[`, "field_names")))
  )

  # Write and upload fields file
  fields_file <- tempfile(fileext = ".txt")
  on.exit(unlink(fields_file), add = TRUE)
  # Reason: open in binary mode to force LF-only line endings — on Windows
  # text-mode writeLines() produces CRLF, which table-exporter rejects as
  # "invalid characters in field names"
  con <- file(fields_file, open = "wb")
  writeLines(all_fields, con = con, sep = "\n")
  close(con)

  cli::cli_inform("Uploading field list...")
  file_id <- .dx_upload_file(fields_file)

  # Auto output name: add HMS to avoid same-day collisions
  output <- if (!is.null(file)) file else
    paste0("ukb_pheno_", format(Sys.time(), "%Y%m%d_%H%M%S"))

  # Auto instance type based on column count (four tiers)
  instance_type <- if (!is.null(instance_type)) instance_type else
    if (n_cols_total > 500) "mem1_ssd1_v2_x36" else
    if (n_cols_total > 100) "mem1_ssd1_v2_x16" else
    if (n_cols_total > 20)  "mem1_ssd1_v2_x8"  else
                            "mem1_ssd1_v2_x4"

  # Submit job
  cli::cli_inform("Submitting table-exporter job...")
  job_id <- .dx_run_table_exporter(dataset, file_id, output, instance_type,
                                    priority = priority)

  cli::cli_inform("Job submitted: {.val {job_id}}")
  cli::cli_inform("  Output  : {output}.csv  (cloud)")
  cli::cli_inform("  Instance: {instance_type}")

  invisible(job_id)
}
