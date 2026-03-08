# =============================================================================
# utils_derive.R — internal helpers for derive_ series
# =============================================================================


# Null-coalescing operator: return lhs unless it is NULL, then return rhs.
# Defined internally to avoid importing rlang just for this operator.
`%||%` <- function(lhs, rhs) if (!is.null(lhs)) lhs else rhs


# UKB labels that carry informative missingness (refusal / uncertainty).
# These are converted to NA or "Unknown" depending on the action parameter.
# "" (empty string) is handled separately — always converted to NA.
.ukb_informative_missing <- c(
  "Do not know",
  "Prefer not to answer",
  "Prefer not to say"
)


# Print a cli summary line for a numeric column.
# Used by derive_covariate() and derive_cut().
.cli_summarise_numeric <- function(x, col, n_rows) {
  x_valid  <- x[!is.na(x)]
  na_n     <- sum(is.na(x))
  na_pct   <- round(na_n / n_rows * 100, 1L)
  mean_v   <- if (length(x_valid) > 0L) round(mean(x_valid),                    2L) else NA
  median_v <- if (length(x_valid) > 0L) round(stats::median(x_valid),            2L) else NA
  sd_v     <- if (length(x_valid) > 1L) round(stats::sd(x_valid),                2L) else NA
  q1_v     <- if (length(x_valid) > 0L) round(stats::quantile(x_valid, 0.25),    2L) else NA
  q3_v     <- if (length(x_valid) > 0L) round(stats::quantile(x_valid, 0.75),    2L) else NA
  cli::cli_text(
    "  {.field {col}}: mean={mean_v}, median={median_v}, sd={sd_v}, Q1={q1_v}, Q3={q3_v}, NA={na_pct}% (n={na_n})"
  )
}


# Print a cli summary block for a factor column and warn if high-cardinality.
# Used by derive_covariate() and derive_cut().
.cli_summarise_factor <- function(f, col, n_rows, max_levels = 5L) {
  n_lvls <- nlevels(f)

  if (n_lvls > max_levels) {
    cli::cli_alert_warning(
      "{.field {col}}: {n_lvls} levels > max_levels ({max_levels}), consider collapsing categories."
    )
  }

  cli::cli_text("  {.field {col}} [{n_lvls} level{?s}]")

  # Reason: include NA so user sees missing proportion alongside valid levels
  tab <- table(f, useNA = "always")
  for (i in seq_along(tab)) {
    lbl   <- names(tab)[i]
    lbl   <- if (is.na(lbl)) "<NA>" else lbl
    count <- tab[[i]]
    pct   <- round(count / n_rows * 100, 1L)
    cli::cli_text("    {lbl}: n={count} ({pct}%)")
  }
}


# Parse UKB decimal year-month format (e.g. 2005.58 → 2005-07-01) to IDate.
# Returns NA_integer_ (IDate) for missing, zero, or negative values.
# Uses IDate (integer-backed) so fcoalesce() works without type coercion.
# Used by derive_selfreport() to convert p20008/p20006 date fields.
.parse_ukb_year_month <- function(ym) {
  ym    <- suppressWarnings(as.numeric(ym))
  valid <- !is.na(ym) & ym > 0
  out   <- rep(NA_integer_, length(ym))
  if (any(valid)) {
    yr  <- floor(ym[valid])
    mo  <- pmax(1L, pmin(12L, round((ym[valid] - yr) * 12)))
    out[valid] <- as.integer(
      data.table::as.IDate(sprintf("%04d-%02d-01", as.integer(yr), as.integer(mo)))
    )
  }
  structure(out, class = c("IDate", "Date"))
}


# Detect a single First Occurrence column for a given UKB field ID.
# First Occurrence fields (p131xxx) are single-column, no _i/_a suffix.
# Strategy:
#   1. Cache available → title → snake_case base → grep names(data)
#   2. Fallback → raw "p{field_id}" pattern (works before decode_names)
# Returns NULL if not found.
.detect_fo_col <- function(data, field_id) {
  fields_df <- .ukbflow_cache$fields

  if (!is.null(fields_df)) {
    idx <- grep(paste0("p", field_id), fields_df$field_name, fixed = TRUE)[1L]
    if (!is.na(idx)) {
      base <- trimws(sub("\\s*\\|.*$", "", fields_df$title[idx]))
      base <- tolower(base)
      base <- gsub("[^a-z0-9]+", "_", base)
      base <- gsub("^_+|_+$",    "",  base)
      cols <- grep(base, names(data), value = TRUE, fixed = TRUE)
      if (length(cols) > 0L) return(cols[1L])
    }
  }

  # Fallback: raw field ID pattern (before decode_names)
  cols <- grep(paste0("p", field_id), names(data), value = TRUE, fixed = TRUE)
  if (length(cols) > 0L) return(cols[1L])

  NULL
}


# Detect columns in data that belong to a given UKB field ID.
# Uses extract_ls() cache: looks up field title → converts base to snake_case
# pattern → greps column names. Falls back to raw "p{id}_i" pattern when
# the cache is unavailable or decode_names() has not been run.
.detect_cols_by_field <- function(data, field_id) {
  fields_df <- .ukbflow_cache$fields

  if (!is.null(fields_df)) {
    # Find any entry for this field ID in the dictionary
    idx <- grep(paste0("p", field_id, "_"), fields_df$field_name, fixed = TRUE)[1L]
    if (!is.na(idx)) {
      # Extract base title (before first "|") and convert to snake_case
      base <- trimws(sub("\\s*\\|.*$", "", fields_df$title[idx]))
      base <- tolower(base)
      base <- gsub("[^a-z0-9]+", "_", base)
      base <- gsub("^_+|_+$",    "",  base)
      cols <- grep(base, names(data), value = TRUE, fixed = TRUE)
      if (length(cols) > 0L) return(cols)
    }
  }

  # Fallback: raw field ID pattern (works before decode_names)
  grep(paste0("p", field_id, "_i"), names(data), value = TRUE)
}
