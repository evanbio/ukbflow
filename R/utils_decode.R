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


#' Extract the UKB field ID integer from a column name
#'
#' @param col_name (character) Column name such as \code{"participant.p31"},
#'   \code{"p31"}, or \code{"p53_i0_a1"}.
#' @return Integer field ID, or \code{NA_integer_} if none found.
#'
#' @keywords internal
#' @noRd
.extract_field_id <- function(col_name) {
  # Reason: anchor on literal "p" followed by digits; strips any prefix
  # (participant.) and any suffix (_i0, _a1, etc.)
  m <- regmatches(col_name, regexpr("(?<![a-z])p(\\d+)", col_name, perl = TRUE))
  if (length(m) == 0 || nchar(m) == 0) return(NA_integer_)
  as.integer(sub("p", "", m, fixed = TRUE))
}


#' Load and cache field.tsv metadata
#'
#' Reads \code{field.tsv} from \code{metadata_dir}, retaining only the columns
#' needed for value decoding (\code{field_id}, \code{value_type},
#' \code{encoding_id}). Result is cached in \code{.ukbflow_cache$field_meta}.
#'
#' @param metadata_dir (character) Directory containing \code{field.tsv}.
#' @return data.frame with columns \code{field_id}, \code{value_type},
#'   \code{encoding_id}.
#'
#' @keywords internal
#' @noRd
.load_field_meta <- function(metadata_dir) {
  if (!is.null(.ukbflow_cache$field_meta)) return(.ukbflow_cache$field_meta)

  path <- file.path(metadata_dir, "field.tsv")
  if (!file.exists(path)) {
    stop(
      "field.tsv not found in '", metadata_dir, "'. ",
      "Run fetch_file(\"Showcase metadata/field.tsv\", dest_dir = \"",
      metadata_dir, "\") first.",
      call. = FALSE
    )
  }

  # Reason: select only 3 columns to keep memory footprint small (~3.5 MB raw)
  df <- data.table::fread(
    path,
    select      = c("field_id", "value_type", "encoding_id"),
    data.table  = FALSE
  )
  .ukbflow_cache$field_meta <- df
  df
}


#' Load and cache esimpint.tsv encoding table
#'
#' Reads \code{esimpint.tsv} from \code{metadata_dir} and caches it in
#' \code{.ukbflow_cache$esimpint}. This table maps
#' \code{encoding_id + value → meaning} for simple integer-encoded categorical
#' fields (UKB \code{value_type} 21 and 22).
#'
#' @param metadata_dir (character) Directory containing \code{esimpint.tsv}.
#' @return data.frame with columns \code{encoding_id}, \code{value},
#'   \code{meaning}.
#'
#' @keywords internal
#' @noRd
.load_esimpint <- function(metadata_dir) {
  if (!is.null(.ukbflow_cache$esimpint)) return(.ukbflow_cache$esimpint)

  path <- file.path(metadata_dir, "esimpint.tsv")
  if (!file.exists(path)) {
    stop(
      "esimpint.tsv not found in '", metadata_dir, "'. ",
      "Run fetch_file(\"Showcase metadata/esimpint.tsv\", dest_dir = \"",
      metadata_dir, "\") first.",
      call. = FALSE
    )
  }

  df <- data.table::fread(
    path,
    select     = c("encoding_id", "value", "meaning"),
    data.table = FALSE
  )
  .ukbflow_cache$esimpint <- df
  df
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
