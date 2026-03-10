#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import data.table
#' @importFrom stats confint anova relevel setNames rnorm runif
#' @importFrom utils object.size
## usethis namespace: end

utils::globalVariables(c(
  # data.table .() — function alias for list(), not exported by data.table
  ".",
  # data.table column references — assoc_*
  ".ukb_event", ".ukb_trend_score", ".fg_status",
  "HR", "CI_lower", "CI_upper", "OR", "SHR",
  "model", "term", "level", "p_interaction", "i.p_interaction",
  "subgroup_level", "fgwt",
  # data.table column references — derive_*
  "eid", "effect_allele", "..required",
  "array_idx", "text", "year_month", "baseline_date", "parsed_date",
  "instance_date", "i.date",
  "icd_code", "raw_clean", "col_name", "diag_date",
  "hist_code", "behv_code",
  "death_date",
  # data.table column references — ops_*
  "pct_na"
))

NULL
