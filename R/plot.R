# =============================================================================
# plot.R — publication-ready visualisation for ukbflow
# =============================================================================


#' Publication-ready forest plot
#'
#' Produces a publication-ready forest plot with UKB-standard styling.
#' The user supplies a data frame whose first column is the row label
#' (\code{item}), plus any additional display columns (e.g. \code{Cases/N}).
#' The gap column and the auto-formatted \code{OR (95\% CI)} text column are
#' inserted automatically at \code{ci_column}. Numeric p-value columns
#' declared via \code{p_cols} are formatted in-place.
#'
#' @param data data.frame. First column must be the label column (\code{item}).
#'   Additional columns are displayed as-is (character) or formatted if named
#'   in \code{p_cols} (must be numeric). Column order is preserved.
#' @param est Numeric vector. Point estimates (\code{NA} = no CI drawn).
#' @param lower Numeric vector. Lower CI bounds (same length as \code{est}).
#' @param upper Numeric vector. Upper CI bounds (same length as \code{est}).
#' @param ci_column Integer. Column position in the final rendered table where
#'   the gap/CI graphic is placed. Must be between \code{2} and
#'   \code{ncol(data) + 1} (inclusive). Default: \code{2L}.
#' @param ref_line Numeric. Reference line. Default: \code{1} (HR/OR).
#'   Use \code{0} for beta coefficients.
#' @param xlim Numeric vector of length 2. X-axis limits. \code{NULL} = auto.
#' @param ticks_at Numeric vector. Tick positions. \code{NULL} = 5 evenly
#'   spaced ticks when \code{xlim} is supplied, otherwise auto.
#' @param arrow_lab Character vector of length 2. Directional labels.
#'   Default: \code{c("Lower risk", "Higher risk")}. \code{NULL} = none.
#' @param header Character vector of length \code{ncol(data) + 2}. Column
#'   header labels for the final rendered table (original columns + gap_ci +
#'   OR label). \code{NULL} (default) = use column names from \code{data} plus
#'   \code{"gap_ci"} and \code{"OR (95\% CI)"}. Pass \code{""} for the gap
#'   column position.
#' @param indent Integer vector (length = \code{nrow(data)}). Indentation
#'   level of the label column: each unit adds two leading spaces.
#'   Default: all zeros.
#' @param bold_label Logical vector (length = \code{nrow(data)}). Which rows
#'   to bold in the label column. \code{NULL} (default) = auto-derive from
#'   \code{indent}: rows where \code{indent == 0} are bolded (parent rows),
#'   indented sub-rows are plain.
#' @param ci_col Character scalar or vector (length = \code{nrow(data)}).
#'   CI colour(s). \code{NA} rows are skipped automatically.
#'   Default: \code{"black"}.
#' @param ci_sizes Numeric. Point size. Default: \code{0.6}.
#' @param ci_Theight Numeric. CI cap height. Default: \code{0.2}.
#' @param ci_digits Integer. Decimal places for the auto-generated
#'   \code{OR (95\% CI)} column. Default: \code{2L}.
#' @param ci_sep Character. Separator between lower and upper CI in the label,
#'   e.g. \code{", "} or \code{" - "}. Default: \code{", "}.
#' @param p_cols Character vector. Names of numeric p-value columns in
#'   \code{data}. These are formatted to \code{p_digits} decimal places with
#'   \code{"<0.001"}-style clipping. \code{NULL} = none.
#' @param p_digits Integer. Decimal places for p-value formatting.
#'   Default: \code{3L}.
#' @param bold_p \code{TRUE} (bold all non-NA p below \code{p_threshold}),
#'   \code{FALSE} (no bolding), or a logical vector (per-row control).
#'   Default: \code{TRUE}.
#' @param p_threshold Numeric. P-value threshold for bolding when
#'   \code{bold_p = TRUE}. Default: \code{0.05}.
#' @param align Integer vector of length \code{ncol(data) + 2}. Alignment per
#'   column: \code{-1} left, \code{0} centre, \code{1} right. Must cover all
#'   final columns (original + gap_ci + OR label).
#'   \code{NULL} = auto (column 1 left, all others centre).
#' @param background Character. Row background style: \code{"zebra"},
#'   \code{"bold_label"} (shade rows where \code{bold_label = TRUE}),
#'   or \code{"none"}. Default: \code{"zebra"}.
#' @param bg_col Character. Shading colour for backgrounds (scalar), or a
#'   per-row vector of length \code{nrow(data)} (overrides style).
#'   Default: \code{"#F0F0F0"}.
#' @param border Character. Border style: \code{"three_line"} or \code{"none"}.
#'   Default: \code{"three_line"}.
#' @param border_width Numeric. Border line width(s). Scalar = all three lines
#'   same width; length-3 vector = top-of-header, bottom-of-header,
#'   bottom-of-body. Default: \code{3}.
#' @param row_height \code{NULL} (auto), numeric scalar, or numeric vector
#'   (length = total gtable rows including margins). Auto sets 8 / 12 / 10 / 15
#'   mm for top / header / data / bottom respectively.
#' @param col_width \code{NULL} (auto), numeric scalar, or numeric vector
#'   (length = total gtable columns). Auto rounds each default width up so the
#'   adjustment is in \eqn{[5, 10)} mm.
#' @param save Logical. Save output to files? Default: \code{FALSE}.
#' @param dest Character. Destination file path (extension ignored; all four
#'   formats are saved). Required when \code{save = TRUE}.
#' @param save_width Numeric. Output width in cm. Default: \code{20}.
#' @param save_height Numeric or \code{NULL}. Output height in cm.
#'   \code{NULL} = \code{nrow(data) * 0.9 + 3}.
#' @param theme Character preset (\code{"default"}) or a
#'   \code{forestploter::forest_theme} object. Default: \code{"default"}.
#'
#' @return A \pkg{forestploter} plot object (gtable), returned invisibly.
#'   Display with \code{plot()} or \code{grid::grid.draw()}.
#'
#' @importFrom forestploter forest forest_theme edit_plot add_border
#' @importFrom grid gpar unit
#' @export
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   item      = c("Exposure vs. control", "Unadjusted", "Fully adjusted"),
#'   `Cases/N` = c("", "89/4521", "89/4521"),
#'   p_value   = c(NA_real_, 0.001, 0.006),
#'   check.names = FALSE
#' )
#'
#' p <- plot_forest(
#'   data       = df,
#'   est        = c(NA, 1.52, 1.43),
#'   lower      = c(NA, 1.18, 1.11),
#'   upper      = c(NA, 1.96, 1.85),
#'   ci_column  = 2L,
#'   indent     = c(0L, 1L, 1L),
#'   bold_label = c(TRUE, FALSE, FALSE),
#'   p_cols     = "p_value",
#'   xlim       = c(0.5, 3.0)
#' )
#' plot(p)
#' }
plot_forest <- function(data,
                        est,
                        lower,
                        upper,
                        ci_column   = 2L,
                        ref_line    = 1,
                        xlim        = NULL,
                        ticks_at    = NULL,
                        arrow_lab   = c("Lower risk", "Higher risk"),
                        header      = NULL,
                        indent      = NULL,
                        bold_label  = NULL,
                        ci_col      = "black",
                        ci_sizes    = 0.6,
                        ci_Theight  = 0.2,
                        ci_digits   = 2L,
                        ci_sep      = ", ",
                        p_cols      = NULL,
                        p_digits    = 3L,
                        bold_p      = TRUE,
                        p_threshold = 0.05,
                        align       = NULL,
                        background  = "zebra",
                        bg_col      = "#F0F0F0",
                        border      = "three_line",
                        border_width = 3,
                        row_height  = NULL,
                        col_width   = NULL,
                        save        = FALSE,
                        dest        = NULL,
                        save_width  = 20,
                        save_height = NULL,
                        theme       = "default") {

  # Validate inputs
  .assert_data_frame(data)
  n        <- nrow(data)
  nc_orig  <- ncol(data)
  nc_final <- nc_orig + 2L   # gap_ci + OR label always inserted

  .assert_length_n(est,   n)
  .assert_length_n(lower, n)
  .assert_length_n(upper, n)
  if (!is.null(indent))     .assert_length_n(indent,     n)
  if (!is.null(bold_label)) .assert_length_n(bold_label, n)
  if (length(ci_col) > 1L)  .assert_length_n(ci_col,     n)
  .assert_has_cols(data, p_cols)
  .assert_logical(bold_p)
  if (length(bold_p) == 1L) bold_p <- rep(bold_p, n)
  .assert_length_n(bold_p, n)

  if (ci_column < 2L || ci_column > nc_orig + 1L)
    cli::cli_abort(
      "{.arg ci_column} must be between 2 and {nc_orig + 1L} (ncol(data) + 1).",
      call = NULL
    )
  if (!is.null(header)) .assert_length_n(header, nc_final)
  if (!is.null(align))  .assert_length_n(align,  nc_final)

  # Defaults
  if (is.null(indent)) indent <- rep(0L, n)
  # bold_label default: bold parent rows (indent == 0), leave sub-rows plain
  if (is.null(bold_label)) bold_label <- indent == 0L

  # Pre-process data
  out        <- .fp_build_data(data, est, lower, upper, indent,
                               p_cols, p_digits, ci_digits, ci_sep, ci_column)
  data_r     <- out$data
  p_col_idxs <- out$p_col_idxs
  p_numeric  <- out$p_numeric

  nr <- nrow(data_r)

  if (!is.null(header)) names(data_r) <- header

  # Build base plot
  if (!is.null(xlim) && is.null(ticks_at))
    ticks_at <- seq(xlim[1L], xlim[2L], length.out = 5L)

  p <- forestploter::forest(
    data      = data_r,
    est       = list(est),
    lower     = list(lower),
    upper     = list(upper),
    ci_column = ci_column,
    ref_line  = ref_line,
    xlim      = xlim,
    ticks_at  = ticks_at,
    arrow_lab = arrow_lab,
    sizes     = ci_sizes,
    theme     = .fp_theme(theme, ci_Theight = ci_Theight)
  )

  # Post-processing
  p <- .fp_align(p, nc_final, align)
  p <- .fp_bold_label(p, bold_label)

  if (!is.null(p_cols))
    p <- .fp_bold_p(p, p_cols, p_col_idxs, p_numeric, bold_p, p_threshold, nr)

  p <- .fp_ci_colors(p, ci_col, ci_column, est, nr)
  p <- .fp_background(p, nr, nc_final, background, bold_label, bg_col)
  p <- .fp_borders(p, nr, border, border_width)
  p <- .fp_layout(p, row_height, col_width)

  # Save
  if (isTRUE(save)) {
    if (is.null(dest))
      cli::cli_abort("{.arg dest} must be provided when {.arg save = TRUE}.", call = NULL)
    h <- if (is.null(save_height)) nr * 0.9 + 3 else save_height
    .fp_save(p, dest, save_width, h)
  }

  invisible(p)
}


#' Publication-ready Table 1 (Baseline Characteristics)
#'
#' Generates a publication-quality baseline-characteristics table (Table 1)
#' using \pkg{gtsummary}, with optional SMD column, \emph{Lancet}-style
#' theming, and automatic export to four formats.
#'
#' The following behaviours are fixed (not exposed as parameters):
#' \itemize{
#'   \item Variable labels are \strong{bold} (\code{bold_labels()}).
#'   \item P-values are formatted as \code{<0.001} or to 3 decimal places.
#'   \item Significant p-values (\eqn{p < 0.05}) are \strong{bold}.
#'   \item The p-value column header is rendered as \emph{P}-value.
#'   \item The table uses a three-line (booktabs) border.
#'   \item Saving always exports \strong{word}, \strong{html}, \strong{pdf},
#'     and \strong{png}.
#' }
#'
#' @param data data.frame. Input data containing all variables.
#' @param vars Character vector. Variable names to display in the table.
#' @param strata Character scalar. Column name for the grouping/stratification
#'   variable. \code{NULL} produces an unstratified overall summary.
#' @param type Named list or \code{NULL}. Variable type overrides passed
#'   directly to \code{\link[gtsummary]{tbl_summary}}.
#'   E.g. \code{list(age = "continuous2")}.
#' @param label Named list / formula list or \code{NULL}. Label overrides.
#'   E.g. \code{list(age ~ "Age (years)", sex ~ "Sex")}.
#' @param statistic Named list or \code{NULL}. Statistic format strings.
#'   E.g. \code{list(all_continuous() ~ "{mean} ({sd})")}.
#' @param digits Named list or \code{NULL}. Decimal place overrides.
#'   E.g. \code{list(age ~ 1)}.
#' @param percent Character. Percentage base for categorical variables:
#'   \code{"column"} (default), \code{"row"}, or \code{"cell"}.
#' @param missing Character. Display of missing counts:
#'   \code{"no"} (default), \code{"ifany"}, or \code{"always"}.
#' @param add_p Logical. Add a p-value column. Default \code{TRUE};
#'   disabled with a warning if \code{strata} is \code{NULL}.
#' @param add_smd Logical. Add a standardised mean difference (SMD) column.
#'   Continuous variables use Cohen's \emph{d}; categorical variables use
#'   root-mean-square deviation (RMSD) of group proportions. SMD is shown
#'   only on label rows. Default \code{FALSE}; disabled with a warning if
#'   \code{strata} is \code{NULL}.
#' @param overall Logical. Add an Overall column when \code{strata} is set.
#'   Default \code{FALSE}.
#' @param exclude_labels Character vector or \code{NULL}. Row labels to
#'   remove from the rendered table, matched exactly against the
#'   \code{label} column in the gtsummary table body.
#'   E.g. \code{c("Unknown", "Missing")}.
#' @param theme Character. Visual theme preset. Only \code{"lancet"}
#'   (default) is currently supported. Controls alternating row shading
#'   (\code{#f8e8e7} / white), three-line borders, and 15 px font size.
#' @param label_width Integer. Label column width in pixels. Default \code{200}.
#' @param stat_width Integer. Statistics column(s) width in pixels.
#'   Default \code{140}.
#' @param pvalue_width Integer. P-value and SMD column width in pixels.
#'   Default \code{100}.
#' @param row_height Integer. Data row padding (top + bottom) in pixels.
#'   Default \code{8}.
#' @param save Logical. Export the table to files. Default \code{FALSE}.
#' @param dest Character or \code{NULL}. File path without extension.
#'   When \code{save = TRUE}, four files are written:
#'   \code{<dest>.docx}, \code{<dest>.html}, \code{<dest>.pdf},
#'   \code{<dest>.png}. Required when \code{save = TRUE}.
#' @param png_scale Numeric. Zoom factor for PNG export via \pkg{webshot2}.
#'   Higher values produce larger, higher-resolution images. Default: \code{2}.
#' @param pdf_width Numeric or \code{NULL}. PDF paper width in inches passed to
#'   \code{pagedown::chrome_print}. A larger value increases the page size so
#'   more content fits on a single page. Default: \code{NULL} (Chrome default).
#' @param pdf_height Numeric or \code{NULL}. PDF paper height in inches.
#'   Increase if the table is cut off across pages. Default: \code{NULL}.
#'
#' @return A \pkg{gt} table object, returned invisibly.
#'
#' @importFrom gtsummary tbl_summary bold_labels add_overall add_p bold_p
#'   modify_header modify_table_body modify_table_styling as_gt style_pvalue
#' @importFrom gt gtsave tab_options tab_style opt_css
#'   cell_borders cell_fill cells_column_labels cells_body cols_width px
#' @importFrom dplyr any_of
#' @export
#'
#' @examples
#' \dontrun{
#' library(gtsummary)
#' data(trial)
#'
#' # Basic stratified table
#' plot_tableone(
#'   data   = trial,
#'   vars   = c("age", "marker", "grade"),
#'   strata = "trt",
#'   save   = FALSE
#' )
#'
#' # With SMD, custom labels, exclude Unknown level
#' plot_tableone(
#'   data           = trial,
#'   vars           = c("age", "marker", "grade", "stage"),
#'   strata         = "trt",
#'   label          = list(age ~ "Age (years)", marker ~ "Marker level"),
#'   add_smd        = TRUE,
#'   exclude_labels = "Unknown",
#'   dest           = "table1",
#'   save           = TRUE
#' )
#' }
plot_tableone <- function(
    data,
    vars,
    strata         = NULL,
    type           = NULL,
    label          = NULL,
    statistic      = NULL,
    digits         = NULL,
    percent        = "column",
    missing        = "no",
    add_p          = TRUE,
    add_smd        = FALSE,
    overall        = FALSE,
    exclude_labels = NULL,
    theme          = "lancet",
    label_width    = 200,
    stat_width     = 140,
    pvalue_width   = 100,
    row_height     = 8,
    save           = FALSE,
    dest           = NULL,
    png_scale      = 2,
    pdf_width      = NULL,
    pdf_height     = NULL
) {
  # Validate inputs
  .assert_data_frame(data)
  .assert_has_cols(data, vars)
  .assert_has_cols(data, strata)
  if (!is.null(exclude_labels)) .assert_character(exclude_labels)
  if (isTRUE(save) && is.null(dest))
    cli::cli_abort("{.arg dest} must be provided when {.arg save = TRUE}.", call = NULL)

  if (isTRUE(add_p) && is.null(strata)) {
    cli::cli_warn("{.arg add_p} requires {.arg strata}; disabling.")
    add_p <- FALSE
  }
  if (isTRUE(add_smd) && is.null(strata)) {
    cli::cli_warn("{.arg add_smd} requires {.arg strata}; disabling.")
    add_smd <- FALSE
  }

  # Build tbl_summary
  tbl <- .t1_build_tbl(data, vars, strata, type, label, statistic,
                        digits, percent, missing)

  # Optional columns
  if (isTRUE(overall) && !is.null(strata))
    tbl <- gtsummary::add_overall(tbl)

  if (isTRUE(add_p))
    tbl <- .t1_add_p(tbl)

  if (isTRUE(add_smd))
    tbl <- .t1_add_smd(tbl, data, vars, strata)

  # Exclude rows
  if (!is.null(exclude_labels))
    tbl <- gtsummary::modify_table_body(
      tbl,
      ~ dplyr::filter(.x, !.data$label %in% exclude_labels)
    )

  # Convert to gt and apply theme
  gt_tbl <- gtsummary::as_gt(tbl)
  gt_tbl <- .t1_apply_theme(gt_tbl, tbl, theme, label_width, stat_width,
                              pvalue_width, row_height)

  # Save
  if (isTRUE(save))
    .t1_save(gt_tbl, dest, png_scale, pdf_width, pdf_height)

  invisible(gt_tbl)
}
