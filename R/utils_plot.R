# =============================================================================
# utils_plot.R — internal helpers for plot_forest() and plot_tableone()
# =============================================================================


# -----------------------------------------------------------------------------
# Theme
# -----------------------------------------------------------------------------

# Build forest theme. theme must be a recognised preset string.
# Invalid values silently fall back to "default".
.fp_theme <- function(theme, ci_Theight = 0.2) {
  presets <- list(
    default = list(
      base_size    = 12,
      base_family  = "sans",
      ci_pch       = 15,
      ci_lty       = 1,
      ci_lwd       = 3,
      ci_col       = "black",
      ci_alpha     = 1,
      ci_fill      = "black",
      ci_Theight   = ci_Theight,
      refline_gp   = grid::gpar(lwd = 2, lty = "dashed", col = "grey20"),
      xaxis_gp     = grid::gpar(fontsize = 12, fontfamily = "sans"),
      arrow_type   = "open",
      arrow_length = 0.1,
      arrow_gp     = grid::gpar(fontsize = 12, fontfamily = "sans", lwd = 2),
      xlab_adjust  = "center",
      xlab_gp      = grid::gpar(fontsize = 10, fontfamily = "sans", fontface = "plain")
    )
  )

  if (!is.character(theme) || !theme %in% names(presets)) {
    cli::cli_warn(
      c("Unknown theme {.val {theme}}, falling back to {.val {'default'}}.",
        "i" = "Available: {.val {names(presets)}}")
    )
    theme <- "default"
  }

  do.call(forestploter::forest_theme, presets[[theme]])
}


# -----------------------------------------------------------------------------
# Data pre-processing
# -----------------------------------------------------------------------------

# Apply indent, format p_cols, insert gap_ci + OR label at ci_column.
# Returns list(data = final_df, p_col_idxs = integer vector of p col positions
#              in final_df).
.fp_build_data <- function(data, est, lower, upper, indent,
                           p_cols, p_digits, ci_digits, ci_sep, ci_column) {
  n         <- nrow(data)
  ncol_orig <- ncol(data)

  # 1. Indent: prepend non-breaking spaces to item (col 1).
  # Reason: regular spaces are often collapsed by grid text rendering;
  # \u00a0 (non-breaking space) preserves visual indentation reliably.
  data[[1L]] <- paste0(strrep("\u00a0\u00a0", as.integer(indent)), data[[1L]])

  # 2. Format p_cols: numeric → character, cache originals for bold logic
  p_numeric <- list()
  if (!is.null(p_cols)) {
    thresh_str <- formatC(10^(-p_digits), digits = p_digits, format = "f")
    for (col in p_cols) {
      pv             <- as.numeric(data[[col]])
      p_numeric[[col]] <- pv
      data[[col]]    <- ifelse(
        is.na(pv), "",
        ifelse(pv < 10^(-p_digits),
               paste0("<", thresh_str),
               formatC(pv, digits = p_digits, format = "f"))
      )
    }
  }

  # 3. Generate OR (95% CI) label from est/lower/upper
  fmt <- function(x) formatC(x, digits = ci_digits, format = "f")
  ci_label <- ifelse(
    is.na(est), "",
    paste0(fmt(est), " (", fmt(lower), ci_sep, fmt(upper), ")")
  )

  # 4. Build final table: left cols | gap_ci | OR (95% CI) | right cols
  if (ci_column <= 1L)
    cli::cli_abort("{.arg ci_column} must be >= 2.")
  if (ci_column > ncol_orig + 1L)
    cli::cli_abort(
      "{.arg ci_column} ({ci_column}) exceeds ncol(data)+1 ({ncol_orig + 1L})."
    )

  gap_df <- data.frame(gap_ci        = strrep(" ", 20L), stringsAsFactors = FALSE)
  lab_df <- data.frame(`OR (95% CI)` = ci_label,         stringsAsFactors = FALSE,
                       check.names   = FALSE)

  left  <- data[, seq_len(ci_column - 1L), drop = FALSE]
  right <- if (ci_column <= ncol_orig)
    data[, seq(ci_column, ncol_orig), drop = FALSE]
  else
    NULL

  data_r <- if (is.null(right)) cbind(left, gap_df, lab_df)
            else                 cbind(left, gap_df, lab_df, right)

  # 5. Map original p_cols indices to final positions (+2 if >= ci_column)
  p_col_idxs <- NULL
  if (!is.null(p_cols)) {
    orig_idxs  <- match(p_cols, names(data))
    p_col_idxs <- ifelse(orig_idxs >= ci_column, orig_idxs + 2L, orig_idxs)
  }

  list(data = data_r, p_col_idxs = p_col_idxs, p_numeric = p_numeric)
}


# -----------------------------------------------------------------------------
# Alignment
# -----------------------------------------------------------------------------

# align: integer vector, length = ncol(final data).
#   -1 = left, 0 = center, 1 = right.
# NULL = auto: col 1 left, everything else center.
.fp_align <- function(p, n_cols, align) {
  if (is.null(align)) align <- c(-1L, rep(0L, n_cols - 1L))

  hjust_map <- c("-1" = 0, "0" = 0.5, "1" = 1)
  x_map     <- c("-1" = 0, "0" = 0.5, "1" = 1)

  for (j in seq_len(n_cols)) {
    key  <- as.character(align[j])
    hj   <- grid::unit(hjust_map[[key]], "npc")
    xpos <- grid::unit(x_map[[key]], "npc")
    for (part in c("body", "header")) {
      p <- forestploter::edit_plot(p, col = j, which = "text", part = part,
                                   hjust = hj, x = xpos)
    }
  }
  p
}


# -----------------------------------------------------------------------------
# Bold label (item column)
# -----------------------------------------------------------------------------

# bold_label: logical vector length n_rows. TRUE rows → bold item column.
.fp_bold_label <- function(p, bold_label) {
  rows <- which(bold_label)
  if (length(rows) == 0L) return(p)
  forestploter::edit_plot(p, row = rows, col = 1L, which = "text",
                          gp = grid::gpar(fontface = "bold"))
}


# -----------------------------------------------------------------------------
# Bold p values
# -----------------------------------------------------------------------------

# p_cols: column names in original data.
# p_col_idxs: their indices in final data_r.
# p_numeric: list of original numeric p vectors (named by p_cols).
# bold_p: TRUE / FALSE / logical vector (length n_rows).
# p_threshold: scalar; only used when bold_p is TRUE.
.fp_bold_p <- function(p, p_cols, p_col_idxs, p_numeric,
                       bold_p, p_threshold, n_rows) {
  if (isFALSE(bold_p)) return(p)

  for (j in seq_along(p_cols)) {
    pv      <- p_numeric[[p_cols[j]]]
    col_idx <- p_col_idxs[j]

    bold_rows <- if (isTRUE(bold_p)) {
      which(!is.na(pv) & pv < p_threshold)
    } else {
      which(as.logical(bold_p) & !is.na(pv))
    }

    for (r in bold_rows) {
      p <- forestploter::edit_plot(p, row = r, col = col_idx, which = "text",
                                   gp = grid::gpar(fontface = "bold"))
    }
  }
  p
}


# -----------------------------------------------------------------------------
# CI colours
# -----------------------------------------------------------------------------

# ci_col: scalar or vector (length n_rows). Rows with NA est or NA ci_col skipped.
.fp_ci_colors <- function(p, ci_col, ci_column, est, n_rows) {
  if (length(ci_col) == 1L) ci_col <- rep(ci_col, n_rows)
  for (i in seq_len(n_rows)) {
    if (!is.na(est[i]) && !is.na(ci_col[i])) {
      p <- forestploter::edit_plot(p, row = i, col = ci_column, which = "ci",
                                   gp = grid::gpar(fill = ci_col[i],
                                                   col  = ci_col[i]))
    }
  }
  p
}


# -----------------------------------------------------------------------------
# Background
# -----------------------------------------------------------------------------

# background: "zebra" | "bold_label" | "none"
# bg_col: scalar (used for shaded rows) or vector (length n_rows, overrides all).
.fp_background <- function(p, n_rows, n_cols, background, bold_label, bg_col) {
  if (background == "none") return(p)

  all_cols <- seq_len(n_cols)

  # Determine per-row fill colour
  if (length(bg_col) == n_rows) {
    # User supplied per-row vector: direct override
    fill <- bg_col
  } else if (background == "zebra") {
    fill <- ifelse(seq_len(n_rows) %% 2L == 0L, bg_col, "white")
  } else if (background == "bold_label") {
    fill <- ifelse(bold_label, bg_col, "white")
  } else {
    cli::cli_abort(
      c("Unknown {.arg background} value {.val {background}}.",
        "i" = "Must be one of: {.val {c('zebra', 'bold_label', 'none')}}")
    )
  }

  for (i in seq_len(n_rows)) {
    p <- forestploter::edit_plot(p, row = i, col = all_cols,
                                 which = "background",
                                 gp    = grid::gpar(fill = fill[i], col = NA))
  }
  p
}


# -----------------------------------------------------------------------------
# Borders
# -----------------------------------------------------------------------------

# border: "three_line" | "none"
# border_width: scalar (all lines same) or length-3 vector
#   (top-of-header, bottom-of-header, bottom-of-body).
.fp_borders <- function(p, n_rows, border, border_width) {
  if (border == "none") return(p)

  if (length(border_width) == 1L) border_width <- rep(border_width, 3L)

  p <- forestploter::add_border(p, part = "header", row = 1L, where = "top",
                                gp = grid::gpar(lwd = border_width[1L]))
  p <- forestploter::add_border(p, part = "header", row = 1L, where = "bottom",
                                gp = grid::gpar(lwd = border_width[2L]))
  p <- forestploter::add_border(p, part = "body",   row = n_rows, where = "bottom",
                                gp = grid::gpar(lwd = border_width[3L]))
  p
}


# -----------------------------------------------------------------------------
# Layout (heights & widths)
# -----------------------------------------------------------------------------

# row_height / col_width: NULL (auto) | scalar | vector.
#
# Auto height: [1]=8mm top, [2]=12mm header, [3..n-1]=10mm rows, [n]=15mm bottom
# Auto width:  each col → ceiling((w+5)/5)*5  (adjustment in [5,10) mm)
.fp_layout <- function(p, row_height, col_width) {
  # --- heights ---
  nh      <- length(p$heights)
  default_h <- round(grid::convertHeight(p$heights, "mm", valueOnly = TRUE), 1)
  cli::cli_inform("Heights default (mm): {paste(default_h, collapse = ', ')}")

  if (!is.null(row_height)) {
    # scalar or vector supplied by user
    if (length(row_height) == 1L) row_height <- rep(row_height, nh)
    for (i in seq_len(nh))
      p$heights[i] <- grid::unit(row_height[i], "mm")
  } else {
    # auto
    p$heights[1L] <- grid::unit(8,  "mm")
    p$heights[2L] <- grid::unit(12, "mm")
    if (nh > 3L)
      for (i in seq(3L, nh - 1L))
        p$heights[i] <- grid::unit(10, "mm")
    p$heights[nh] <- grid::unit(15, "mm")
  }

  adj_h <- round(grid::convertHeight(p$heights, "mm", valueOnly = TRUE), 1)
  cli::cli_inform("Heights adjusted (mm): {paste(adj_h, collapse = ', ')}")

  # --- widths ---
  nw        <- length(p$widths)
  default_w <- round(grid::convertWidth(p$widths, "mm", valueOnly = TRUE), 1)
  cli::cli_inform("Widths default (mm): {paste(default_w, collapse = ', ')}")

  if (!is.null(col_width)) {
    if (length(col_width) == 1L) col_width <- rep(col_width, nw)
    for (i in seq_len(nw))
      p$widths[i] <- grid::unit(col_width[i], "mm")
  } else {
    # auto: round up so adjustment is in [5, 10) mm
    for (i in seq_len(nw)) {
      w   <- default_w[i]
      new <- ceiling((w + 5) / 5) * 5
      p$widths[i] <- grid::unit(new, "mm")
    }
  }

  adj_w <- round(grid::convertWidth(p$widths, "mm", valueOnly = TRUE), 1)
  cli::cli_inform("Widths adjusted (mm): {paste(adj_w, collapse = ', ')}")

  p
}


# =============================================================================
# Table 1 helpers (.t1_*)
# =============================================================================


# Build a gtsummary tbl_summary with bold labels.
# All args NULL-safe: only passed to tbl_summary when non-NULL.
.t1_build_tbl <- function(data, vars, strata, type, label, statistic,
                           digits, percent, missing) {
  sub  <- if (is.null(strata)) data[, vars, drop = FALSE]
          else                  data[, c(vars, strata), drop = FALSE]

  args <- list(data = sub, by = strata, percent = percent, missing = missing)
  if (!is.null(type))      args$type      <- type
  if (!is.null(label))     args$label     <- label
  if (!is.null(statistic)) args$statistic <- statistic
  if (!is.null(digits))    args$digits    <- digits

  tbl <- do.call(gtsummary::tbl_summary, args)
  gtsummary::bold_labels(tbl)
}


# Add p-value column: 3 dp / <0.001 cutoff, italic header, bold sig p.
.t1_add_p <- function(tbl) {
  tbl <- gtsummary::add_p(
    tbl,
    pvalue_fun = function(x) gtsummary::style_pvalue(x, digits = 3)
  )
  tbl <- gtsummary::bold_p(tbl)
  # Italic *P* via gtsummary markdown syntax
  tbl <- gtsummary::modify_header(tbl, p.value ~ "***P*-value**")
  tbl
}


# Add SMD column to tbl_summary.
# Continuous: Cohen's d. Categorical: RMSD. Shown on label rows only.
.t1_add_smd <- function(tbl, data, vars, strata) {
  smd_vals <- .t1_compute_smd(data, vars, strata)
  smd_map  <- stats::setNames(smd_vals$smd_fmt, smd_vals$variable)

  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$smd <- ifelse(
      tb$row_type == "label",
      smd_map[tb$variable],
      NA_character_
    )
    tb
  })

  # Register column so as_gt() renders it
  tbl <- gtsummary::modify_table_styling(
    tbl,
    columns = "smd",
    label   = "**SMD**",
    align   = "center"
  )
  tbl
}


# Compute SMD for each variable.
# 2 groups  → direct formula.
# 3+ groups → mean of all pairwise values.
.t1_compute_smd <- function(data, vars, strata) {
  grp  <- factor(data[[strata]])
  levs <- levels(grp)

  rows <- lapply(vars, function(v) {
    x <- data[[v]]
    val <- tryCatch(
      if (is.numeric(x)) .t1_smd_continuous(x, grp, levs)
      else               .t1_smd_categorical(x, grp, levs),
      error = function(e) NA_real_
    )
    data.frame(
      variable = v,
      smd_fmt  = if (!is.na(val)) formatC(val, digits = 3, format = "f")
                 else             NA_character_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}


# Cohen's d for continuous variable (pooled-SD formula).
.t1_smd_continuous <- function(x, grp, levs) {
  pairs <- utils::combn(levs, 2L, simplify = FALSE)
  smds  <- vapply(pairs, function(p) {
    x1 <- x[grp == p[1L] & !is.na(x)]
    x2 <- x[grp == p[2L] & !is.na(x)]
    # Require at least 2 observations per group; var() on n<2 returns NA + warning
    if (length(x1) < 2L || length(x2) < 2L) return(NA_real_)
    ps <- sqrt((stats::var(x1) + stats::var(x2)) / 2)
    if (ps == 0) return(NA_real_)
    abs(mean(x1) - mean(x2)) / ps
  }, numeric(1L))
  mean(smds, na.rm = TRUE)
}


# RMSD of group proportions for categorical variable.
.t1_smd_categorical <- function(x, grp, levs) {
  cats  <- levels(factor(x))
  if (length(cats) < 2L) return(NA_real_)
  pairs <- utils::combn(levs, 2L, simplify = FALSE)
  smds  <- vapply(pairs, function(p) {
    p1 <- prop.table(table(factor(x[grp == p[1L]], levels = cats)))
    p2 <- prop.table(table(factor(x[grp == p[2L]], levels = cats)))
    sqrt(mean((as.numeric(p1) - as.numeric(p2))^2))
  }, numeric(1L))
  mean(smds, na.rm = TRUE)
}


# Apply visual theme (currently only "lancet") to a gt table.
# Block-based row shading (by variable group), header shading, three-line
# borders, font size, and column widths.
# tbl: original gtsummary object (needed to read row_type for block IDs).
.t1_apply_theme <- function(gt_tbl, tbl, theme, label_width, stat_width,
                              pvalue_width, row_height) {
  valid_themes <- "lancet"
  if (!theme %in% valid_themes) {
    cli::cli_warn("Unknown theme {.val {theme}}; using {.val {'lancet'}}.")
    theme <- "lancet"
  }

  # --- block-based row shading -----------------------------------------------
  # Reason: each variable occupies 1-N rows (label + levels); coloring by
  # block (not row index) keeps a variable's rows visually grouped.
  tbl_data  <- tbl$table_body
  label_idx <- which(tbl_data$row_type == "label")

  if (length(label_idx) > 0L) {
    block_id    <- rep(seq_along(label_idx),
                       times = diff(c(label_idx, nrow(tbl_data) + 1L)))
    fill_colors <- ifelse(block_id %% 2L == 1L, "#f8e8e7", "#FFFFFF")

    pink_rows  <- which(fill_colors == "#f8e8e7")
    white_rows <- which(fill_colors == "#FFFFFF")

    if (length(pink_rows) > 0L)
      gt_tbl <- gt::tab_style(gt_tbl,
        style     = gt::cell_fill(color = "#f8e8e7"),
        locations = gt::cells_body(rows = pink_rows))

    if (length(white_rows) > 0L)
      gt_tbl <- gt::tab_style(gt_tbl,
        style     = gt::cell_fill(color = "#FFFFFF"),
        locations = gt::cells_body(rows = white_rows))
  }

  # --- header row: same #f8e8e7 background -----------------------------------
  gt_tbl <- gt::tab_style(gt_tbl,
    style     = gt::cell_fill(color = "#f8e8e7"),
    locations = gt::cells_column_labels())

  # --- three-line borders (via tab_style, higher specificity than tab_options)
  n_body <- nrow(tbl_data)
  # Line 1: top of header
  gt_tbl <- gt::tab_style(gt_tbl,
    style     = gt::cell_borders(sides = "top",    color = "black", weight = gt::px(3)),
    locations = gt::cells_column_labels())
  # Line 2: bottom of header
  gt_tbl <- gt::tab_style(gt_tbl,
    style     = gt::cell_borders(sides = "bottom", color = "black", weight = gt::px(2)),
    locations = gt::cells_column_labels())
  # Line 3: bottom of last body row
  gt_tbl <- gt::tab_style(gt_tbl,
    style     = gt::cell_borders(sides = "bottom", color = "black", weight = gt::px(3)),
    locations = gt::cells_body(rows = n_body))

  # Remove all other horizontal rules
  gt_tbl <- gt::tab_options(gt_tbl,
    table_body.hlines.style   = "none",
    table.border.bottom.style = "none",
    table.border.top.style    = "none",
    table.font.size           = gt::px(15),
    data_row.padding          = gt::px(row_height),
    column_labels.padding     = gt::px(12))

  # --- column widths ---------------------------------------------------------
  # Reason: gt::cols_width() evaluates formula RHS via NSE and may not resolve
  # local function variables from within a package. rlang::inject() + !!
  # substitutes the actual integer values before gt sees the call.
  gt_tbl <- rlang::inject(
    gt::cols_width(
      gt_tbl,
      dplyr::any_of("label")             ~ gt::px(!!label_width),
      dplyr::any_of(c("p.value", "smd")) ~ gt::px(!!pvalue_width),
      gt::everything()                   ~ gt::px(!!stat_width)
    )
  )

  gt_tbl
}


# Save table to word / html / pdf / png.
#
# DOCX/HTML : gt::gtsave() directly — preserves gt styling.
# PDF       : gt → temp HTML → pagedown::chrome_print(printBackground=TRUE).
# PNG       : gt → temp HTML → webshot2::webshot(selector=".gt_table").
#
# Reason: browsers strip backgrounds by default when printing/rendering.
# CSS `print-color-adjust: exact` + printBackground=TRUE forces preservation.
.t1_save <- function(gt_tbl, dest) {
  base <- tools::file_path_sans_ext(dest)

  # Inject CSS for background/border preservation in PDF & PNG rendering.
  # Applied to a separate copy so the returned gt object stays clean.
  gt_print <- gt_tbl |>
    gt::opt_css(css = "
      @media print {
        body, td, th {
          -webkit-print-color-adjust: exact !important;
          print-color-adjust: exact !important;
          color-adjust: exact !important;
        }
        table, td, th { border-color: inherit !important; }
      }
      @media screen {
        body, td, th {
          -webkit-print-color-adjust: exact !important;
          print-color-adjust: exact !important;
        }
      }
    ")

  # DOCX ----------------------------------------------------------------------
  tryCatch({
    out <- paste0(base, ".docx")
    gt::gtsave(gt_tbl, filename = out)
    cli::cli_alert_success("Saved: {.path {out}}")
  }, error = function(e) {
    cli::cli_alert_danger("Failed to save .docx: {conditionMessage(e)}")
  })

  # HTML ----------------------------------------------------------------------
  tryCatch({
    out <- paste0(base, ".html")
    gt::gtsave(gt_tbl, filename = out)
    cli::cli_alert_success("Saved: {.path {out}}")
  }, error = function(e) {
    cli::cli_alert_danger("Failed to save .html: {conditionMessage(e)}")
  })

  # PDF + PNG share the same HTML source — write once, reuse twice.
  tmp_html <- tempfile(fileext = ".html")
  on.exit(unlink(tmp_html), add = TRUE)
  html_ready <- tryCatch({
    gt::gtsave(gt_print, filename = tmp_html)
    TRUE
  }, error = function(e) {
    cli::cli_alert_danger("Failed to build temp HTML for PDF/PNG: {conditionMessage(e)}")
    FALSE
  })

  # PDF (HTML → pagedown::chrome_print) ---------------------------------------
  if (html_ready) tryCatch({
    if (!requireNamespace("pagedown", quietly = TRUE))
      cli::cli_abort("Package {.pkg pagedown} is required for PDF export.")
    out <- paste0(base, ".pdf")
    pagedown::chrome_print(
      input      = tmp_html,
      output     = out,
      format     = "pdf",
      options    = list(
        printBackground     = TRUE,   # preserve backgrounds
        preferCSSPageSize   = TRUE,
        displayHeaderFooter = FALSE
      ),
      extra_args = c("--no-sandbox", "--disable-dev-shm-usage"),
      verbose    = 0
    )
    cli::cli_alert_success("Saved: {.path {out}}")
  }, error = function(e) {
    cli::cli_alert_danger("Failed to save .pdf: {conditionMessage(e)}")
  })

  # PNG (HTML → webshot2::webshot) --------------------------------------------
  if (html_ready) tryCatch({
    if (!requireNamespace("webshot2", quietly = TRUE))
      cli::cli_abort("Package {.pkg webshot2} is required for PNG export.")
    out <- paste0(base, ".png")
    webshot2::webshot(
      url      = tmp_html,
      file     = out,
      zoom     = 2,
      selector = ".gt_table",
      expand   = 10
    )
    cli::cli_alert_success("Saved: {.path {out}}")
  }, error = function(e) {
    cli::cli_alert_danger("Failed to save .png: {conditionMessage(e)}")
  })

  invisible(NULL)
}


# =============================================================================
# Forest plot save helper (.fp_save) — below
# =============================================================================


# dest: file path (with or without extension; extension stripped and ignored).
# Saves png / pdf / jpg / tiff at 300 dpi, white background, always overwrite.
.fp_save <- function(p, dest, save_width, save_height) {
  base  <- tools::file_path_sans_ext(dest)
  exts  <- c("png", "pdf", "jpg", "tiff")
  w_in  <- save_width  / 2.54
  h_in  <- save_height / 2.54

  for (ext in exts) {
    out <- paste0(base, ".", ext)
    tryCatch({
      if (ext == "pdf") {
        grDevices::pdf(out, width = w_in, height = h_in, bg = "white")
      } else if (ext == "png") {
        grDevices::png(out, width = save_width, height = save_height,
                       units = "cm", res = 300, bg = "white")
      } else if (ext == "jpg") {
        grDevices::jpeg(out, width = save_width, height = save_height,
                        units = "cm", res = 300, bg = "white", quality = 95)
      } else if (ext == "tiff") {
        grDevices::tiff(out, width = save_width, height = save_height,
                        units = "cm", res = 300, bg = "white")
      }
      grid::grid.newpage()
      grid::grid.draw(p)
      grDevices::dev.off()
      cli::cli_alert_success("Saved: {.path {out}}")
    }, error = function(e) {
      try(grDevices::dev.off(), silent = TRUE)
      cli::cli_alert_danger("Failed to save {.path {out}}: {conditionMessage(e)}")
    })
  }
  invisible(NULL)
}
