# =============================================================================
# utils_derive.R — internal helpers for derive_ series
# =============================================================================


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
    "  {.field {col}}: mean={mean_v}, median={median_v}, sd={sd_v}, \\
     Q1={q1_v}, Q3={q3_v}, NA={na_pct}% (n={na_n})"
  )
}


# Print a cli summary block for a factor column and warn if high-cardinality.
# Used by derive_covariate() and derive_cut().
.cli_summarise_factor <- function(f, col, n_rows, max_levels = 5L) {
  n_lvls <- nlevels(f)

  if (n_lvls > max_levels) {
    cli::cli_alert_warning(
      "{.field {col}}: {n_lvls} levels > max_levels ({max_levels}), \\
       consider collapsing categories."
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
