# =============================================================================
# decode.R — UKB column name and value decoding
# =============================================================================


#' Rename UKB field ID columns to human-readable snake_case names
#'
#' Renames columns from the raw UKB field ID format used by
#' \code{\link{extract_pheno}} (e.g. \code{participant.p31}) and
#' \code{\link{job_result}} (e.g. \code{p53_i0}) to human-readable
#' snake_case identifiers (e.g. \code{sex},
#' \code{date_of_attending_assessment_centre_i0}).
#'
#' Column labels are taken from the UKB field title dictionary cached by
#' \code{\link{extract_ls}}. The cache is populated automatically when
#' \code{extract_pheno()} or \code{extract_batch()} is called; if it is
#' empty, \code{decode_names()} calls \code{extract_ls()} itself.
#'
#' When an auto-generated name exceeds \code{max_nchar} characters it is
#' flagged with a warning so you can decide whether to shorten it manually
#' with \code{names(data)[...] <- ...}. The function never truncates names
#' automatically, because the right short name depends on scientific context
#' that only you know.
#'
#' @param data (data.frame or data.table) Data extracted from UKB-RAP via
#'   \code{extract_pheno()} or \code{job_result()}.
#' @param max_nchar (integer) Column names longer than this value are flagged.
#'   Default: \code{60}.
#'
#' @return The input \code{data} with column names replaced by snake_case
#'   labels. Returns a \code{data.table} if the input is a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(31, 53, 21022))
#' df <- decode_names(df)
#' # participant.eid    → eid
#' # participant.p31    → sex
#' # participant.p21022 → age_at_recruitment
#' # participant.p53_i0 → date_of_attending_assessment_centre_i0  (warned if > 30)
#'
#' # Shorten a long name afterwards
#' names(df)[names(df) == "date_of_attending_assessment_centre_i0"] <- "date_baseline"
#' }
decode_names <- function(data, max_nchar = 60L) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.numeric(max_nchar) || length(max_nchar) != 1L || max_nchar < 1L) {
    stop("max_nchar must be a single positive integer.", call. = FALSE)
  }

  col_names <- names(data)

  # Use cached field dictionary; fetch from network only if cache is empty
  fields_df <- .ukbflow_cache$fields
  if (is.null(fields_df)) {
    cli::cli_inform(
      "Field dictionary not cached — calling {.fn extract_ls} to populate it."
    )
    fields_df <- extract_ls()
  }

  # Build old → new name vector (positionally aligned with col_names)
  new_names <- .build_name_map(col_names, fields_df)

  # Apply renaming; make.unique() guards against duplicate titles in the
  # UKB field dictionary producing identical snake_case names
  names(data) <- make.unique(new_names, sep = "_")

  n_renamed <- sum(new_names != col_names, na.rm = TRUE)
  cli::cli_alert_success("Renamed {n_renamed} column{?s}.")

  # Flag names that exceed the character limit
  long_cols <- new_names[nchar(new_names) > max_nchar]
  if (length(long_cols) > 0) {
    cli::cli_alert_warning(
      "{length(long_cols)} column name{?s} longer than {max_nchar} characters \\
       \u2014 consider renaming manually:"
    )
    cli::cli_ul(long_cols)
  }

  data
}
