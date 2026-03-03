# =============================================================================
# utils_decode.R — Internal helpers for decode_ series
# =============================================================================


#' Convert a UKB field title to a snake_case column name
#'
#' Parses the UKB field title format (e.g.
#' \code{"Date of attending assessment centre | Instance 0"}) into a
#' compact snake_case identifier (e.g.
#' \code{"date_of_attending_assessment_centre_i0"}).
#'
#' @param title (character) Single UKB field title string.
#' @return (character) Snake_case column name.
#'
#' @keywords internal
#' @noRd
.title_to_snake <- function(title) {

  # Extract "| Instance X" → suffix "_iX"
  inst_m <- regmatches(title, regexpr("\\|\\s*Instance\\s+(\\d+)", title, perl = TRUE))
  inst_suffix <- if (length(inst_m) > 0 && nchar(inst_m) > 0) {
    paste0("_i", sub(".*?(\\d+)$", "\\1", inst_m, perl = TRUE))
  } else {
    ""
  }

  # Extract "| Array X" → suffix "_aX"
  arr_m <- regmatches(title, regexpr("\\|\\s*Array\\s+(\\d+)", title, perl = TRUE))
  arr_suffix <- if (length(arr_m) > 0 && nchar(arr_m) > 0) {
    paste0("_a", sub(".*?(\\d+)$", "\\1", arr_m, perl = TRUE))
  } else {
    ""
  }

  # Extract base label (everything before the first "|")
  base <- trimws(sub("\\s*\\|.*$", "", title))

  # Convert base to snake_case
  # Reason: if base somehow contains only special characters the two gsub()
  # calls below would yield ""; this is unreachable in practice because
  # .build_name_map() only calls here after a successful match() in fields_df
  base <- tolower(base)
  base <- gsub("[^a-z0-9]+", "_", base)
  base <- gsub("^_+|_+$", "", base)   # strip leading/trailing underscores

  paste0(base, inst_suffix, arr_suffix)
}


#' Build a mapping from raw UKB column names to snake_case names
#'
#' Handles both \code{extract_pheno()} output (\code{participant.pXXXX})
#' and \code{job_result()} output (\code{pXXXX_iX}).
#'
#' @param col_names (character) Column names from the input data.
#' @param fields_df (data.frame) Output of \code{extract_ls()}, with columns
#'   \code{field_name} and \code{title}.
#' @return Character vector (same length as \code{col_names}) of new
#'   snake_case column names.
#'
#' @keywords internal
#' @noRd
.build_name_map <- function(col_names, fields_df) {
  vapply(col_names, function(col) {

    # Special case: participant ID column always stays "eid"
    if (col %in% c("eid", "participant.eid")) return("eid")

    # Normalise lookup key: ensure "participant." prefix for dictionary lookup
    lookup_key <- if (grepl("^participant\\.", col, perl = TRUE)) {
      col
    } else {
      paste0("participant.", col)
    }

    idx <- match(lookup_key, fields_df$field_name)

    if (is.na(idx)) {
      # Reason: fallback preserves column rather than silently dropping it;
      # should not occur if extract_ls() cache is fully populated
      return(sub("^participant\\.", "", col))
    }

    .title_to_snake(fields_df$title[idx])

  }, character(1), USE.NAMES = FALSE)
}
