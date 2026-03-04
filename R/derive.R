# =============================================================================
# derive.R — analysis-ready variable preparation for UKB data
# =============================================================================


#' Handle informative missing labels in UKB decoded data
#'
#' After \code{\link{decode_values}} converts categorical codes to character
#' labels, some values represent meaningful non-response rather than true data:
#' \code{"Do not know"}, \code{"Prefer not to answer"}, and
#' \code{"Prefer not to say"}. This function either converts them to \code{NA}
#' (for complete-case analysis) or retains them as \code{"Unknown"} (to
#' preserve the informative missingness as a model category).
#'
#' Empty strings (\code{""}) are always converted to \code{NA} regardless of
#' \code{action}, as they carry no informational content.
#'
#' Only character columns are modified; numeric, integer, Date, and logical
#' columns are silently skipped.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, modifications are made in-place via
#' \code{\link[data.table]{set}}. The returned object and the original variable
#' point to the same memory. If you need to preserve the original, pass
#' \code{data.table::copy(data)} instead.
#'
#' @param data (data.frame or data.table) Decoded UKB data, typically output
#'   of \code{\link{decode_values}} followed by \code{\link{decode_names}}.
#' @param cols <\code{\link[tidyselect]{tidyselect}}> Columns to process.
#'   Default: \code{everything()} (all columns). Non-character columns in the
#'   selection are silently skipped.
#' @param action (character) One of \code{"na"} (default) or \code{"unknown"}.
#'   \itemize{
#'     \item \code{"na"}: convert all informative missing labels to \code{NA}.
#'     \item \code{"unknown"}: convert informative missing labels to
#'       \code{"Unknown"}, preserving them as a distinct model category.
#'   }
#'   Empty strings are always converted to \code{NA} regardless of this
#'   parameter.
#' @param extra_labels (character or NULL) Additional labels to treat as
#'   informative missing, appended to the built-in list. Default: \code{NULL}.
#'
#' @return The input \code{data} with missing labels replaced in-place.
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(31, 20116, 2080)) |>
#'   decode_values() |>
#'   decode_names() |>
#'   derive_missing()                          # "Do not know" -> NA
#'
#' # Retain informative non-response as a model category
#' df <- derive_missing(df, action = "unknown")  # "Prefer not to answer" -> "Unknown"
#'
#' # Add a custom label
#' df <- derive_missing(df, extra_labels = "Not applicable")
#' }
derive_missing <- function(data,
                           cols         = tidyselect::everything(),
                           action       = c("na", "unknown"),
                           extra_labels = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }

  action <- match.arg(action)

  if (!is.null(extra_labels)) {
    if (!is.character(extra_labels)) {
      stop("extra_labels must be a character vector or NULL.", call. = FALSE)
    }
    extra_labels <- extra_labels[nchar(trimws(extra_labels)) > 0L]
  }

  # Convert to data.table in-place (no copy for data.table input)
  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  # Resolve tidyselect column indices, then keep only character columns
  selected_idx  <- tidyselect::eval_select(rlang::enquo(cols), data)
  selected_cols <- names(selected_idx)
  char_cols     <- selected_cols[vapply(data[, selected_cols, with = FALSE],
                                        is.character, logical(1L))]

  if (length(char_cols) == 0L) {
    cli::cli_alert_info("No character columns found in selection — nothing to do.")
    return(invisible(data))
  }

  # Build label sets
  informative_labels <- c(.ukb_informative_missing, extra_labels)
  replace_value      <- if (action == "na") NA_character_ else "Unknown"

  n_cols_affected  <- 0L
  n_vals_replaced  <- 0L

  for (col in char_cols) {

    x          <- data[[col]]
    empty_idx  <- which(x == "")
    inform_idx <- which(x %in% informative_labels)

    n_replaced <- length(empty_idx) + length(inform_idx)
    if (n_replaced == 0L) next

    # "" always -> NA; informative labels -> NA or "Unknown" per action
    data.table::set(data, i = empty_idx,  j = col, value = NA_character_)
    data.table::set(data, i = inform_idx, j = col, value = replace_value)

    n_cols_affected <- n_cols_affected + 1L
    n_vals_replaced <- n_vals_replaced + n_replaced
  }

  cli::cli_alert_success(
    "derive_missing: replaced {n_vals_replaced} value{?s} across \\
     {n_cols_affected} column{?s} (action = {.val {action}})."
  )

  data
}


#' Prepare UKB covariates for analysis
#'
#' Converts decoded UKB columns to analysis-ready types: character-encoded
#' numeric fields to \code{numeric}, and categorical fields to \code{factor}.
#' Prints a concise summary for each converted column — mean / median / SD /
#' missing rate for numeric columns, and level counts for factor columns — so
#' you can verify distributions without leaving the pipeline.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, modifications are made in-place. Pass
#' \code{data.table::copy(data)} to preserve the original.
#'
#' @param data (data.frame or data.table) UKB data, typically output of
#'   \code{\link{derive_missing}}.
#' @param as_numeric (character or NULL) Column names to convert to
#'   \code{numeric}. Values that cannot be coerced (e.g. residual text) become
#'   \code{NA} with a warning. Default: \code{NULL}.
#' @param as_factor (character or NULL) Column names to convert to
#'   \code{factor}. Default levels are the sorted unique non-NA values unless
#'   overridden by \code{factor_levels}. Default: \code{NULL}.
#' @param factor_levels (named list or NULL) Custom level ordering for specific
#'   factor columns. Names must match entries in \code{as_factor}; values are
#'   character vectors of levels in the desired order (first level = reference
#'   group in regression). Columns not listed use default ordering.
#'   Default: \code{NULL}.
#' @param max_levels (integer) Factor columns with more levels than this
#'   threshold trigger a warning suggesting the user consider collapsing
#'   categories. Default: \code{5L}.
#'
#' @return The input \code{data} with converted columns. Always returns a
#'   \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(31, 20116, 738, 874)) |>
#'   decode_values() |>
#'   decode_names() |>
#'   derive_missing() |>
#'   derive_covariate(
#'     as_numeric = "duration_of_walks_i0",
#'     as_factor  = c("sex", "smoking_status_i0"),
#'     factor_levels = list(
#'       smoking_status_i0 = c("Never", "Previous", "Current")
#'     )
#'   )
#' }
derive_covariate <- function(data,
                             as_numeric    = NULL,
                             as_factor     = NULL,
                             factor_levels = NULL,
                             max_levels    = 5L) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.null(factor_levels) && !is.list(factor_levels)) {
    stop("factor_levels must be a named list or NULL.", call. = FALSE)
  }
  if (!is.null(factor_levels) && is.null(names(factor_levels))) {
    stop("factor_levels must be a named list (names = column names).", call. = FALSE)
  }

  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  n_rows <- nrow(data)

  # ── as_numeric ──────────────────────────────────────────────────────────────
  if (!is.null(as_numeric)) {

    bad        <- setdiff(as_numeric, names(data))
    as_numeric <- intersect(as_numeric, names(data))
    if (length(bad) > 0L) {
      cli::cli_alert_warning("as_numeric: columns not found, skipped: {.val {bad}}")
    }

    if (length(as_numeric) > 0L) {
      cli::cli_rule(left = "Numeric")

      for (col in as_numeric) {
        na_before <- sum(is.na(data[[col]]))
        data.table::set(data, j = col,
                        value = suppressWarnings(as.numeric(data[[col]])))
        na_new <- sum(is.na(data[[col]])) - na_before
        if (na_new > 0L) {
          cli::cli_alert_warning(
            "{.field {col}}: {na_new} value{?s} coerced to NA."
          )
        }
        .cli_summarise_numeric(data[[col]], col, n_rows)
      }
    }
  }

  # ── as_factor ───────────────────────────────────────────────────────────────
  if (!is.null(as_factor)) {

    bad       <- setdiff(as_factor, names(data))
    as_factor <- intersect(as_factor, names(data))
    if (length(bad) > 0L) {
      cli::cli_alert_warning("as_factor: columns not found, skipped: {.val {bad}}")
    }

    if (length(as_factor) > 0L) {
      cli::cli_rule(left = "Factor")

      for (col in as_factor) {
        lvls  <- factor_levels[[col]]   # NULL → default sorted levels
        f_val <- if (is.null(lvls)) factor(data[[col]]) else factor(data[[col]], levels = lvls)
        data.table::set(data, j = col, value = f_val)
        .cli_summarise_factor(data[[col]], col, n_rows, max_levels)
      }
    }
  }

  data
}


#' Cut a continuous UKB variable into quantile-based or custom groups
#'
#' Creates a new factor column by binning a continuous variable into \code{n}
#' groups. When \code{breaks} is omitted, group boundaries are derived from
#' quantiles of the observed data (equal-frequency binning). When
#' \code{breaks} is supplied, those values are used as interior cut points.
#'
#' Before binning, a numeric summary (mean, median, SD, Q1, Q3, missing rate)
#' is printed for the source column. After binning, the group distribution is
#' printed via \code{\link{.cli_summarise_factor}}.
#'
#' Only one column can be processed per call; loop over columns explicitly
#' when binning multiple variables.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, the new column is added in-place. Pass
#' \code{data.table::copy(data)} to preserve the original.
#'
#' @param data (data.frame or data.table) UKB data.
#' @param col (character) Name of the source numeric column.
#' @param n (integer) Number of groups. Supported values: \code{2}, \code{3},
#'   \code{4}, \code{5}.
#' @param breaks (numeric vector or NULL) Interior cut points; length must
#'   equal \code{n - 1}. When \code{NULL} (default), quantile-based equal-
#'   frequency boundaries are computed automatically.
#' @param labels (character vector or NULL) Group labels of length \code{n}.
#'   Defaults to \code{"Q1"}, \code{"Q2"}, \ldots, \code{"Qn"}.
#' @param name (character or NULL) Name for the new column. Defaults to
#'   \code{"{col}_bi"} / \code{"{col}_tri"} / \code{"{col}_quad"} /
#'   \code{"{col}_quin"} for \code{n} = 2 / 3 / 4 / 5.
#'
#' @return The input \code{data} with one new factor column appended. Always
#'   returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- derive_cut(df, col = "age_at_recruitment", n = 3)
#' # → adds age_at_recruitment_tri with groups Q1 / Q2 / Q3
#'
#' df <- derive_cut(df, col = "age_at_recruitment", n = 3,
#'                  breaks = c(50, 60),
#'                  labels = c("<50", "50-59", "60+"),
#'                  name   = "age_group")
#' }
derive_cut <- function(data,
                       col,
                       n,
                       breaks = NULL,
                       labels = NULL,
                       name   = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!col %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
  }
  if (!is.numeric(n) || length(n) != 1L || n < 2L) {
    stop("n must be a single integer >= 2.", call. = FALSE)
  }
  n <- as.integer(n)

  if (!is.null(breaks)) {
    if (!is.numeric(breaks) || length(breaks) != n - 1L) {
      stop(sprintf("breaks must be a numeric vector of length n - 1 (%d).", n - 1L),
           call. = FALSE)
    }
  }
  if (!is.null(labels) && length(labels) != n) {
    stop(sprintf("labels must be a character vector of length n (%d).", n), call. = FALSE)
  }

  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  n_rows <- nrow(data)
  x      <- data[[col]]

  if (!is.numeric(x)) {
    stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
  }

  # Default name based on n
  if (is.null(name)) {
    suffix_map <- c("2" = "_bi", "3" = "_tri", "4" = "_quad", "5" = "_quin")
    suffix <- suffix_map[as.character(n)]
    name   <- if (!is.na(suffix)) paste0(col, suffix) else paste0(col, "_g", n)
  }

  # Default labels: Q1, Q2, ..., Qn
  if (is.null(labels)) labels <- paste0("Q", seq_len(n))

  # ── Print source column numeric summary ────────────────────────────────────
  cli::cli_rule(left = sprintf("Source: %s", col))
  .cli_summarise_numeric(x, col, n_rows)

  # ── Compute cut points ─────────────────────────────────────────────────────
  if (is.null(breaks)) {
    # Reason: quantile-based equal-frequency binning; include.lowest ensures
    # the minimum value falls into the first group
    cut_breaks <- stats::quantile(x, probs = seq(0, 1, length.out = n + 1L),
                                  na.rm = TRUE)
    cut_breaks <- unique(cut_breaks)   # collapse duplicate boundaries from ties
    if (length(cut_breaks) < n + 1L) {
      cli::cli_alert_warning(
        "Ties at quantile boundaries reduced the number of distinct groups \\
         (requested {n}, got {length(cut_breaks) - 1L})."
      )
    }
  } else {
    cut_breaks <- c(-Inf, breaks, Inf)
  }

  f_val <- base::cut(x, breaks = cut_breaks, labels = labels,
                     include.lowest = TRUE, right = TRUE)

  # ── Add new column and print factor summary ─────────────────────────────────
  data.table::set(data, j = name, value = f_val)

  cli::cli_rule(left = sprintf("New column: %s", name))
  .cli_summarise_factor(data[[name]], name, n_rows, max_levels = n)

  data
}


#' Define a self-reported phenotype from UKB touchscreen data
#'
#' Searches UKB self-reported illness fields across all instances and arrays,
#' matches records against a user-supplied regex, parses the associated
#' year-month date, and appends two columns to the data:
#' \code{{name}_selfreport} (logical) and \code{{name}_selfreport_date}
#' (\code{IDate}, earliest matching instance).
#'
#' The function auto-detects the relevant columns using the
#' \code{extract_ls()} field dictionary cache (populated by
#' \code{extract_ls()} or \code{extract_pheno()}). The three \code{_cols}
#' parameters let you override auto-detection when column names have been
#' customised (e.g. after \code{decode_names()}).
#'
#' \strong{Field mapping by \code{field}:}
#' \itemize{
#'   \item \code{"noncancer"}: disease text = p20002, date = p20008.
#'   \item \code{"cancer"}:    disease text = p20001, date = p20006.
#' }
#' Baseline visit date (p53) is used as a fallback when no specific
#' diagnosis date is recorded.
#'
#' \strong{data.table pass-by-reference}: new columns are added in-place.
#' Pass \code{data.table::copy(data)} to preserve the original.
#'
#' @param data (data.frame or data.table) UKB data containing self-report
#'   fields.
#' @param name (character) Output column name prefix, e.g. \code{"ad"} or
#'   \code{"cscc"}.
#' @param regex (character) Regular expression matched against disease text
#'   values (after \code{tolower()}), e.g. \code{"^eczema/dermatitis$"}.
#' @param field (character) Self-report field type: \code{"noncancer"}
#'   (p20002 / p20008) or \code{"cancer"} (p20001 / p20006).
#' @param ignore_case (logical) Should regex matching ignore case?
#'   Default: \code{TRUE}.
#' @param disease_cols (character or NULL) Column name(s) containing disease
#'   text (p20002 or p20001). \code{NULL} = auto-detect via
#'   \code{extract_ls()} cache.
#' @param date_cols (character or NULL) Column name(s) containing the
#'   self-report year-month date (p20008 or p20006). \code{NULL} =
#'   auto-detect.
#' @param visit_cols (character or NULL) Column name(s) containing the
#'   baseline assessment date (p53). \code{NULL} = auto-detect.
#'
#' @return The input \code{data} with two new columns appended in-place:
#'   \code{{name}_selfreport} (logical) and
#'   \code{{name}_selfreport_date} (IDate). Always returns a
#'   \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- extract_pheno(c(20002, 20008, 53)) |>
#'   derive_selfreport(name = "ad", regex = "^eczema/dermatitis$",
#'                     field = "noncancer")
#'
#' df <- derive_selfreport(df, name = "cscc",
#'                         regex = "squamous cell carcinoma",
#'                         field = "cancer")
#' }
derive_selfreport <- function(data,
                              name,
                              regex,
                              field        = c("noncancer", "cancer"),
                              ignore_case  = TRUE,
                              disease_cols = NULL,
                              date_cols    = NULL,
                              visit_cols   = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name)  || length(name)  != 1L) stop("name must be a single string.",  call. = FALSE)
  if (!is.character(regex) || length(regex) != 1L) stop("regex must be a single string.", call. = FALSE)

  field <- match.arg(field)

  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  # ── Field ID mapping ───────────────────────────────────────────────────────
  fid_disease <- if (field == "noncancer") 20002L else 20001L
  fid_date    <- if (field == "noncancer") 20008L else 20006L
  fid_visit   <- 53L

  # ── Auto-detect columns ────────────────────────────────────────────────────
  if (is.null(disease_cols)) disease_cols <- .detect_cols_by_field(data, fid_disease)
  if (is.null(date_cols))    date_cols    <- .detect_cols_by_field(data, fid_date)
  if (is.null(visit_cols))   visit_cols   <- .detect_cols_by_field(data, fid_visit)

  status_col <- paste0(name, "_selfreport")
  date_col   <- paste0(name, "_selfreport_date")

  if (length(disease_cols) == 0L) {
    cli::cli_alert_warning(
      "derive_selfreport: no disease columns for field {fid_disease}. \\
       Supply disease_cols manually."
    )
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    return(invisible(data))
  }
  if (length(date_cols)  == 0L) cli::cli_alert_warning(
    "derive_selfreport: no date columns for field {fid_date}. Baseline (p53) used."
  )
  if (length(visit_cols) == 0L) cli::cli_alert_warning(
    "derive_selfreport: no visit columns for field {fid_visit}."
  )

  # ── Detect instances (e.g. "_i0_", "_i1_") ────────────────────────────────
  inst_raw  <- regmatches(disease_cols,
                          regexpr("_i(\\d+)_", disease_cols, perl = TRUE))
  instances <- sort(unique(sub("_i(\\d+)_", "\\1", inst_raw, perl = TRUE)))

  results <- vector("list", length(instances))
  names(results) <- instances

  for (inst in instances) {

    d_cols <- sort(grep(paste0("_i", inst, "_"), disease_cols, value = TRUE))
    t_cols <- sort(grep(paste0("_i", inst, "_"), date_cols,    value = TRUE))
    v_col  <- grep(paste0("_i", inst, "$"),      visit_cols,   value = TRUE)
    v_col  <- if (length(v_col) > 0L) v_col[1L] else NULL

    if (length(d_cols) == 0L) next

    id_cols <- if (!is.null(v_col)) c("eid", v_col) else "eid"

    # ── Melt disease text columns ────────────────────────────────────────────
    # Reason: two separate simple melts (disease + date) then join by array_idx.
    # Avoids list-melt entirely — list-melt with mixed-type sparse UKB array
    # columns is unreliable across data.table versions (may strip class or
    # ignore value.name). Simple melt on a single pre-typed column group is
    # always well-behaved.
    sub_d <- data.table::copy(data[, c(id_cols, d_cols), with = FALSE])
    for (.c in d_cols) {
      data.table::set(sub_d, j = .c, value = as.character(sub_d[[.c]]))
    }

    long_d <- data.table::melt(
      sub_d,
      id.vars       = id_cols,
      measure.vars  = d_cols,
      variable.name = "array_idx",
      value.name    = "text"
    )
    long_d[, array_idx := as.integer(array_idx)]

    # Filter: drop empty/NA, lowercase, apply regex
    long_d <- long_d[!is.na(text) & nchar(as.character(text)) > 0L]
    if (nrow(long_d) == 0L) next
    long_d[, text := tolower(as.character(text))]
    long_d <- long_d[grepl(regex, text, ignore.case = ignore_case, perl = TRUE)]
    if (nrow(long_d) == 0L) next

    # ── Melt date columns, join onto matched disease rows ────────────────────
    if (length(t_cols) > 0L) {
      sub_t <- data.table::copy(data[, c("eid", t_cols), with = FALSE])
      for (.c in t_cols) {
        data.table::set(sub_t, j = .c,
                        value = suppressWarnings(as.numeric(sub_t[[.c]])))
      }

      long_t <- data.table::melt(
        sub_t,
        id.vars       = "eid",
        measure.vars  = t_cols,
        variable.name = "array_idx",
        value.name    = "year_month"
      )
      long_t[, array_idx  := as.integer(array_idx)]
      long_t[, year_month := suppressWarnings(as.numeric(year_month))]

      # Left join: attach year_month to matched disease rows by (eid, array_idx)
      long_d <- long_t[long_d, on = c("eid", "array_idx")]
    } else {
      long_d[, year_month := NA_real_]
    }

    # ── Baseline date (IDate; integer-backed for fcoalesce compatibility) ────
    if (!is.null(v_col) && v_col %in% names(long_d)) {
      data.table::setnames(long_d, v_col, "baseline_date")
      long_d[, baseline_date := data.table::as.IDate(as.character(baseline_date))]
    } else {
      long_d[, baseline_date := data.table::as.IDate(NA_character_)]
    }

    # ── Parse year_month → IDate, fallback to baseline ──────────────────────
    # Both parsed_date (.parse_ukb_year_month) and baseline_date are IDate
    # (integer-backed), so fcoalesce() works without type coercion.
    long_d[, parsed_date   := .parse_ukb_year_month(year_month)]
    long_d[, instance_date := data.table::fcoalesce(parsed_date, baseline_date)]

    results[[inst]] <- long_d[, .(eid, instance_date)]
  }

  # ── Combine across instances ───────────────────────────────────────────────
  results <- Filter(Negate(is.null), results)

  if (length(results) == 0L) {
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    cli::cli_alert_warning("derive_selfreport ({name}): 0 cases found.")
    return(invisible(data))
  }

  combined <- data.table::rbindlist(results, fill = TRUE)

  # Status: in-place logical flag
  data[, (status_col) := eid %in% unique(combined$eid)]

  # Earliest date per eid — update-on-join (zero-copy, truly in-place)
  dates <- combined[!is.na(instance_date),
                    .(date = min(instance_date, na.rm = TRUE)),
                    by = eid]
  data[, (date_col) := data.table::as.IDate(NA_character_)]
  data[dates, on = "eid", (date_col) := i.date]

  n_cases <- sum(data[[status_col]])
  n_dated  <- sum(!is.na(data[[date_col]]))
  cli::cli_alert_success(
    "derive_selfreport ({name}): {n_cases} case{?s}, {n_dated} with date{?s}."
  )

  data
}


#' Derive a binary disease flag from UKB First Occurrence fields
#'
#' UKB pre-computes the earliest recorded date for hundreds of ICD-10 chapters
#' and categories as \emph{First Occurrence} fields (\code{p131xxx}).  Each
#' field contains a single date per participant; no array or instance depth is
#' involved.  This function reads that date, converts it to \code{IDate},
#' and writes two analysis-ready columns:
#'
#' \describe{
#'   \item{\code{{name}_fo_date}}{Earliest First Occurrence date (\code{IDate}).
#'     Values that cannot be coerced to a valid date (e.g. UKB error codes)
#'     are silently set to \code{NA}.}
#'   \item{\code{{name}_fo}}{Logical flag derived from
#'     \code{{name}_fo_date}: \code{TRUE} if and only if a valid date exists.
#'     This guarantees that every positive case has a usable date — essential
#'     for time-to-event and prevalent/incident classification.}
#' }
#'
#' \strong{Column detection}: the function locates the source column
#' automatically from \code{field}, handling both the raw format used by
#' \code{\link{extract_pheno}} (\code{participant.p131720}) and the
#' snake_case format produced by \code{\link{decode_names}}
#' (\code{date_l20_first_reported_atopic_dermatitis}).  Supply \code{col}
#' to override auto-detection.
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, new columns are added in-place via \code{:=}.
#' The returned object and the original variable point to the same memory.
#'
#' @param data (data.frame or data.table) UKB phenotype data.
#' @param name (character) Output column prefix, e.g. \code{"ad"} produces
#'   \code{ad_fo} and \code{ad_fo_date}.
#' @param field (integer or character) UKB field ID of the First Occurrence
#'   field, e.g. \code{131720} for L20 (atopic dermatitis).
#' @param col (character or NULL) Name of the source column in \code{data}.
#'   When \code{NULL} (default) the column is detected automatically from
#'   \code{field}.
#'
#' @return The input \code{data} (invisibly) with two new columns added
#'   in-place: \code{{name}_fo} (logical) and \code{{name}_fo_date} (IDate).
#' @export
#'
#' @examples
#' \dontrun{
#' # AD — field 131720 corresponds to ICD-10 L20 (atopic dermatitis)
#' df <- derive_first_occurrence(df, name = "ad", field = 131720)
#' # → df$ad_fo        logical
#' # → df$ad_fo_date   IDate
#'
#' # Supply col directly when the column name is already known
#' df <- derive_first_occurrence(df, name = "ad", field = 131720,
#'                               col = "date_l20_first_reported_atopic_dermatitis")
#' }
derive_first_occurrence <- function(data, name, field, col = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data.table::setDT(data)

  status_col <- paste0(name, "_fo")
  date_col   <- paste0(name, "_fo_date")

  # ── Locate source column ──────────────────────────────────────────────────
  if (!is.null(col)) {
    src_col <- col
    if (!src_col %in% names(data)) {
      stop("Column '", src_col, "' not found in data.", call. = FALSE)
    }
  } else {
    src_col <- .detect_fo_col(data, field)
    if (is.null(src_col)) {
      stop(
        "Cannot find First Occurrence column for field ", field, ". ",
        "Specify col= directly or ensure extract_ls() cache is populated.",
        call. = FALSE
      )
    }
  }

  # ── Convert to IDate ──────────────────────────────────────────────────────
  # Reason: some p131xxx values are UKB error codes that cannot be coerced to
  # a valid date; as.IDate(as.character(...)) converts them to NA naturally.
  # Dates that predate birth or carry other clinical implausibility are also
  # surfaced as NA at this step (as.IDate returns NA for unparseable strings).
  data[, (date_col) := data.table::as.IDate(as.character(get(src_col)))]

  # ── Derive logical flag FROM date (never from raw column) ─────────────────
  # Reason: status must imply a usable date for time-to-event analysis.
  # A case without a valid date is analytically unusable.
  data[, (status_col) := !is.na(get(date_col))]

  n_cases <- sum(data[[status_col]], na.rm = TRUE)
  cli::cli_alert_success(
    "derive_first_occurrence ({name}): {n_cases} case{?s} with valid date."
  )

  invisible(data)
}


#' Derive a binary disease flag from UKB HES inpatient diagnoses
#'
#' Hospital Episode Statistics (HES) inpatient records store ICD-10 diagnosis
#' codes in field \code{p41270} (single JSON-array column on UKB RAP) and
#' corresponding first-diagnosis dates in field \code{p41280}
#' (\code{p41280_a0}, \code{p41280_a1}, \ldots).  The array index in
#' \code{p41270} and \code{p41280} are aligned: the \emph{N}-th code in the
#' JSON array corresponds to \code{p41280_aN} (date of first in-patient
#' diagnosis for that code).
#'
#' \describe{
#'   \item{\code{{name}_hes}}{Logical flag: \code{TRUE} if any HES record
#'     contains a matching ICD-10 code.}
#'   \item{\code{{name}_hes_date}}{Earliest first-diagnosis date across all
#'     matching codes (\code{IDate}).  \code{NA} if no date is available.}
#' }
#'
#' @param data (data.frame or data.table) UKB phenotype data containing HES
#'   fields (\code{p41270} and \code{p41280_a*}).
#' @param name (character) Output column prefix, e.g. \code{"ad"} produces
#'   \code{ad_hes} and \code{ad_hes_date}.
#' @param icd10 (character) ICD-10 code(s) to match.  For \code{"prefix"} and
#'   \code{"exact"}, supply a vector such as \code{c("L20", "L21")}.  For
#'   \code{"regex"}, supply a single regex string.
#' @param match (character) Matching strategy: \code{"prefix"} (default)
#'   matches any code starting with the supplied string; \code{"exact"}
#'   requires a full match; \code{"regex"} uses \code{icd10} directly.
#' @param disease_cols (character or NULL) Name of the \code{p41270} column.
#'   \code{NULL} = auto-detect.
#' @param date_cols (character or NULL) Names of \code{p41280_a*} columns.
#'   \code{NULL} = auto-detect.
#'
#' @return The input \code{data} with two new columns added in-place:
#'   \code{{name}_hes} (logical) and \code{{name}_hes_date} (IDate).
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- derive_hes(df, name = "ad", icd10 = "L20")
#' df <- derive_hes(df, name = "asthma",
#'                  icd10 = c("J450", "J451", "J459"), match = "exact")
#' df <- derive_hes(df, name = "dermatitis",
#'                  icd10 = "^(L20|L21|L23)", match = "regex")
#' }
derive_hes <- function(data,
                       name,
                       icd10,
                       match        = c("prefix", "exact", "regex"),
                       disease_cols = NULL,
                       date_cols    = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  match      <- match.arg(match)
  status_col <- paste0(name, "_hes")
  date_col   <- paste0(name, "_hes_date")

  # ── Auto-detect columns ────────────────────────────────────────────────────
  # p41270: single JSON-array column (no _i/_a suffix on RAP)
  if (is.null(disease_cols)) disease_cols <- .detect_fo_col(data, 41270L)

  # p41280: wide date columns p41280_a0, p41280_a1, ...
  if (is.null(date_cols)) {
    date_cols <- .detect_cols_by_field(data, 41280L)
    # Fallback: RAP format has no _i, only _a
    if (length(date_cols) == 0L) {
      date_cols <- grep("p41280", names(data), value = TRUE, fixed = TRUE)
      date_cols <- setdiff(date_cols, "eid")
    }
  }

  if (is.null(disease_cols) || !disease_cols %in% names(data)) {
    cli::cli_alert_warning(
      "derive_hes: ICD-10 code column (p41270) not found. \\
       Supply disease_cols manually."
    )
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    return(invisible(data))
  }
  if (length(date_cols) == 0L) {
    cli::cli_alert_warning("derive_hes: no date columns (p41280_a*) found.")
  }

  # ── Build ICD-10 match patterns ───────────────────────────────────────────
  pattern <- switch(match,
    prefix = paste0("^(", paste(icd10, collapse = "|"), ")"),
    exact  = paste0("^(", paste(icd10, collapse = "|"), ")$"),
    regex  = icd10[1L]
  )
  # Reason: pre_pattern is anchor-free so it can match codes embedded inside
  # the raw JSON string (e.g. '"L209"' inside '["R55","L209",...]').
  # The anchored pattern is applied later on individual parsed codes.
  pre_pattern <- switch(match,
    prefix = paste(icd10, collapse = "|"),
    exact  = paste(icd10, collapse = "|"),
    regex  = icd10[1L]
  )

  # ── Pre-filter: coarse grepl on raw JSON string before strsplit ───────────
  # Reason: ~90%+ of participants have no matching code; scanning the raw
  # string is O(n_chars) and avoids the expensive strsplit + expand step for
  # the vast majority of rows.
  sub <- data[
    !is.na(get(disease_cols)) &
    nchar(as.character(get(disease_cols))) > 2L &
    grepl(pre_pattern, as.character(get(disease_cols)),
          ignore.case = TRUE, perl = TRUE),
    .(eid, raw = as.character(get(disease_cols)))
  ]

  if (nrow(sub) == 0L) {
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    cli::cli_alert_warning("derive_hes ({name}): 0 cases found.")
    return(invisible(data))
  }

  # ── Parse JSON array → long table (eid, array_idx, icd_code) ─────────────
  # Vectorized: strip brackets, split by "," separator, clean quotes
  sub[, raw_clean := gsub('^\\[|\\]$', '', raw)]
  codes_list <- strsplit(sub$raw_clean, '","')
  codes_list <- lapply(codes_list, function(x) gsub('"', '', x))
  codes_list <- lapply(codes_list, function(x) x[nchar(trimws(x)) > 0L])

  long_code <- data.table::data.table(
    eid       = rep(sub$eid, lengths(codes_list)),
    array_idx = unlist(lapply(codes_list, function(x) seq_along(x) - 1L)),
    icd_code  = unlist(codes_list)
  )

  # ── Exact filter on parsed codes (anchored pattern) ───────────────────────
  long_code <- long_code[
    grepl(pattern, icd_code, ignore.case = TRUE, perl = TRUE)
  ]

  if (nrow(long_code) == 0L) {
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    cli::cli_alert_warning("derive_hes ({name}): 0 cases found.")
    return(invisible(data))
  }

  # Status: any matching code
  data[, (status_col) := eid %in% unique(long_code$eid)]

  # ── Melt p41280 → long, extract array index, join on (eid, array_idx) ─────
  if (length(date_cols) > 0L) {
    matched_eids <- unique(long_code$eid)

    # Reason: only melt date columns for matched eids — avoids building a
    # 500k × 259 long table; na.rm = TRUE drops empty cells at C level.
    sub_t <- data.table::copy(
      data[eid %in% matched_eids, c("eid", date_cols), with = FALSE]
    )
    for (.c in date_cols) {
      data.table::set(sub_t, j = .c,
                      value = data.table::as.IDate(as.character(sub_t[[.c]])))
    }
    long_date <- data.table::melt(sub_t,
                                   id.vars       = "eid",
                                   measure.vars  = date_cols,
                                   variable.name = "col_name",
                                   value.name    = "diag_date",
                                   na.rm         = TRUE)
    # Extract 0-based array index from column name: p41280_a0 → 0
    long_date[, array_idx := as.integer(
      gsub(".*_a(\\d+)$", "\\1", as.character(col_name), perl = TRUE)
    )]
    long_date[, col_name := NULL]

    # Inner join: matched codes × dates by (eid, array_idx)
    matched <- long_date[long_code, on = c("eid", "array_idx"), nomatch = 0L]

    dates <- matched[!is.na(diag_date),
                     .(date = min(diag_date, na.rm = TRUE)),
                     by = eid]
    data[, (date_col) := data.table::as.IDate(NA_character_)]
    data[dates, on = "eid", (date_col) := i.date]
  } else {
    data[, (date_col) := data.table::as.IDate(NA_character_)]
  }

  n_cases <- sum(data[[status_col]])
  n_dated  <- sum(!is.na(data[[date_col]]))
  cli::cli_alert_success(
    "derive_hes ({name}): {n_cases} case{?s}, {n_dated} with date."
  )

  data
}


#' Derive a binary disease flag from UKB cancer registry
#'
#' The UK Biobank cancer registry links each participant's cancer diagnoses
#' from national cancer registries.  Each diagnosis is stored as a separate
#' instance with four parallel fields: ICD-10 code (\code{p40006}), histology
#' code (\code{p40011}), behaviour code (\code{p40012}), and diagnosis date
#' (\code{p40005}).  Unlike HES or self-report data, each instance holds
#' exactly one record — there is no array (\code{a*}) dimension.
#'
#' All three filter arguments (\code{icd10}, \code{histology},
#' \code{behaviour}) are applied with AND logic: a record must satisfy
#' every non-\code{NULL} filter to be counted.  For OR conditions (e.g.\
#' D04 \emph{or} C44 with specific histology), call the function twice and
#' combine the resulting columns downstream.
#'
#' \describe{
#'   \item{\code{{name}_cancer}}{Logical flag: \code{TRUE} if any cancer
#'     registry record satisfies all supplied filters.}
#'   \item{\code{{name}_cancer_date}}{Earliest matching diagnosis date
#'     (\code{IDate}).}
#' }
#'
#' @param data (data.frame or data.table) UKB phenotype data containing
#'   cancer registry fields.
#' @param name (character) Output column prefix, e.g. \code{"cscc_invasive"}
#'   produces \code{cscc_invasive_cancer} and
#'   \code{cscc_invasive_cancer_date}.
#' @param icd10 (character or NULL) Regular expression matched against the
#'   ICD-10 code column (\code{p40006}).  \code{NULL} = no ICD-10 filter.
#'   Examples: \code{"^C44"}, \code{"^(C44|D04)"}.
#' @param histology (integer vector or NULL) Histology codes to retain
#'   (\code{p40011}).  \code{NULL} = no histology filter.
#'   Example: \code{c(8070:8078, 8083, 8084)}.
#' @param behaviour (integer vector or NULL) Behaviour codes to retain
#'   (\code{p40012}).  \code{NULL} = no behaviour filter.
#'   Typical values: \code{3L} (invasive / malignant),
#'   \code{2L} (in situ).
#' @param code_cols (character or NULL) Names of ICD-10 code columns
#'   (\code{p40006_i*}).  \code{NULL} = auto-detect via field 40006.
#' @param hist_cols (character or NULL) Names of histology columns
#'   (\code{p40011_i*}).  \code{NULL} = auto-detect via field 40011.
#' @param behv_cols (character or NULL) Names of behaviour columns
#'   (\code{p40012_i*}).  \code{NULL} = auto-detect via field 40012.
#' @param date_cols (character or NULL) Names of diagnosis date columns
#'   (\code{p40005_i*}).  \code{NULL} = auto-detect via field 40005.
#'
#' @return The input \code{data} with two new columns added in-place:
#'   \code{{name}_cancer} (logical) and \code{{name}_cancer_date} (IDate).
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' # Invasive cSCC: C44 + specific histology + behaviour = 3
#' df <- derive_cancer_registry(
#'   df, name = "cscc_invasive",
#'   icd10     = "^C44",
#'   histology = c(8070:8078, 8083, 8084, 8051, 8052),
#'   behaviour = 3L
#' )
#'
#' # In situ: D04 (call twice for OR logic, combine downstream)
#' df <- derive_cancer_registry(df, name = "cscc_insitu_d04", icd10 = "^D04")
#' df <- derive_cancer_registry(
#'   df, name = "cscc_insitu_c44",
#'   icd10     = "^C44",
#'   histology = c(8070:8078, 8080, 8081, 8083, 8084),
#'   behaviour = 2L
#' )
#'
#' # All breast cancers (ICD-10 only, no histology/behaviour filter)
#' df <- derive_cancer_registry(df, name = "breast_cancer", icd10 = "^C50")
#' }
derive_cancer_registry <- function(data,
                                   name,
                                   icd10     = NULL,
                                   histology = NULL,
                                   behaviour = NULL,
                                   code_cols = NULL,
                                   hist_cols = NULL,
                                   behv_cols = NULL,
                                   date_cols = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!is.null(icd10) && (!is.character(icd10) || length(icd10) != 1L)) {
    stop("icd10 must be a single regex string or NULL.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  status_col <- paste0(name, "_cancer")
  date_col   <- paste0(name, "_cancer_date")

  # ── Auto-detect columns ────────────────────────────────────────────────────
  if (is.null(code_cols)) code_cols <- .detect_cols_by_field(data, 40006L)
  if (is.null(hist_cols)) hist_cols <- .detect_cols_by_field(data, 40011L)
  if (is.null(behv_cols)) behv_cols <- .detect_cols_by_field(data, 40012L)
  if (is.null(date_cols)) date_cols <- .detect_cols_by_field(data, 40005L)

  if (length(code_cols) == 0L) {
    cli::cli_alert_warning(
      "derive_cancer_registry: no ICD-10 code columns (p40006_i*) found. \\
       Supply code_cols manually."
    )
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    return(invisible(data))
  }

  # ── Extract instance indices ───────────────────────────────────────────────
  inst_raw  <- regmatches(code_cols,
                          regexpr("_i(\\d+)", code_cols, perl = TRUE))
  instances <- as.character(
    sort(as.integer(unique(sub("_i", "", inst_raw, fixed = TRUE))))
  )

  # ── Build long table: one row per (eid, instance) ─────────────────────────
  # Reason: cancer registry has no array (_a*) dimension — each instance is
  # a single record per field. rbindlist + lapply avoids melt entirely and
  # handles sparse / all-NA instances cleanly via fill = TRUE.
  long <- data.table::rbindlist(lapply(instances, function(inst) {

    c_col <- grep(paste0("_i", inst, "$"), code_cols, value = TRUE)
    if (length(c_col) != 1L) return(NULL)

    h_col <- grep(paste0("_i", inst, "$"), hist_cols, value = TRUE)
    b_col <- grep(paste0("_i", inst, "$"), behv_cols, value = TRUE)
    d_col <- grep(paste0("_i", inst, "$"), date_cols, value = TRUE)

    # Reason: pre-filter to rows with a non-empty ICD code before extracting
    # other columns — most instances are NA for most participants, so this
    # drops ~95% of rows at the source and keeps the long table small.
    data[
      !is.na(get(c_col)) & nchar(as.character(get(c_col))) > 0L,
      .(
        eid,
        icd_code  = as.character(get(c_col)),
        hist_code = if (length(h_col) == 1L)
                      suppressWarnings(as.integer(get(h_col)))
                    else
                      NA_integer_,
        behv_code = if (length(b_col) == 1L)
                      suppressWarnings(as.integer(get(b_col)))
                    else
                      NA_integer_,
        diag_date = if (length(d_col) == 1L)
                      data.table::as.IDate(as.character(get(d_col)))
                    else
                      data.table::as.IDate(NA_character_)
      )
    ]
  }), fill = TRUE)

  if (nrow(long) == 0L) {
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    cli::cli_alert_warning("derive_cancer_registry ({name}): 0 records found.")
    return(invisible(data))
  }

  # ── Multi-dimensional AND filter ───────────────────────────────────────────
  # Reason: column names (hist_code, behv_code) are distinct from parameter
  # names (histology, behaviour), so %in% comparisons are unambiguous.
  if (!is.null(icd10)) {
    long <- long[grepl(icd10, icd_code, ignore.case = TRUE, perl = TRUE)]
  }
  if (!is.null(histology)) {
    long <- long[!is.na(hist_code) & hist_code %in% histology]
  }
  if (!is.null(behaviour)) {
    long <- long[!is.na(behv_code) & behv_code %in% behaviour]
  }

  if (nrow(long) == 0L) {
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    cli::cli_alert_warning("derive_cancer_registry ({name}): 0 cases after filtering.")
    return(invisible(data))
  }

  # ── Write status and earliest date back to data ────────────────────────────
  data[, (status_col) := eid %in% long[, unique(eid)]]

  dates <- long[!is.na(diag_date),
                .(date = min(diag_date, na.rm = TRUE)),
                by = eid]
  data[, (date_col) := data.table::as.IDate(NA_character_)]
  data[dates, on = "eid", (date_col) := i.date]

  n_cases <- sum(data[[status_col]])
  n_dated  <- sum(!is.na(data[[date_col]]))
  cli::cli_alert_success(
    "derive_cancer_registry ({name}): {n_cases} case{?s}, {n_dated} with date."
  )

  data
}


#' Derive a binary disease flag from UKB death registry
#'
#' Death registry records store the underlying (primary) cause of death in
#' field \code{p40001} and contributory (secondary) causes in field
#' \code{p40002}, both coded in ICD-10.  The date of death is in field
#' \code{p40000}.  All three fields have an instance dimension (\code{i0},
#' \code{i1}) reflecting potential amendments; \code{p40002} additionally
#' has an array dimension (\code{a0}, \code{a1}, \ldots).
#'
#' \describe{
#'   \item{\code{{name}_death}}{Logical flag: \code{TRUE} if any death
#'     registry record (primary or secondary cause) contains a matching
#'     ICD-10 code.}
#'   \item{\code{{name}_death_date}}{Earliest death date across matching
#'     instances (\code{IDate}).  Note: this is the \emph{date of death},
#'     not onset date.}
#' }
#'
#' @param data (data.frame or data.table) UKB phenotype data containing
#'   death registry fields.
#' @param name (character) Output column prefix, e.g. \code{"ad"} produces
#'   \code{ad_death} and \code{ad_death_date}.
#' @param icd10 (character) ICD-10 code(s) to match.  For \code{"prefix"}
#'   and \code{"exact"}, supply a vector such as \code{c("L20", "L21")}.
#'   For \code{"regex"}, supply a single regex string.
#' @param match (character) Matching strategy: \code{"prefix"} (default),
#'   \code{"exact"}, or \code{"regex"}.
#' @param primary_cols (character or NULL) Names of primary cause columns
#'   (\code{p40001_i*}).  \code{NULL} = auto-detect via field 40001.
#' @param secondary_cols (character or NULL) Names of secondary cause
#'   columns (\code{p40002_i*_a*}).  \code{NULL} = auto-detect via field
#'   40002.
#' @param date_cols (character or NULL) Names of death date columns
#'   (\code{p40000_i*}).  \code{NULL} = auto-detect via field 40000.
#'
#' @return The input \code{data} with two new columns added in-place:
#'   \code{{name}_death} (logical) and \code{{name}_death_date} (IDate).
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' df <- derive_death_registry(df, name = "ad", icd10 = "L20")
#' df <- derive_death_registry(df, name = "copd",
#'                             icd10 = c("J440", "J441"), match = "exact")
#' }
derive_death_registry <- function(data,
                                  name,
                                  icd10,
                                  match          = c("prefix", "exact", "regex"),
                                  primary_cols   = NULL,
                                  secondary_cols = NULL,
                                  date_cols      = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  match      <- match.arg(match)
  status_col <- paste0(name, "_death")
  date_col   <- paste0(name, "_death_date")

  # ── Auto-detect columns ────────────────────────────────────────────────────
  if (is.null(primary_cols))   primary_cols   <- .detect_cols_by_field(data, 40001L)
  if (is.null(secondary_cols)) secondary_cols <- .detect_cols_by_field(data, 40002L)
  if (is.null(date_cols))      date_cols      <- .detect_cols_by_field(data, 40000L)

  if (length(primary_cols) == 0L && length(secondary_cols) == 0L) {
    cli::cli_alert_warning(
      "derive_death_registry: no death cause columns found. \\
       Supply primary_cols / secondary_cols manually."
    )
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    return(invisible(data))
  }

  # ── Build ICD-10 match pattern ─────────────────────────────────────────────
  pattern <- switch(match,
    prefix = paste0("^(", paste(icd10, collapse = "|"), ")"),
    exact  = paste0("^(", paste(icd10, collapse = "|"), ")$"),
    regex  = icd10[1L]
  )

  # ── Detect instances from primary cause columns ────────────────────────────
  inst_src  <- if (length(primary_cols) > 0L) primary_cols else secondary_cols
  inst_raw  <- regmatches(inst_src, regexpr("_i(\\d+)", inst_src, perl = TRUE))
  instances <- sort(unique(sub("_i", "", inst_raw, fixed = TRUE)))

  results <- vector("list", length(instances))
  names(results) <- instances

  for (inst in instances) {

    matched_eids <- integer(0L)

    # ── ① Primary cause: single column per instance, direct grepl ─────────
    p_col <- grep(paste0("_i", inst, "$"), primary_cols, value = TRUE)
    if (length(p_col) == 1L) {
      # Reason: pure data.table [i, j] avoids copying the column to a
      # separate vector — zero extra allocation.
      hits <- data[
        !is.na(get(p_col)) &
        grepl(pattern, as.character(get(p_col)), ignore.case = TRUE, perl = TRUE),
        eid
      ]
      matched_eids <- union(matched_eids, hits)
    }

    # ── ② Secondary causes: melt instance array columns, then grepl ───────
    s_cols <- grep(paste0("_i", inst, "_a"), secondary_cols, value = TRUE)
    if (length(s_cols) > 0L) {
      sub_s <- data.table::copy(data[, c("eid", s_cols), with = FALSE])
      for (.c in s_cols) {
        data.table::set(sub_s, j = .c, value = as.character(sub_s[[.c]]))
      }
      long_s <- data.table::melt(sub_s,
                                  id.vars       = "eid",
                                  measure.vars  = s_cols,
                                  variable.name = "array_idx",
                                  value.name    = "icd_code",
                                  na.rm         = TRUE)
      long_s <- long_s[
        nchar(as.character(icd_code)) > 0L &
        grepl(pattern, icd_code, ignore.case = TRUE, perl = TRUE)
      ]
      matched_eids <- union(matched_eids, unique(long_s$eid))
    }

    if (length(matched_eids) == 0L) next

    # ── ③ Death date: p40000_iX (instance level) ──────────────────────────
    d_col <- grep(paste0("_i", inst, "$"), date_cols, value = TRUE)
    if (length(d_col) == 1L) {
      # Reason: filter to matched eids first, then parse dates — avoids
      # converting the full 500k-row date column for a handful of matches.
      death_dates <- data[
        eid %in% matched_eids,
        .(eid, death_date = data.table::as.IDate(as.character(get(d_col))))
      ]
    } else {
      death_dates <- data.table::data.table(
        eid        = matched_eids,
        death_date = data.table::as.IDate(NA_character_)
      )
    }

    results[[inst]] <- death_dates
  }

  # ── Combine across instances ───────────────────────────────────────────────
  results <- Filter(Negate(is.null), results)

  if (length(results) == 0L) {
    data[, (status_col) := FALSE]
    data[, (date_col)   := data.table::as.IDate(NA_character_)]
    cli::cli_alert_warning("derive_death_registry ({name}): 0 cases found.")
    return(invisible(data))
  }

  combined <- data.table::rbindlist(results, fill = TRUE)

  # Status: any matching death cause record
  data[, (status_col) := eid %in% unique(combined$eid)]

  # Earliest death date per eid — update-on-join (zero-copy)
  dates <- combined[!is.na(death_date),
                    .(date = min(death_date, na.rm = TRUE)),
                    by = eid]
  data[, (date_col) := data.table::as.IDate(NA_character_)]
  data[dates, on = "eid", (date_col) := i.date]

  n_cases <- sum(data[[status_col]])
  n_dated  <- sum(!is.na(data[[date_col]]))
  cli::cli_alert_success(
    "derive_death_registry ({name}): {n_cases} case{?s}, {n_dated} with date."
  )

  data
}


#' Derive a unified ICD-10 disease flag across multiple UKB data sources
#'
#' A high-level wrapper that calls one or more of \code{\link{derive_hes}},
#' \code{\link{derive_death_registry}}, \code{\link{derive_first_occurrence}},
#' and \code{\link{derive_cancer_registry}} according to the \code{source}
#' argument, then combines their results into a single status flag and
#' earliest-date column.
#'
#' All intermediate source columns (\code{{name}_hes}, \code{{name}_death},
#' \code{{name}_fo}, \code{{name}_cancer} and their \code{_date} counterparts)
#' are retained in \code{data} so that per-source contributions remain
#' traceable.
#'
#' \describe{
#'   \item{\code{{name}_icd10}}{Logical flag: \code{TRUE} if any selected
#'     source contains a matching record.}
#'   \item{\code{{name}_icd10_date}}{Earliest matching date across all
#'     selected sources (\code{IDate}).}
#' }
#'
#' @param data (data.frame or data.table) UKB phenotype data.
#' @param name (character) Output column prefix, e.g. \code{"ad"} produces
#'   \code{ad_icd10} and \code{ad_icd10_date}, plus intermediate columns
#'   such as \code{ad_hes}, \code{ad_hes_date}, etc.
#' @param icd10 (character) ICD-10 code(s) to match.  For \code{"prefix"}
#'   and \code{"exact"}, supply a vector such as \code{c("L20", "L21")}.
#'   For \code{"regex"}, supply a single regex string.  When
#'   \code{"cancer_registry"} is included in \code{source}, \code{icd10}
#'   and \code{match} are automatically converted to a regex and passed to
#'   \code{\link{derive_cancer_registry}}.
#' @param source (character) One or more of \code{"hes"},
#'   \code{"death"}, \code{"first_occurrence"}, \code{"cancer_registry"}.
#'   Defaults to all four.
#' @param match (character) Matching strategy passed to \code{derive_hes}
#'   and \code{derive_death_registry}: \code{"prefix"} (default),
#'   \code{"exact"}, or \code{"regex"}.
#' @param fo_field (integer or character or NULL) UKB field ID for the
#'   First Occurrence column (e.g. \code{131720L} for AD).  Required when
#'   \code{"first_occurrence"} is in \code{source} and \code{fo_col} is
#'   \code{NULL}.
#' @param fo_col (character or NULL) Column name of the First Occurrence
#'   field in \code{data}.  Alternative to \code{fo_field}.
#' @param histology (integer vector or NULL) Passed to
#'   \code{\link{derive_cancer_registry}}.  Ignored for other sources.
#' @param behaviour (integer vector or NULL) Passed to
#'   \code{\link{derive_cancer_registry}}.  Ignored for other sources.
#' @param hes_code_col (character or NULL) Passed as \code{disease_cols}
#'   to \code{\link{derive_hes}}.
#' @param hes_date_cols (character or NULL) Passed as \code{date_cols}
#'   to \code{\link{derive_hes}}.
#' @param primary_cols (character or NULL) Passed to
#'   \code{\link{derive_death_registry}}.
#' @param secondary_cols (character or NULL) Passed to
#'   \code{\link{derive_death_registry}}.
#' @param death_date_cols (character or NULL) Passed as \code{date_cols}
#'   to \code{\link{derive_death_registry}}.
#' @param cr_code_cols (character or NULL) Passed as \code{code_cols}
#'   to \code{\link{derive_cancer_registry}}.
#' @param cr_hist_cols (character or NULL) Passed as \code{hist_cols}
#'   to \code{\link{derive_cancer_registry}}.
#' @param cr_behv_cols (character or NULL) Passed as \code{behv_cols}
#'   to \code{\link{derive_cancer_registry}}.
#' @param cr_date_cols (character or NULL) Passed as \code{date_cols}
#'   to \code{\link{derive_cancer_registry}}.
#'
#' @return The input \code{data} with \code{{name}_icd10} (logical) and
#'   \code{{name}_icd10_date} (IDate) added in-place, plus all intermediate
#'   source columns.  Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' # AD (atopic dermatitis): HES + death + First Occurrence
#' df <- derive_icd10(df, name = "ad", icd10 = "L20",
#'                    source    = c("hes", "death", "first_occurrence"),
#'                    fo_field  = 131720L)
#'
#' # COPD: HES + death only, exact 4-digit codes
#' df <- derive_icd10(df, name = "copd",
#'                    icd10  = c("J440", "J441"),
#'                    source = c("hes", "death"),
#'                    match  = "exact")
#'
#' # Invasive cSCC: all four sources, cancer registry filtered by histology
#' df <- derive_icd10(df, name = "cscc_invasive",
#'                    icd10     = "^C44",
#'                    match     = "regex",
#'                    source    = c("hes", "death", "cancer_registry"),
#'                    histology = c(8070:8078, 8083, 8084, 8051, 8052),
#'                    behaviour = 3L)
#' }
derive_icd10 <- function(data,
                         name,
                         icd10,
                         source          = c("hes", "death",
                                             "first_occurrence",
                                             "cancer_registry"),
                         match           = c("prefix", "exact", "regex"),
                         fo_field        = NULL,
                         fo_col          = NULL,
                         histology       = NULL,
                         behaviour       = NULL,
                         hes_code_col    = NULL,
                         hes_date_cols   = NULL,
                         primary_cols    = NULL,
                         secondary_cols  = NULL,
                         death_date_cols = NULL,
                         cr_code_cols    = NULL,
                         cr_hist_cols    = NULL,
                         cr_behv_cols    = NULL,
                         cr_date_cols    = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  source     <- match.arg(source, several.ok = TRUE)
  match      <- match.arg(match)
  status_col <- paste0(name, "_icd10")
  date_col   <- paste0(name, "_icd10_date")

  # ── HES ───────────────────────────────────────────────────────────────────
  if ("hes" %in% source) {
    data <- derive_hes(data, name = name, icd10 = icd10, match = match,
                       disease_cols = hes_code_col,
                       date_cols    = hes_date_cols)
  }

  # ── Death registry ─────────────────────────────────────────────────────────
  if ("death" %in% source) {
    data <- derive_death_registry(data, name = name, icd10 = icd10,
                                  match          = match,
                                  primary_cols   = primary_cols,
                                  secondary_cols = secondary_cols,
                                  date_cols      = death_date_cols)
  }

  # ── First Occurrence ───────────────────────────────────────────────────────
  if ("first_occurrence" %in% source) {
    if (is.null(fo_field) && is.null(fo_col)) {
      cli::cli_alert_warning(
        "derive_icd10: 'first_occurrence' selected but fo_field and fo_col \\
         are both NULL — skipping this source."
      )
    } else {
      data <- derive_first_occurrence(data, name = name,
                                      field = fo_field, col = fo_col)
    }
  }

  # ── Cancer registry ────────────────────────────────────────────────────────
  if ("cancer_registry" %in% source) {
    # Reason: derive_cancer_registry takes a single regex string, not a vector
    # + match mode. Convert here so the caller only needs one set of params.
    icd10_regex <- switch(match,
      prefix = paste0("^(", paste(icd10, collapse = "|"), ")"),
      exact  = paste0("^(", paste(icd10, collapse = "|"), ")$"),
      regex  = icd10[1L]
    )
    data <- derive_cancer_registry(data, name = name, icd10 = icd10_regex,
                                   histology = histology,
                                   behaviour = behaviour,
                                   code_cols = cr_code_cols,
                                   hist_cols = cr_hist_cols,
                                   behv_cols = cr_behv_cols,
                                   date_cols = cr_date_cols)
  }

  # ── Collect active intermediate columns ────────────────────────────────────
  fo_ran <- "first_occurrence" %in% source &&
            (!is.null(fo_field) || !is.null(fo_col))

  active_status <- intersect(
    c(if ("hes"              %in% source) paste0(name, "_hes"),
      if ("death"            %in% source) paste0(name, "_death"),
      if (fo_ran)                         paste0(name, "_fo"),
      if ("cancer_registry"  %in% source) paste0(name, "_cancer")),
    names(data)
  )
  active_dates <- intersect(
    c(if ("hes"              %in% source) paste0(name, "_hes_date"),
      if ("death"            %in% source) paste0(name, "_death_date"),
      if (fo_ran)                         paste0(name, "_fo_date"),
      if ("cancer_registry"  %in% source) paste0(name, "_cancer_date")),
    names(data)
  )

  # ── Combine: OR for status, pmin for date ──────────────────────────────────
  data[, (status_col) := Reduce(`|`, lapply(active_status, function(col) data[[col]]))]

  if (length(active_dates) > 0L) {
    date_list <- lapply(active_dates, function(col) data[[col]])
    data[, (date_col) := data.table::as.IDate(
      do.call(pmin, c(date_list, list(na.rm = TRUE)))
    )]
  } else {
    data[, (date_col) := data.table::as.IDate(NA_character_)]
  }

  n_cases  <- sum(data[[status_col]], na.rm = TRUE)
  n_dated  <- sum(!is.na(data[[date_col]]))
  n_src    <- length(active_status)
  cli::cli_alert_success(
    "derive_icd10 ({name}): {n_cases} case{?s} across \\
     {n_src} source{?s}, {n_dated} with date."
  )

  data
}


#' Combine self-report and ICD-10 sources into a unified case definition
#'
#' Takes the self-report flag and ICD-10 flag produced by
#' \code{\link{derive_selfreport}} and \code{\link{derive_icd10}} (or any
#' pair of logical columns) and merges them into a single logical case status
#' and earliest date.
#'
#' \describe{
#'   \item{\code{{name}_status}}{Logical: \code{TRUE} if positive in at
#'     least one source.}
#'   \item{\code{{name}_date}}{Earliest diagnosis/report date across both
#'     sources (\code{IDate}).}
#' }
#'
#' @param data (data.frame or data.table) UKB phenotype data.
#' @param name (character) Column prefix used both to locate the default
#'   input columns and to name the output columns.  Defaults:
#'   \code{{name}_icd10}, \code{{name}_selfreport},
#'   \code{{name}_icd10_date}, \code{{name}_selfreport_date}.
#' @param icd10_col (character or NULL) Name of the ICD-10 status column.
#'   \code{NULL} = \code{paste0(name, "_icd10")}.
#' @param selfreport_col (character or NULL) Name of the self-report status
#'   column.  \code{NULL} = \code{paste0(name, "_selfreport")}.
#' @param icd10_date_col (character or NULL) Name of the ICD-10 date column.
#'   \code{NULL} = \code{paste0(name, "_icd10_date")}.
#' @param selfreport_date_col (character or NULL) Name of the self-report date
#'   column.  \code{NULL} = \code{paste0(name, "_selfreport_date")}.
#'
#' @return The input \code{data} with two new columns added in-place:
#'   \code{{name}_status} (logical) and \code{{name}_date} (IDate).
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' # Default: looks for ad_icd10, ad_selfreport, ad_icd10_date, ad_selfreport_date
#' df <- derive_case(df, name = "ad")
#'
#' # Explicit column names
#' df <- derive_case(df, name = "ad",
#'                   icd10_col      = "ad_icd10",
#'                   selfreport_col = "ad_selfreport_noncancer")
#' }
derive_case <- function(data,
                        name,
                        icd10_col           = NULL,
                        selfreport_col      = NULL,
                        icd10_date_col      = NULL,
                        selfreport_date_col = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  # ── Resolve column names ───────────────────────────────────────────────────
  icd10_col           <- icd10_col           %||% paste0(name, "_icd10")
  selfreport_col      <- selfreport_col      %||% paste0(name, "_selfreport")
  icd10_date_col      <- icd10_date_col      %||% paste0(name, "_icd10_date")
  selfreport_date_col <- selfreport_date_col %||% paste0(name, "_selfreport_date")

  status_col <- paste0(name, "_status")
  date_col   <- paste0(name, "_date")

  # ── Validate presence ──────────────────────────────────────────────────────
  status_cols_present <- intersect(c(icd10_col, selfreport_col), names(data))
  if (length(status_cols_present) == 0L) {
    stop(
      "derive_case: neither '", icd10_col, "' nor '", selfreport_col,
      "' found in data. Supply column names explicitly.", call. = FALSE
    )
  }
  if (length(status_cols_present) < 2L) {
    cli::cli_alert_warning(
      "derive_case ({name}): only one status column found \\
       ({status_cols_present[1L]}), combining with itself."
    )
  }

  date_cols_present <- intersect(c(icd10_date_col, selfreport_date_col), names(data))

  # ── Status: OR across available status columns → logical ──────────────────
  data[, (status_col) := Reduce(`|`, lapply(status_cols_present, function(col) data[[col]]))]

  # ── Date: earliest across available date columns ───────────────────────────
  if (length(date_cols_present) > 0L) {
    date_list <- lapply(date_cols_present, function(col) data[[col]])
    data[, (date_col) := data.table::as.IDate(
      do.call(pmin, c(date_list, list(na.rm = TRUE)))
    )]
  } else {
    data[, (date_col) := data.table::as.IDate(NA_character_)]
  }

  # ── CLI summary ────────────────────────────────────────────────────────────
  n_cases <- sum(data[[status_col]], na.rm = TRUE)
  n_dated  <- sum(!is.na(data[[date_col]]))
  cli::cli_alert_success(
    "derive_case ({name}): {n_cases} case{?s}, {n_dated} with date."
  )
  if (length(status_cols_present) == 2L) {
    n_both <- sum(data[[status_cols_present[1L]]] & data[[status_cols_present[2L]]],
                  na.rm = TRUE)
    cli::cli_alert_info(
      "  Both sources ({icd10_col} & {selfreport_col}): {n_both}"
    )
  }

  data
}


#' Classify disease timing relative to UKB baseline assessment
#'
#' Assigns each participant an integer timing category based on whether their
#' disease date falls before or after the baseline visit date:
#'
#' \describe{
#'   \item{\code{0}}{No disease (\code{status_col} is \code{FALSE}).}
#'   \item{\code{1}}{Prevalent — disease date on or before baseline.}
#'   \item{\code{2}}{Incident — disease date strictly after baseline.}
#'   \item{\code{NA}}{Case with missing date; timing cannot be determined.}
#' }
#'
#' Call once per timing variable needed (e.g. once for the combined case,
#' once per individual source).
#'
#' @param data (data.frame or data.table) UKB phenotype data.
#' @param name (character) Output column prefix.  The new column is named
#'   \code{{name}_timing}.  Also used to derive default \code{status_col}
#'   and \code{date_col} when those are \code{NULL}.
#' @param baseline_col (character) Name of the baseline date column in
#'   \code{data} (e.g. \code{"date_baseline"} or \code{"p53_i0"}).
#' @param status_col (character or NULL) Name of the logical disease flag.
#'   \code{NULL} = \code{paste0(name, "_status")}.
#' @param date_col (character or NULL) Name of the disease date column
#'   (\code{IDate} or \code{Date}).
#'   \code{NULL} = \code{paste0(name, "_date")}.
#'
#' @return The input \code{data} with one new integer column
#'   \code{{name}_timing} (0/1/2/\code{NA}) added in-place.
#'   Always returns a \code{data.table}.
#' @export
#'
#' @examples
#' \dontrun{
#' # Combined case timing (uses ad_status + ad_date from derive_case)
#' df <- derive_timing(df, name = "ad", baseline_col = "date_baseline")
#' # → ad_timing
#'
#' # Individual source timing
#' df <- derive_timing(df, name = "ad_icd10",
#'                     status_col   = "ad_icd10",
#'                     date_col     = "ad_icd10_date",
#'                     baseline_col = "date_baseline")
#' # → ad_icd10_timing
#' }


#' Compute age at event for one or more UKB outcomes
#'
#' For each name in \code{name}, adds one column \code{age_at_{name}} (numeric,
#' years) computed as:
#' \deqn{age\_at\_event = age\_col + (event\_date - baseline\_date) / 365.25}
#'
#' The value is \code{NA} for participants who did not experience the event
#' (status is \code{FALSE} / \code{0}) or who lack an event date.
#'
#' \strong{Auto-detection per name} (when \code{date_cols} / \code{status_cols}
#' are \code{NULL}):
#' \itemize{
#'   \item \code{date_col}   — looked up as \code{{name}_date}.
#'   \item \code{status_col} — looked up first as \code{{name}_status}, then
#'     as \code{{name}} (logical column); if neither exists all rows with a
#'     non-\code{NA} date are treated as cases.
#' }
#'
#' \strong{data.table pass-by-reference}: new columns are added in-place.
#'
#' @param data (data.frame or data.table) UKB phenotype data.
#' @param name (character) One or more output prefixes, e.g.
#'   \code{c("ad", "ad_icd10", "cscc")}. Each produces \code{age_at_{name}}.
#' @param baseline_col (character) Name of the baseline date column
#'   (e.g. \code{"date_baseline"}).
#' @param age_col (character) Name of the age-at-baseline column
#'   (e.g. \code{"age_recruitment"}).
#' @param date_cols (character or NULL) Named character vector mapping each
#'   name to its event date column, e.g.
#'   \code{c(ad = "ad_date", cscc = "cscc_date")}. \code{NULL} (default)
#'   triggers auto-detection as \code{{name}_date}.
#' @param status_cols (character or NULL) Named character vector mapping each
#'   name to its status column. \code{NULL} (default) triggers auto-detection.
#'
#' @return The input \code{data} with one new \code{age_at_{name}} column
#'   per entry in \code{name}, added in-place.
#' @export
#'
#' @examples
#' \dontrun{
#' # Process multiple events in one call — auto-detects {name}_date and
#' # {name}_status for each
#' df <- derive_age(df,
#'   name         = c("ad", "ad_icd10", "ad_selfreport",
#'                    "cscc", "cscc_invasive", "cscc_insitu"),
#'   baseline_col = "date_baseline",
#'   age_col      = "age_recruitment")
#' # → age_at_ad, age_at_ad_icd10, age_at_ad_selfreport,
#' #   age_at_cscc, age_at_cscc_invasive, age_at_cscc_insitu
#' }
derive_age <- function(data,
                       name,
                       baseline_col,
                       age_col,
                       date_cols   = NULL,
                       status_cols = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) == 0L) {
    stop("name must be a non-empty character vector.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  for (col in c(baseline_col, age_col)) {
    if (!col %in% names(data)) {
      stop("derive_age: column '", col, "' not found in data.", call. = FALSE)
    }
  }

  # ── Process each name ──────────────────────────────────────────────────────
  for (nm in name) {

    out_col <- paste0("age_at_", nm)

    # ── Resolve date column ──────────────────────────────────────────────────
    date_col <- if (!is.null(date_cols) && nm %in% names(date_cols)) date_cols[[nm]] else NULL
    date_col <- date_col %||% paste0(nm, "_date")

    if (!date_col %in% names(data)) {
      cli::cli_alert_warning("derive_age: date column '{date_col}' not found — skipping {nm}.")
      next
    }

    # ── Resolve status column (optional guard) ───────────────────────────────
    # Reason: status may be integer (0/1) or logical; try {name}_status first,
    # then bare {name}, then fall back to NA-date guard only.
    status_col <- if (!is.null(status_cols) && nm %in% names(status_cols)) status_cols[[nm]] else NULL
    if (is.null(status_col)) {
      if (paste0(nm, "_status") %in% names(data)) {
        status_col <- paste0(nm, "_status")
      } else if (nm %in% names(data) && is.logical(data[[nm]])) {
        status_col <- nm
      }
    }

    # ── Compute age at event in-place ────────────────────────────────────────
    # Condition: participant is a case AND has a recorded event date.
    # When no status column exists, compute for all rows with non-NA date.
    if (!is.null(status_col)) {
      s <- data[[status_col]]
      is_case <- if (is.logical(s)) s else s == 1L
      data[, (out_col) := data.table::fifelse(
        is_case & !is.na(get(date_col)),
        get(age_col) + as.numeric(
          data.table::as.IDate(get(date_col)) -
          data.table::as.IDate(get(baseline_col))
        ) / 365.25,
        NA_real_
      )]
    } else {
      data[, (out_col) := data.table::fifelse(
        !is.na(get(date_col)),
        get(age_col) + as.numeric(
          data.table::as.IDate(get(date_col)) -
          data.table::as.IDate(get(baseline_col))
        ) / 365.25,
        NA_real_
      )]
    }

    # ── CLI summary ──────────────────────────────────────────────────────────
    v <- data[[out_col]]
    n_cases <- sum(!is.na(v))
    cli::cli_alert_info(
      "  {out_col}: n={n_cases}, median={round(median(v, na.rm=TRUE), 1)}, range=[{round(min(v, na.rm=TRUE), 1)}, {round(max(v, na.rm=TRUE), 1)}]"
    )
  }

  cli::cli_alert_success("derive_age: {length(name)} event{?s} processed.")
  data
}


#' Compute follow-up end date and follow-up time for survival analysis
#'
#' Adds two columns to \code{data}:
#' \itemize{
#'   \item \code{{name}_followup_end} (IDate) — the earliest of the outcome
#'     event date, death date, lost-to-follow-up date, and the administrative
#'     censoring date.
#'   \item \code{{name}_followup_years} (numeric) — time in years from
#'     \code{baseline_col} to \code{{name}_followup_end}.
#' }
#'
#' \strong{data.table pass-by-reference}: when the input is a
#' \code{data.table}, new columns are added in-place via \code{:=}.
#'
#' @param data (data.frame or data.table) UKB phenotype data.
#' @param name (character) Output column prefix, e.g. \code{"cscc"} produces
#'   \code{cscc_followup_end} and \code{cscc_followup_years}.
#' @param event_col (character) Name of the outcome event date column
#'   (e.g. \code{"cscc_date"}).
#' @param baseline_col (character) Name of the baseline date column
#'   (e.g. \code{"date_baseline"}).
#' @param censor_date (Date or character) Scalar administrative censoring date,
#'   e.g. \code{as.Date("2022-06-01")}.  A character string in
#'   \code{"YYYY-MM-DD"} format is also accepted.
#' @param death_col (character or NULL) Name of the death date column
#'   (UKB field 40000).  \code{NULL} (default) triggers auto-detection via
#'   the \code{\link{extract_ls}} cache; pass \code{FALSE} to explicitly
#'   disable death as a competing end-point.
#' @param lost_col (character or NULL) Name of the lost-to-follow-up date
#'   column (UKB field 191).  \code{NULL} (default) triggers auto-detection;
#'   pass \code{FALSE} to explicitly disable.
#'
#' @return The input \code{data} with two new columns added in-place:
#'   \code{{name}_followup_end} (IDate) and \code{{name}_followup_years}
#'   (numeric).
#' @export
#'
#' @examples
#' \dontrun{
#' df <- derive_followup(df,
#'   name         = "cscc",
#'   event_col    = "cscc_date",
#'   baseline_col = "date_baseline",
#'   censor_date  = as.Date("2022-06-01"),
#'   death_col    = "date_death",
#'   lost_col     = "date_lost_followup")
#' # → df$cscc_followup_end    IDate
#' # → df$cscc_followup_years  numeric
#' }
derive_followup <- function(data,
                            name,
                            event_col,
                            baseline_col,
                            censor_date,
                            death_col = NULL,
                            lost_col  = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  # ── Auto-detect death / lost-to-follow-up columns from extract_ls() cache ──
  # Reason: UKB field 40000 = date of death, field 191 = date lost to follow-up.
  # When the user does not supply these, try to locate them automatically so
  # the function works out-of-the-box after extract_pheno() + decode_names().
  if (is.null(death_col)) death_col <- .detect_fo_col(data, 40000L)
  if (is.null(lost_col))  lost_col  <- .detect_fo_col(data, 191L)

  # ── Validate required columns ──────────────────────────────────────────────
  for (col in c(event_col, baseline_col)) {
    if (!col %in% names(data)) {
      stop("derive_followup: column '", col, "' not found in data.", call. = FALSE)
    }
  }
  if (!is.null(death_col) && !death_col %in% names(data)) {
    stop("derive_followup: death_col '", death_col, "' not found in data.", call. = FALSE)
  }
  if (!is.null(lost_col) && !lost_col %in% names(data)) {
    stop("derive_followup: lost_col '", lost_col, "' not found in data.", call. = FALSE)
  }

  censor_date <- data.table::as.IDate(censor_date)

  # ── Output column names ────────────────────────────────────────────────────
  end_col   <- paste0(name, "_followup_end")
  years_col <- paste0(name, "_followup_years")

  # ── Collect date columns for pmin ─────────────────────────────────────────
  # Reason: using .SDcols keeps column references inside data.table's j-scope;
  # valid_date_cols collects only columns that are actually present.
  valid_date_cols <- event_col
  if (!is.null(death_col)) valid_date_cols <- c(valid_date_cols, death_col)
  if (!is.null(lost_col))  valid_date_cols <- c(valid_date_cols, lost_col)

  # ── Compute follow-up end (earliest competing date) ────────────────────────
  data[, (end_col) := data.table::as.IDate(
    do.call(pmin, c(.SD, list(censor_date), list(na.rm = TRUE)))
  ), .SDcols = valid_date_cols]

  # ── Compute follow-up time in years ───────────────────────────────────────
  data[, (years_col) := as.numeric(get(end_col) - data.table::as.IDate(get(baseline_col))) / 365.25]

  # ── CLI summary ────────────────────────────────────────────────────────────
  yrs <- data[[years_col]]
  cli::cli_alert_success("derive_followup ({name}):")
  cli::cli_alert_info("  {end_col}: {sum(!is.na(data[[end_col]]))} / {nrow(data)} non-missing")
  cli::cli_alert_info("  {years_col}: mean={round(mean(yrs, na.rm=TRUE), 2)}, median={round(median(yrs, na.rm=TRUE), 2)}, range=[{round(min(yrs, na.rm=TRUE), 2)}, {round(max(yrs, na.rm=TRUE), 2)}]")

  data
}


derive_timing <- function(data,
                          name,
                          baseline_col,
                          status_col = NULL,
                          date_col   = NULL) {

  if (!is.data.frame(data)) {
    stop("data must be a data.frame or data.table.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L) {
    stop("name must be a single string.", call. = FALSE)
  }
  if (!data.table::is.data.table(data)) data <- data.table::as.data.table(data)

  # ── Resolve column names ───────────────────────────────────────────────────
  status_col  <- status_col  %||% paste0(name, "_status")
  date_col    <- date_col    %||% paste0(name, "_date")
  timing_col  <- paste0(name, "_timing")

  for (col in c(status_col, date_col, baseline_col)) {
    if (!col %in% names(data)) {
      stop("derive_timing: column '", col, "' not found in data.", call. = FALSE)
    }
  }

  # ── Classify timing with fcase (data.table's vectorised case_when) ─────────
  # Reason: fcase evaluates conditions sequentially and short-circuits,
  # making it faster than nested ifelse and cleaner than case_when.
  data[, (timing_col) := data.table::fcase(
    !get(status_col),                                                          0L,
    get(status_col) & !is.na(get(date_col)) &
      get(date_col) <= data.table::as.IDate(get(baseline_col)),               1L,
    get(status_col) & !is.na(get(date_col)) &
      get(date_col) >  data.table::as.IDate(get(baseline_col)),               2L,
    default = NA_integer_
  )]

  # ── CLI summary ────────────────────────────────────────────────────────────
  tv <- data[[timing_col]]
  cli::cli_alert_success("derive_timing ({name}_timing):")
  cli::cli_alert_info("  0 (no disease): {sum(tv == 0L, na.rm = TRUE)}")
  cli::cli_alert_info("  1 (prevalent):  {sum(tv == 1L, na.rm = TRUE)}")
  cli::cli_alert_info("  2 (incident):   {sum(tv == 2L, na.rm = TRUE)}")
  cli::cli_alert_info("  NA (no date):   {sum(is.na(tv))}")

  data
}
