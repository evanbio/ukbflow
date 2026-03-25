# =============================================================================
# test-plot.R — Unit tests for plot_forest() and plot_tableone()
#   Focus: input validation + pure internal helpers (no graphics device needed)
# =============================================================================


# ===========================================================================
# Shared helpers
# ===========================================================================

.fake_forest_df <- function() {
  data.frame(
    item    = c("AD vs control", "Crude", "Adjusted"),
    cases_n = c("", "89/4521", "89/4521"),
    stringsAsFactors = FALSE
  )
}

.fake_t1_df <- function(n = 120, seed = 42) {
  set.seed(seed)
  data.frame(
    age = round(rnorm(n, 57, 8), 1),
    sex = factor(sample(c("Male", "Female"), n, TRUE)),
    bmi = round(rnorm(n, 27, 5), 1),
    trt = factor(sample(c("Drug A", "Drug B"), n, TRUE)),
    stringsAsFactors = FALSE
  )
}


# ===========================================================================
# plot_forest() — input validation
# ===========================================================================

test_that("plot_forest() aborts on non-data.frame input", {
  expect_error(plot_forest("not a df", 1, 0.5, 2), "data.frame")
})

test_that("plot_forest() aborts when est length != nrow(data)", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df, est = c(1, 2), lower = c(0.5, 1), upper = c(2, 3)),
    "length 3"
  )
})

test_that("plot_forest() aborts when lower length != nrow(data)", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est   = c(NA, 1.52, 1.43),
                lower = c(0.5, 1.18),          # wrong length
                upper = c(NA, 1.96, 1.85)),
    "length 3"
  )
})

test_that("plot_forest() aborts when upper length != nrow(data)", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est   = c(NA, 1.52, 1.43),
                lower = c(NA, 1.18, 1.11),
                upper = c(1.96, 1.85)),         # wrong length
    "length 3"
  )
})

test_that("plot_forest() aborts when indent length != nrow(data)", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est    = c(NA, 1.52, 1.43),
                lower  = c(NA, 1.18, 1.11),
                upper  = c(NA, 1.96, 1.85),
                indent = c(0L, 1L)),             # length 2, need 3
    "length"
  )
})

test_that("plot_forest() aborts when bold_label length != nrow(data)", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est        = c(NA, 1.52, 1.43),
                lower      = c(NA, 1.18, 1.11),
                upper      = c(NA, 1.96, 1.85),
                bold_label = c(TRUE, FALSE)),    # length 2, need 3
    "length"
  )
})

test_that("plot_forest() aborts when ci_col is wrong vector length", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est    = c(NA, 1.52, 1.43),
                lower  = c(NA, 1.18, 1.11),
                upper  = c(NA, 1.96, 1.85),
                ci_col = c("black", "red")),     # length 2, need 1 or 3
    "length"
  )
})

test_that("plot_forest() aborts when p_cols not in data", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est    = c(NA, 1.52, 1.43),
                lower  = c(NA, 1.18, 1.11),
                upper  = c(NA, 1.96, 1.85),
                p_cols = "nonexistent"),
    "nonexistent"
  )
})

test_that("plot_forest() aborts when save=TRUE and dest=NULL", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est   = c(NA, 1.52, 1.43),
                lower = c(NA, 1.18, 1.11),
                upper = c(NA, 1.96, 1.85),
                save  = TRUE, dest = NULL),
    "dest"
  )
})

test_that("plot_forest() aborts when bold_p is not logical", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est    = c(NA, 1.52, 1.43),
                lower  = c(NA, 1.18, 1.11),
                upper  = c(NA, 1.96, 1.85),
                bold_p = "yes"),
    "logical"
  )
})

test_that("plot_forest() aborts when ci_column < 2", {
  df <- .fake_forest_df()
  expect_error(
    plot_forest(df,
                est       = c(NA, 1.52, 1.43),
                lower     = c(NA, 1.18, 1.11),
                upper     = c(NA, 1.96, 1.85),
                ci_column = 1L),
    "ci_column"
  )
})

test_that("plot_forest() aborts when ci_column > ncol(data) + 1", {
  df <- .fake_forest_df()   # 2 cols
  expect_error(
    plot_forest(df,
                est       = c(NA, 1.52, 1.43),
                lower     = c(NA, 1.18, 1.11),
                upper     = c(NA, 1.96, 1.85),
                ci_column = 4L),  # max allowed = 3
    "ci_column"
  )
})

test_that("plot_forest() aborts when header length != ncol(data) + 2", {
  df <- .fake_forest_df()   # 2 orig cols → nc_final = 4
  expect_error(
    plot_forest(df,
                est    = c(NA, 1.52, 1.43),
                lower  = c(NA, 1.18, 1.11),
                upper  = c(NA, 1.96, 1.85),
                header = c("Label", "Gap")),  # need 4
    "length"
  )
})

test_that("plot_forest() aborts when align length != ncol(data) + 2", {
  df <- .fake_forest_df()   # nc_final = 4
  expect_error(
    plot_forest(df,
                est   = c(NA, 1.52, 1.43),
                lower = c(NA, 1.18, 1.11),
                upper = c(NA, 1.96, 1.85),
                align = c(-1L, 0L)),  # need 4
    "length"
  )
})


# ===========================================================================
# .fp_build_data() — pure data processing helper
# ===========================================================================

test_that(".fp_build_data() inserts gap_ci and OR (95% CI) columns", {
  df  <- data.frame(item = c("A", "B"), stringsAsFactors = FALSE)
  out <- ukbflow:::.fp_build_data(
    df, c(1.2, NA), c(0.9, NA), c(1.6, NA),
    indent = c(0L, 0L),
    p_cols = NULL, p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 2L
  )
  expect_true("gap_ci"       %in% names(out$data))
  expect_true("OR (95% CI)"  %in% names(out$data))
})

test_that(".fp_build_data() formats non-NA est as 'est (lower, upper)'", {
  df  <- data.frame(item = c("A", "B"), stringsAsFactors = FALSE)
  out <- ukbflow:::.fp_build_data(
    df, c(1.52, NA), c(1.18, NA), c(1.96, NA),
    indent = c(0L, 0L),
    p_cols = NULL, p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 2L
  )
  ci_col <- out$data[["OR (95% CI)"]]
  expect_equal(ci_col[1L], "1.52 (1.18, 1.96)")
  expect_equal(ci_col[2L], "")
})

test_that(".fp_build_data() applies indent as non-breaking spaces", {
  df  <- data.frame(item = c("Parent", "Child"), stringsAsFactors = FALSE)
  out <- ukbflow:::.fp_build_data(
    df, c(NA, 1.2), c(NA, 0.9), c(NA, 1.6),
    indent = c(0L, 1L),
    p_cols = NULL, p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 2L
  )
  expect_equal(out$data[[1L]][1L], "Parent")
  expect_true(startsWith(out$data[[1L]][2L], "\u00a0\u00a0"))
})

test_that(".fp_build_data() formats p_cols numeric to string and caches originals", {
  df  <- data.frame(item = c("A", "B"), p = c(0.031, NA_real_),
                    stringsAsFactors = FALSE)
  out <- ukbflow:::.fp_build_data(
    df, c(1, NA), c(0.5, NA), c(2, NA),
    indent = c(0L, 0L),
    p_cols = "p", p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 2L
  )
  expect_equal(out$data$p[1L], "0.031")
  expect_equal(out$data$p[2L], "")
  expect_equal(out$p_numeric$p[1L], 0.031)
})

test_that(".fp_build_data() clips p < 0.001 to '<0.001'", {
  df  <- data.frame(item = "A", p = 0.00001, stringsAsFactors = FALSE)
  out <- ukbflow:::.fp_build_data(
    df, 1.2, 0.9, 1.6,
    indent = 0L,
    p_cols = "p", p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 2L
  )
  expect_equal(out$data$p[1L], "<0.001")
})

test_that(".fp_build_data() aborts when ci_column < 2", {
  df <- data.frame(item = "A", stringsAsFactors = FALSE)
  expect_error(
    ukbflow:::.fp_build_data(
      df, 1, 0.5, 2, indent = 0L,
      p_cols = NULL, p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 1L
    ),
    ">= 2"
  )
})

test_that(".fp_build_data() maps p_col indices correctly when p_col is right of ci_column", {
  # data: item | n | p  →  ci_column = 2 → gap_ci inserted at 2
  # original p is col 3, after insert becomes col 5
  df  <- data.frame(item = "A", n = "10/100", p = 0.05, stringsAsFactors = FALSE)
  out <- ukbflow:::.fp_build_data(
    df, 1, 0.5, 2, indent = 0L,
    p_cols = "p", p_digits = 3L, ci_digits = 2L, ci_sep = ", ", ci_column = 2L
  )
  # orig p is col 3, >= ci_column (2) → idx = 3 + 2 = 5
  expect_equal(out$p_col_idxs, 5L)
})


# ===========================================================================
# .fp_theme() — theme builder
# ===========================================================================

test_that(".fp_theme() returns a list for 'default'", {
  th <- ukbflow:::.fp_theme("default")
  expect_true(is.list(th))
})

test_that(".fp_theme() result has expected ci element", {
  th <- ukbflow:::.fp_theme("default")
  # forest_theme stores CI settings under $ci
  expect_true(!is.null(th$ci) || !is.null(th$ci_col))
})

test_that(".fp_theme() warns on unknown preset and falls back to default", {
  expect_warning(
    ukbflow:::.fp_theme("unknown_theme"),
    "Unknown theme"
  )
})

test_that(".fp_theme() different ci_Theight values do not error", {
  expect_no_error(ukbflow:::.fp_theme("default", ci_Theight = 0.1))
  expect_no_error(ukbflow:::.fp_theme("default", ci_Theight = 0.5))
})


# ===========================================================================
# plot_tableone() — input validation
# ===========================================================================

test_that("plot_tableone() aborts on non-data.frame input", {
  expect_error(plot_tableone("not a df", vars = "age"), "data.frame")
})

test_that("plot_tableone() aborts when vars not in data", {
  df <- .fake_t1_df()
  expect_error(
    plot_tableone(df, vars = "nonexistent", save = FALSE),
    "missing"
  )
})

test_that("plot_tableone() aborts when strata not in data", {
  df <- .fake_t1_df()
  expect_error(
    plot_tableone(df, vars = "age", strata = "missing_col", save = FALSE),
    "missing_col"
  )
})

test_that("plot_tableone() aborts when save=TRUE and dest=NULL", {
  df <- .fake_t1_df()
  expect_error(
    plot_tableone(df, vars = "age", strata = "trt",
                  save = TRUE, dest = NULL),
    "dest"
  )
})

test_that("plot_tableone() warns and disables add_p when strata=NULL", {
  df <- .fake_t1_df()
  # cli::cli_warn() produces a warning, not a message
  expect_warning(
    plot_tableone(df, vars = "age", strata = NULL, add_p = TRUE, save = FALSE),
    "add_p"
  )
})

test_that("plot_tableone() warns and disables add_smd when strata=NULL", {
  df <- .fake_t1_df()
  # cli::cli_warn() produces a warning, not a message.
  # Disable add_p to avoid a second unrelated warning leaking out.
  expect_warning(
    plot_tableone(df, vars = "age", strata = NULL,
                  add_p = FALSE, add_smd = TRUE, save = FALSE),
    "add_smd"
  )
})

test_that("plot_tableone() aborts when exclude_labels is not character", {
  df <- .fake_t1_df()
  expect_error(
    plot_tableone(df, vars = "age", strata = "trt",
                  exclude_labels = 1L, save = FALSE),
    "character"
  )
})


# ===========================================================================
# .t1_smd_continuous() — Cohen's d helper
# ===========================================================================

test_that(".t1_smd_continuous() returns non-negative numeric for two groups", {
  set.seed(1)
  x   <- c(rnorm(50, mean = 0), rnorm(50, mean = 1))
  grp <- factor(rep(c("A", "B"), each = 50))
  val <- ukbflow:::.t1_smd_continuous(x, grp, levels(grp))
  expect_true(is.numeric(val))
  expect_gte(val, 0)
})

test_that(".t1_smd_continuous() returns ~0 when groups have same mean", {
  x   <- c(rep(5, 50), rep(5, 50))
  grp <- factor(rep(c("A", "B"), each = 50))
  val <- ukbflow:::.t1_smd_continuous(x, grp, levels(grp))
  # pooled SD = 0 → NA (division by zero guard), or 0 if identical
  expect_true(is.na(val) || val == 0)
})

test_that(".t1_smd_continuous() returns NA when a group has < 2 observations", {
  x   <- c(1, 2, 3)
  grp <- factor(c("A", "A", "B"))   # group B has only 1 obs
  val <- ukbflow:::.t1_smd_continuous(x, grp, levels(grp))
  expect_true(is.na(val))
})


# ===========================================================================
# .t1_smd_categorical() — RMSD helper
# ===========================================================================

test_that(".t1_smd_categorical() returns non-negative numeric", {
  x   <- factor(c("Yes", "No", "Yes", "Yes", "No", "No"))
  grp <- factor(c("A",   "A",  "A",   "B",   "B",  "B"))
  val <- ukbflow:::.t1_smd_categorical(x, grp, levels(grp))
  expect_true(is.numeric(val))
  expect_gte(val, 0)
})

test_that(".t1_smd_categorical() returns NA for single-category variable", {
  x   <- factor(c("Yes", "Yes", "Yes", "Yes"))
  grp <- factor(c("A",   "A",   "B",   "B"))
  val <- ukbflow:::.t1_smd_categorical(x, grp, levels(grp))
  expect_true(is.na(val))
})

test_that(".t1_smd_categorical() returns ~0 when proportions are identical", {
  x   <- factor(c("Yes", "No", "Yes", "No"))
  grp <- factor(c("A",   "A",  "B",   "B"))
  val <- ukbflow:::.t1_smd_categorical(x, grp, levels(grp))
  expect_lt(val, 1e-10)
})


# ===========================================================================
# .t1_compute_smd() — per-variable SMD dispatcher
# ===========================================================================

test_that(".t1_compute_smd() returns one row per variable", {
  set.seed(42)
  df  <- .fake_t1_df()
  res <- ukbflow:::.t1_compute_smd(df, vars = c("age", "sex"), strata = "trt")
  expect_equal(nrow(res), 2L)
  expect_equal(res$variable, c("age", "sex"))
})

test_that(".t1_compute_smd() smd_fmt is character or NA", {
  df  <- .fake_t1_df()
  res <- ukbflow:::.t1_compute_smd(df, vars = c("age", "bmi", "sex"), strata = "trt")
  expect_true(is.character(res$smd_fmt))
})

test_that(".t1_compute_smd() smd_fmt is formatted to 3 decimal places", {
  df  <- .fake_t1_df()
  res <- ukbflow:::.t1_compute_smd(df, vars = "age", strata = "trt")
  fmt <- res$smd_fmt[!is.na(res$smd_fmt)]
  if (length(fmt) > 0L) {
    # e.g. "0.123" — decimal part is exactly 3 digits
    expect_true(all(grepl("^\\d+\\.\\d{3}$", fmt)))
  }
})
