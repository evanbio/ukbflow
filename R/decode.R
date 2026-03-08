# =============================================================================
# decode.R - UKB column name and value decoding
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
      "Field dictionary not cached - calling {.fn extract_ls} to populate it."
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
      "{length(long_cols)} column name{?s} longer than {max_nchar} characters - consider renaming manually:"
    )
    cli::cli_ul(long_cols)
  }

  data
}


#' Decode UKB categorical column values using Showcase metadata
#'
#' Converts raw integer codes produced by \code{\link{extract_pheno}} into
#' human-readable labels for all categorical fields
#' (\code{value_type} 21 and 22), using the UKB Showcase encoding tables.
#' Continuous, text, date, and already-decoded columns are left unchanged.
#'
#' This function requires two metadata files downloaded from the UKB Research
#' Analysis Platform:
#' \itemize{
#'   \item \code{field.tsv} - maps field IDs to encoding IDs and value types.
#'   \item \code{esimpint.tsv} - maps encoding ID + integer code to label.
#' }
#' Download them once with:
#' \preformatted{
#' fetch_file("Showcase metadata/field.tsv",    dest_dir = "data/metadata/")
#' fetch_file("Showcase metadata/esimpint.tsv", dest_dir = "data/metadata/")
#' }
#' Both files are cached in the session after the first read.
#'
#' \strong{Call order}: use \code{decode_values()} \emph{before}
#' \code{\link{decode_names}}, so that column names still contain the numeric
#' field ID needed to look up the encoding.
#'
#' @param data (data.frame or data.table) Data from \code{extract_pheno()},
#'   with column names in \code{participant.pXXXX} or \code{pXXXX_iX} format.
#' @param metadata_dir (character) Directory containing \code{field.tsv} and
#'   \code{esimpint.tsv}. Default: \code{"data/metadata/"}.
#'
#' @return The input \code{data} with categorical columns replaced by character
#'   labels. Returns a \code{data.table} if the input is a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download metadata once
#' fetch_file("Showcase metadata/field.tsv",    dest_dir = "data/metadata/")
#' fetch_file("Showcase metadata/esimpint.tsv", dest_dir = "data/metadata/")
#'
#' # Recommended call order
#' df <- extract_pheno(c(31, 54, 20116, 21000))
#' df <- decode_values(df)                  # 0/1 → "Female"/"Male", etc.
#' df <- decode_names(df)                   # participant.p31 → sex
#' }
decode_values <- function(data, metadata_dir = "data/metadata/") {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }

  col_names <- names(data)

  # Auto-detect UKB field columns: must still contain numeric field ID
  target_cols <- col_names[grepl("(?<![a-z])p\\d+", col_names, perl = TRUE)]

  if (length(target_cols) == 0) {
    cli::cli_alert_warning(
      "No UKB field ID columns detected. Call {.fn decode_values} before {.fn decode_names}."
    )
    return(invisible(data))
  }

  # Load metadata (hits cache after first call)
  field_meta <- .load_field_meta(metadata_dir)
  esimpint   <- .load_esimpint(metadata_dir)

  # Subset to categorical fields with a real encoding
  cat_fields <- field_meta[
    field_meta$value_type %in% c(21L, 22L) & field_meta$encoding_id > 0L, ,
    drop = FALSE
  ]

  n_decoded <- 0L
  n_skipped <- 0L

  for (col in target_cols) {

    # Skip columns already decoded to character (e.g. job_result() output)
    if (is.character(data[[col]])) { n_skipped <- n_skipped + 1L; next }

    fid <- .extract_field_id(col)
    if (is.na(fid)) { n_skipped <- n_skipped + 1L; next }

    enc_row <- cat_fields[cat_fields$field_id == fid, , drop = FALSE]
    if (nrow(enc_row) == 0) { n_skipped <- n_skipped + 1L; next }

    enc_id  <- enc_row$encoding_id[1L]
    mapping <- esimpint[esimpint$encoding_id == enc_id, , drop = FALSE]
    if (nrow(mapping) == 0) { n_skipped <- n_skipped + 1L; next }

    # Reason: match() returns NA for any code absent from the encoding table,
    # which naturally covers UKB missing codes (-1, -3, -7, -13, -818)
    # when they are not listed as valid entries in that encoding
    data[[col]] <- mapping$meaning[match(data[[col]], mapping$value)]
    n_decoded   <- n_decoded + 1L
  }

  cli::cli_alert_success(
    "Decoded {n_decoded} categorical column{?s}; {n_skipped} non-categorical column{?s} unchanged."
  )

  data
}
