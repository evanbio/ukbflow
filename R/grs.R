# =============================================================================
# grs.R - Genetic Risk Score utilities for ukbflow
# =============================================================================


#' Check and export a GRS weights file
#'
#' Reads a SNP weights file, validates its content, and writes a
#' plink2-compatible space-delimited output ready for upload to UKB RAP.
#'
#' The input file must contain at least the three columns below (additional
#' columns are ignored):
#' \describe{
#'   \item{\code{snp}}{SNP identifier, expected in \code{rs} + digits format.}
#'   \item{\code{effect_allele}}{Effect allele; must be one of A / T / C / G.}
#'   \item{\code{beta}}{Effect size (log-OR or beta coefficient); must be numeric.}
#' }
#'
#' Checks performed:
#' \itemize{
#'   \item Required columns present.
#'   \item No \code{NA} values in the three required columns.
#'   \item No duplicate \code{snp} identifiers.
#'   \item \code{snp} matches \code{rs[0-9]+} pattern (warning if not).
#'   \item \code{effect_allele} contains only A / T / C / G (warning if not).
#'   \item \code{beta} is numeric (error if not).
#' }
#'
#' @param file Character scalar. Path to the input weights file.
#'   Read via \code{data.table::fread} (format auto-detected; handles
#'   CSV, TSV, space-delimited, etc.).
#' @param dest Character scalar. Output path for the validated,
#'   space-delimited weights file. Default: \code{"weights.txt"}.
#'
#' @return A \code{data.table} with columns \code{snp}, \code{effect_allele},
#'   and \code{beta}, returned invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Local
#' w <- grs_check("weights.csv", dest = "weights_clean.txt")
#'
#' # On RAP (JupyterLab) - files accessed via /mnt/project/
#' w <- grs_check(
#'   file = "/mnt/project/weights/weights.csv",
#'   dest = "/mnt/project/weights/weights_clean.txt"
#' )
#' }
grs_check <- function(file, dest = "weights.txt") {

  # ---------------------------------------------------------------------------
  # 1. Read
  # ---------------------------------------------------------------------------
  if (!file.exists(file))
    cli::cli_abort("File not found: {.path {file}}", call = NULL)

  dt <- data.table::fread(file, data.table = TRUE)
  if (nrow(dt) == 0L)
    cli::cli_abort("File contains no data rows: {.path {file}}", call = NULL)
  cli::cli_inform("Read {.path {file}}: {nrow(dt)} rows, {ncol(dt)} columns.")
  # Normalise effect_allele to uppercase to tolerate lowercase input
  if ("effect_allele" %in% names(dt))
    dt[, effect_allele := toupper(effect_allele)]

  # ---------------------------------------------------------------------------
  # 2. Required columns
  # ---------------------------------------------------------------------------
  required    <- c("snp", "effect_allele", "beta")
  missing_cols <- setdiff(required, names(dt))
  if (length(missing_cols) > 0L)
    cli::cli_abort(
      c("Required column(s) not found: {.val {missing_cols}}",
        "i" = "File must contain: {.val {required}}")
    )

  w <- dt[, ..required]

  # ---------------------------------------------------------------------------
  # 3. NA check
  # ---------------------------------------------------------------------------
  n_na <- sum(!stats::complete.cases(w))
  if (n_na > 0L)
    cli::cli_abort("{n_na} row(s) have NA in required columns - remove before proceeding.", call = NULL)
  cli::cli_alert_success("No NA values.")

  # ---------------------------------------------------------------------------
  # 4. Duplicate SNPs
  # ---------------------------------------------------------------------------
  n_dup <- sum(duplicated(w$snp))
  if (n_dup > 0L)
    cli::cli_abort("{n_dup} duplicate SNP ID(s) found - each SNP must appear once.", call = NULL)
  cli::cli_alert_success("No duplicate SNPs.")

  # ---------------------------------------------------------------------------
  # 5. SNP format: rs + digits
  # ---------------------------------------------------------------------------
  n_bad_rs <- sum(!grepl("^rs[0-9]+$", w$snp))
  if (n_bad_rs > 0L)
    cli::cli_warn(
      c("{n_bad_rs} SNP ID(s) do not match {.code rs[0-9]+} format.",
        "i" = "plink2 accepts non-rsID formats but verify alignment with target genotype data.")
    )
  else
    cli::cli_alert_success("All SNP IDs match rs[0-9]+ format.")

  # ---------------------------------------------------------------------------
  # 6. Effect allele: A / T / C / G only
  # ---------------------------------------------------------------------------
  n_bad_al <- sum(!w$effect_allele %in% c("A", "T", "C", "G"))
  if (n_bad_al > 0L)
    cli::cli_warn(
      c("{n_bad_al} effect allele(s) outside A/T/C/G.",
        "i" = "Indels or multi-character alleles may not score correctly in plink2.")
    )
  else
    cli::cli_alert_success("All effect alleles are A/T/C/G.")

  # ---------------------------------------------------------------------------
  # 7. Beta: numeric
  # ---------------------------------------------------------------------------
  if (!is.numeric(w$beta))
    cli::cli_abort("{.field beta} must be numeric (found {.cls {class(w$beta)}}).", call = NULL)

  # ---------------------------------------------------------------------------
  # 8. Beta summary
  # ---------------------------------------------------------------------------
  n_pos  <- sum(w$beta >  0)
  n_neg  <- sum(w$beta <  0)
  n_zero <- sum(w$beta == 0)

  cli::cli_inform(c(
    "Beta summary:",
    " " = "Range     : {round(min(w$beta), 4)} to {round(max(w$beta), 4)}",
    " " = "Mean |beta|: {round(mean(abs(w$beta)), 4)}",
    " " = "Positive  : {n_pos} ({round(100 * n_pos / nrow(w), 1)}%)",
    " " = "Negative  : {n_neg} ({round(100 * n_neg / nrow(w), 1)}%)",
    " " = "Zero      : {n_zero}"
  ))

  # ---------------------------------------------------------------------------
  # 9. Final summary
  # ---------------------------------------------------------------------------
  cli::cli_alert_success(
    "Weights file passed checks: {.strong {nrow(w)} SNPs} ready for UKB RAP."
  )

  # ---------------------------------------------------------------------------
  # 10. Write plink2-compatible output (space-delimited, no quotes)
  # ---------------------------------------------------------------------------
  data.table::fwrite(w, dest, sep = " ", quote = FALSE)
  cli::cli_alert_success("Saved: {.path {dest}}")

  invisible(w)
}


#' Convert UKB imputed BGEN files to PGEN on RAP
#'
#' Submits one Swiss Army Knife job per chromosome to the DNAnexus Research
#' Analysis Platform, each converting a UKB imputed BGEN file to PGEN format
#' with a MAF > 0.01 filter applied via plink2. Jobs run in parallel across
#' chromosomes.
#'
#' The function auto-generates the plink2 driver script, uploads it once to
#' the RAP project root (\code{/}) on RAP, then loops over \code{chr} submitting
#' one job per chromosome. A 500 ms pause between submissions prevents API
#' rate-limiting.
#'
#' \strong{Output path is critical.} The driver script writes plink2 output to
#' \code{/home/dnanexus/out/out/} - the fixed path that Swiss Army Knife
#' auto-uploads to \code{dest} on completion. Output files per chromosome:
#' \code{chr\{N\}_maf001.pgen/.pvar/.psam/.log}.
#'
#' \strong{Instance types:}
#' \describe{
#'   \item{\code{"standard"}}{\code{mem2_ssd1_v2_x4}: 4 cores, 12 GB RAM.
#'     Suitable for smaller chromosomes (roughly chr 17–22).}
#'   \item{\code{"large"}}{\code{mem2_ssd2_v2_x8}: 8 cores, 28 GB RAM,
#'     640 GB SSD. Required for large chromosomes (roughly chr 1–16) where
#'     standard storage is insufficient.}
#' }
#'
#' @param chr Integer vector. Chromosomes to process. Default: \code{1:22}.
#' @param dest Character scalar. RAP destination path for output PGEN files.
#'   Default: \code{"/pgen/"}.
#' @param maf Numeric scalar. Minor allele frequency filter passed to plink2
#'   \code{--maf}. Variants with MAF below this threshold are excluded.
#'   Default: \code{0.01}. Must be in \code{(0, 0.5)}.
#' @param instance Character scalar. Instance type preset: \code{"standard"}
#'   or \code{"large"}. See Details. Default: \code{"standard"}.
#' @param priority Character scalar. Job priority: \code{"low"} or
#'   \code{"high"}. Default: \code{"low"}.
#'
#' @return A character vector of job IDs (one per chromosome), returned
#'   invisibly. Failed submissions are \code{NA}. Use \code{\link{job_ls}},
#'   \code{\link{job_status}}, or \code{\link{job_wait}} to monitor progress.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Test with chr22 first (smallest chromosome)
#' ids <- grs_bgen2pgen(chr = 22, priority = "high")
#'
#' # Small chromosomes - standard instance
#' ids_small <- grs_bgen2pgen(chr = 15:22)
#'
#' # Large chromosomes - upgrade instance to handle storage
#' ids_large <- grs_bgen2pgen(chr = 1:16, instance = "large")
#'
#' # Monitor
#' job_ls()
#' }
grs_bgen2pgen <- function(chr      = 1:22,
                           dest     = "/pgen/",
                           maf      = 0.01,
                           instance = "standard",
                           priority = "low") {

  # ---------------------------------------------------------------------------
  # 1. Validate
  # ---------------------------------------------------------------------------
  instance <- match.arg(instance, c("standard", "large"))
  priority <- match.arg(priority, c("low", "high"))

  chr <- as.integer(chr)
  if (any(is.na(chr)) || any(chr < 1L) || any(chr > 22L))
    cli::cli_abort("{.arg chr} must be integers between 1 and 22.", call = NULL)

  if (!is.numeric(maf) || length(maf) != 1L || maf <= 0 || maf >= 0.5)
    cli::cli_abort("{.arg maf} must be a single numeric value in (0, 0.5).", call = NULL)

  if (instance == "standard" && any(chr %in% 1:16))
    cli::cli_warn(c(
      "chr {.val {intersect(chr, 1:16)}} may exceed storage on {.val {'mem2_ssd1_v2_x4'}}.",
      "i" = "Consider {.code instance = \"large\"} (mem2_ssd2_v2_x8, 640 GB SSD) for these chromosomes."
    ))

  # ---------------------------------------------------------------------------
  # 2. Instance config (mirrors scripts 06 and 13)
  # ---------------------------------------------------------------------------
  if (instance == "standard") {
    instance_type <- "mem2_ssd1_v2_x4"
    n_threads     <- 4L
    plink_memory  <- 12000L
  } else {
    instance_type <- "mem2_ssd2_v2_x8"
    n_threads     <- 8L
    plink_memory  <- 28000L
  }

  # ---------------------------------------------------------------------------
  # 3. Verify project context
  # ---------------------------------------------------------------------------
  project_id <- .dx_get_project_id()
  if (is.na(project_id) || !nzchar(project_id))
    cli::cli_abort("No project selected. Run {.fn auth_select_project} first.", call = NULL)

  # ---------------------------------------------------------------------------
  # 4. Generate driver script, write to tempfile, upload to RAP
  # ---------------------------------------------------------------------------
  script_name   <- if (instance == "standard") "grs_bgen2pgen_std.R"
                   else                         "grs_bgen2pgen_lrg.R"
  script_remote <- paste0("/", script_name)

  tmp_script <- tempfile(fileext = ".R")
  on.exit(unlink(tmp_script), add = TRUE)
  writeLines(.bgen2pgen_script(n_threads, plink_memory, maf), tmp_script)

  existing <- tryCatch(fetch_ls(".", type = "file"), error = function(e) NULL)

  if (!is.null(existing) && script_name %in% existing$name) {
    cli::cli_alert_success("{.val {script_name}} already on RAP, skipping upload.")
  } else {
    cli::cli_inform("Uploading {.val {script_name}} to RAP ...")
    up <- .dx_run(
      c("upload", tmp_script, "--path", script_remote, "--brief", "--wait"),
      timeout = 120L
    )
    if (!up$success)
      cli::cli_abort("Script upload failed: {up$stderr}", call = NULL)
    cli::cli_alert_success("Uploaded: {.val {script_remote}}")
  }

  # ---------------------------------------------------------------------------
  # 5. Submit one Swiss Army Knife job per chromosome
  # ---------------------------------------------------------------------------
  cli::cli_inform(
    "Submitting {length(chr)} job(s) -- {instance_type} / priority: {priority}"
  )

  job_ids <- character(length(chr))

  for (i in seq_along(chr)) {
    ch <- chr[i]

    # Mirrors dx download + Rscript pattern from scripts 07 / 09 / 12
    cmd <- paste0(
      "dx download ", project_id, ":", script_remote, " --overwrite",
      " && Rscript ", script_name, " ", ch
    )

    res <- .dx_run(c(
      "run", "swiss-army-knife",
      paste0("-icmd=", cmd),
      "--destination",   dest,
      "--instance-type", instance_type,
      "--priority",      priority,
      "--name",          paste0("pgen_chr", ch),
      "--brief",
      "--yes"
    ), timeout = 60L)

    if (res$success) {
      job_ids[i] <- trimws(res$stdout)
      cli::cli_alert_success("chr{ch} -> {.val {job_ids[i]}}")
    } else {
      job_ids[i] <- NA_character_
      cli::cli_alert_danger("chr{ch} submission failed: {res$stderr}")
    }

    # Avoid DNAnexus API rate limits
    if (i < length(chr)) Sys.sleep(0.5)
  }

  n_ok <- sum(!is.na(job_ids))
  cli::cli_alert_success(
    "{n_ok}/{length(chr)} job(s) submitted. Monitor with {.fn job_ls}."
  )

  invisible(job_ids)
}


#' Calculate genetic risk scores from PGEN files on RAP
#'
#' Uploads local SNP weight files to the RAP project root, then submits one
#' Swiss Army Knife job per GRS. Each job runs plink2 \code{--score} across
#' all 22 chromosomes and saves a single CSV to \code{dest} on completion.
#' Jobs run in parallel; use \code{\link{job_ls}} to monitor progress.
#'
#' Weight files should have three columns (any delimiter, header required):
#' \describe{
#'   \item{Column 1}{Variant ID (e.g. \code{rs} IDs).}
#'   \item{Column 2}{Effect allele (A1).}
#'   \item{Column 3}{Effect weight (beta / log-OR).}
#' }
#' This matches the output format of \code{\link{grs_check}}.
#'
#' \strong{Output per job:} \code{dest/<score_name>_scores.csv} with columns
#' \code{IID} and the GRS score (named \code{GRS_<name>}).
#'
#' \strong{Instance types:}
#' \describe{
#'   \item{\code{"standard"}}{\code{mem2_ssd1_v2_x4}: 4 cores, 12 GB RAM.}
#'   \item{\code{"large"}}{\code{mem2_ssd2_v2_x8}: 8 cores, 28 GB RAM.}
#' }
#'
#' @param file Named character vector of local weight file paths. Names become
#'   the GRS identifiers (output column = \code{GRS_<name>}).
#'   Example: \code{c(grs_a = "weights_a.txt")}.
#' @param pgen_dir Character scalar. Path to PGEN files on RAP.
#'   Default: \code{"/mnt/project/pgen"}.
#' @param dest Character scalar. RAP destination path for output CSV files.
#'   Default: \code{"/grs/"}.
#' @param maf Numeric scalar. MAF filter threshold used when locating PGEN
#'   files. Must match the value used in \code{\link{grs_bgen2pgen}}.
#'   Default: \code{0.01}.
#' @param instance Character scalar. Instance type preset: \code{"standard"}
#'   or \code{"large"}. Default: \code{"standard"}.
#' @param priority Character scalar. Job priority: \code{"low"} or
#'   \code{"high"}. Default: \code{"low"}.
#'
#' @return A named character vector of job IDs (one per GRS), returned
#'   invisibly. Failed submissions are \code{NA}. Use \code{\link{job_ls}} to
#'   monitor progress.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ids <- grs_score(
#'   file = c(
#'     grs_a = "weights/grs_a_weights.txt",
#'     grs_b = "weights/grs_b_weights.txt"
#'   ),
#'   dest     = "/grs/",
#'   priority = "high"
#' )
#'
#' job_ls()
#' }
grs_score <- function(file,
                      pgen_dir = "/mnt/project/pgen",
                      dest     = "/grs/",
                      maf      = 0.01,
                      instance = "standard",
                      priority = "low") {

  # ---------------------------------------------------------------------------
  # 1. Validate arguments
  # ---------------------------------------------------------------------------
  instance <- match.arg(instance, c("standard", "large"))
  priority <- match.arg(priority, c("low", "high"))

  if (!is.numeric(maf) || length(maf) != 1L || maf <= 0 || maf >= 0.5)
    cli::cli_abort("{.arg maf} must be a single numeric value in (0, 0.5). Must match the value used in {.fn grs_bgen2pgen}.", call = NULL)

  if (!is.character(file))
    cli::cli_abort("{.arg file} must be a named character vector.", call = NULL)
  if (is.null(names(file)) || any(!nzchar(names(file))))
    cli::cli_abort("{.arg file} must be fully named (each entry needs a name).", call = NULL)
  if (any(duplicated(names(file))))
    cli::cli_abort(
      "Duplicate names in {.arg file}: {.val {names(file)[duplicated(names(file))]}}",
      call = NULL
    )

  missing_local <- file[!file.exists(file)]
  if (length(missing_local) > 0L)
    cli::cli_abort(c(
      "Local weight file(s) not found:",
      setNames(missing_local, rep("x", length(missing_local)))
    ), call = NULL)

  # ---------------------------------------------------------------------------
  # 2. Instance config
  # ---------------------------------------------------------------------------
  if (instance == "standard") {
    instance_type <- "mem2_ssd1_v2_x4"
    n_threads     <- 4L
    plink_memory  <- 12000L
  } else {
    instance_type <- "mem2_ssd2_v2_x8"
    n_threads     <- 8L
    plink_memory  <- 28000L
  }

  # ---------------------------------------------------------------------------
  # 3. Verify project context
  # ---------------------------------------------------------------------------
  project_id <- .dx_get_project_id()
  if (is.na(project_id) || !nzchar(project_id))
    cli::cli_abort("No project selected. Run {.fn auth_select_project} first.", call = NULL)

  # ---------------------------------------------------------------------------
  # 4. Upload weight files to RAP root
  # Reason: SAK jobs access /mnt/project/<name>; uploading to root means the
  # driver script can read them at /mnt/project/<basename>.
  # ---------------------------------------------------------------------------
  cli::cli_h1("Uploading {length(file)} weight file(s) to RAP")

  existing <- tryCatch(fetch_ls(".", type = "file"), error = function(e) NULL)
  existing_names <- if (!is.null(existing)) existing$name else character(0L)

  for (i in seq_along(file)) {
    fname       <- basename(file[[i]])
    remote_path <- paste0("/", fname)

    # If already at RAP root (e.g. /mnt/project/<fname>), skip delete + upload.
    # Reason: deleting before re-uploading would destroy the source file itself.
    if (.is_on_rap() && identical(file[[i]], paste0("/mnt/project/", fname))) {
      cli::cli_alert_info("{.val {fname}} already at RAP root, skipping upload.")
      next
    }

    if (fname %in% existing_names) {
      cli::cli_inform("Removing existing {.val {fname}} from RAP ...")
      rm_res <- .dx_run(c("rm", remote_path), timeout = 30L)
      if (!rm_res$success)
        cli::cli_abort("Failed to remove {.val {fname}}: {rm_res$stderr}", call = NULL)
    }

    cli::cli_inform("Uploading {.val {fname}} ...")
    up <- .dx_run(
      c("upload", file[[i]], "--path", remote_path, "--brief", "--wait"),
      timeout = 120L
    )
    if (!up$success)
      cli::cli_abort("Upload failed for {.val {fname}}: {up$stderr}", call = NULL)

    cli::cli_alert_success("Uploaded: {.val {remote_path}}")
  }

  # ---------------------------------------------------------------------------
  # 5. Generate driver script, upload once to RAP root
  # ---------------------------------------------------------------------------
  script_name   <- if (instance == "standard") "grs_score_std.R"
                   else                         "grs_score_lrg.R"
  script_remote <- paste0("/", script_name)

  tmp_script <- tempfile(fileext = ".R")
  on.exit(unlink(tmp_script), add = TRUE)
  writeLines(.grs_score_script(n_threads, plink_memory, maf), tmp_script)

  # Re-fetch to account for any files added during weight uploads
  existing2 <- tryCatch(fetch_ls(".", type = "file"), error = function(e) NULL)

  if (!is.null(existing2) && script_name %in% existing2$name) {
    cli::cli_alert_success("{.val {script_name}} already on RAP, skipping upload.")
  } else {
    cli::cli_inform("Uploading {.val {script_name}} to RAP ...")
    up <- .dx_run(
      c("upload", tmp_script, "--path", script_remote, "--brief", "--wait"),
      timeout = 120L
    )
    if (!up$success)
      cli::cli_abort("Script upload failed: {up$stderr}", call = NULL)
    cli::cli_alert_success("Uploaded: {.val {script_remote}}")
  }

  # ---------------------------------------------------------------------------
  # 6. Submit one Swiss Army Knife job per GRS
  # ---------------------------------------------------------------------------
  cli::cli_inform(
    "Submitting {length(file)} job(s) -- {instance_type} / priority: {priority}"
  )

  job_ids <- character(length(file))
  names(job_ids) <- names(file)

  for (i in seq_along(file)) {
    nm          <- names(file)[i]
    score_name  <- paste0("GRS_", nm)
    weight_fname <- basename(file[[i]])

    cmd <- paste0(
      "dx download ", project_id, ":", script_remote, " --overwrite",
      " && Rscript ", script_name,
      " ", weight_fname,
      " ", score_name,
      " ", pgen_dir
    )

    res <- .dx_run(c(
      "run", "swiss-army-knife",
      paste0("-icmd=", cmd),
      "--destination",   dest,
      "--instance-type", instance_type,
      "--priority",      priority,
      "--name",          paste0("grs_score_", nm),
      "--brief",
      "--yes"
    ), timeout = 60L)

    if (res$success) {
      job_ids[i] <- trimws(res$stdout)
      cli::cli_alert_success("{nm} -> {.val {job_ids[i]}}")
    } else {
      job_ids[i] <- NA_character_
      cli::cli_alert_danger("{nm} submission failed: {res$stderr}")
    }

    if (i < length(file)) Sys.sleep(0.5)
  }

  n_ok <- sum(!is.na(job_ids))
  cli::cli_alert_success(
    "{n_ok}/{length(file)} job(s) submitted. Monitor with {.fn job_ls}."
  )

  invisible(job_ids)
}


#' Standardise GRS columns by Z-score transformation
#'
#' Adds a \code{_z} column for every selected GRS column:
#' \code{z = (x - mean(x)) / sd(x)}.  The original columns are kept
#' unchanged.  \code{\link{grs_zscore}} is an alias for this function.
#'
#' @param data A \code{data.frame} or \code{data.table} containing at least
#'   one GRS column.
#' @param grs_cols Character vector of column names to standardise.
#'   If \code{NULL} (default), all columns whose names contain \code{"grs"}
#'   (case-insensitive) are selected automatically.
#'
#' @return The input \code{data} as a \code{data.table} with one additional
#'   \code{_z} column per GRS column appended after its source column.
#'
#' @export
#'
#' @examples
#' dt <- data.frame(
#'   IID   = 1:5,
#'   GRS_a = c(0.12, 0.34, 0.56, 0.23, 0.45),
#'   GRS_b = c(1.1,  0.9,  1.3,  0.8,  1.0)
#' )
#' grs_standardize(dt)
#' grs_zscore(dt)   # identical
grs_standardize <- function(data, grs_cols = NULL) {

  # ---------------------------------------------------------------------------
  # 1. Validate data
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data))
    cli::cli_abort("{.arg data} must be a data.frame or data.table.", call = NULL)

  dt <- data.table::as.data.table(data)

  # ---------------------------------------------------------------------------
  # 2. Resolve target columns
  # ---------------------------------------------------------------------------
  if (is.null(grs_cols)) {
    grs_cols <- names(dt)[grepl("grs", names(dt), ignore.case = TRUE)]
    if (length(grs_cols) == 0L)
      cli::cli_abort("No columns containing {.val grs} found. Supply column names via {.arg grs_cols}.", call = NULL)
    cli::cli_inform("Auto-detected {length(grs_cols)} GRS column(s): {.val {grs_cols}}")
  } else {
    missing_cols <- setdiff(grs_cols, names(dt))
    if (length(missing_cols) > 0L)
      cli::cli_abort("Column(s) not found in data: {.val {missing_cols}}", call = NULL)
  }

  # ---------------------------------------------------------------------------
  # 3. Z-score each column: add _z column immediately after source column
  # ---------------------------------------------------------------------------
  for (col in grs_cols) {
    x       <- dt[[col]]
    mu      <- mean(x, na.rm = TRUE)
    sigma   <- stats::sd(x, na.rm = TRUE)

    if (sigma == 0)
      cli::cli_abort("{.field {col}} has zero variance - cannot standardise.", call = NULL)

    z_col   <- paste0(col, "_z")
    z_vals  <- (x - mu) / sigma

    # Insert _z column right after source column
    idx     <- which(names(dt) == col)
    dt      <- cbind(dt[, 1:idx, with = FALSE],
                     data.table::data.table(tmp__ = z_vals),
                     if (idx < ncol(dt)) dt[, (idx + 1L):ncol(dt), with = FALSE]
                     else NULL)
    data.table::setnames(dt, "tmp__", z_col)

    cli::cli_alert_success(
      "{col} -> {z_col}  [mean={round(mu, 4)}, sd={round(sigma, 4)}]"
    )
  }

  dt
}


#' @rdname grs_standardize
#' @export
grs_zscore <- grs_standardize


#' Validate GRS predictive performance
#'
#' For each GRS column, computes four sets of validation metrics:
#' \enumerate{
#'   \item \strong{Per SD} - OR (logistic) or HR (Cox) per 1-SD increase.
#'   \item \strong{High vs Low} - OR / HR comparing top 20\% vs bottom 20\%
#'     (extreme tertile grouping: Low / Mid / High).
#'   \item \strong{Trend test} - P-trend across quartiles (Q1–Q4).
#'   \item \strong{Discrimination} - AUC (logistic) or C-index (Cox).
#' }
#'
#' GRS grouping columns are created internally via \code{\link{derive_cut}}
#' and are not added to the user's data.  When \code{time_col} is
#' \code{NULL}, logistic regression is used throughout; when supplied, Cox
#' proportional hazards models are used.
#'
#' Models follow the same adjustment logic as \code{\link{assoc_logistic}} /
#' \code{\link{assoc_coxph}}: unadjusted and age-sex adjusted models are
#' always included; a fully adjusted model is added when \code{covariates}
#' is non-\code{NULL}.
#'
#' @param data A \code{data.frame} or \code{data.table}.
#' @param grs_cols Character vector of GRS column names to validate.
#'   If \code{NULL} (default), all columns whose names contain \code{"grs"}
#'   (case-insensitive) are selected automatically.
#' @param outcome_col Character scalar. Name of the outcome column
#'   (\code{0}/\code{1} or \code{TRUE}/\code{FALSE}).
#' @param time_col Character scalar or \code{NULL}. Name of the follow-up
#'   time column. When \code{NULL} (default), logistic regression is used;
#'   when supplied, Cox regression is used.
#' @param covariates Character vector or \code{NULL}. Covariates for the
#'   fully adjusted model. When \code{NULL}, only unadjusted and age-sex
#'   adjusted models are run.
#'
#' @return A named \code{list} with four \code{data.table} elements:
#' \itemize{
#'   \item \code{per_sd}: OR / HR per 1-SD increase in GRS.
#'   \item \code{high_vs_low}: OR / HR for High vs Low extreme tertile.
#'   \item \code{trend}: P-trend across Q1–Q4 quartiles.
#'   \item \code{discrimination}: AUC (logistic) or C-index (Cox) with 95\% CI.
#' }
#'
#' @importFrom survival coxph Surv concordance
#' @export
#'
#' @examples
#' \dontrun{
#' # Logistic (cross-sectional)
#' res <- grs_validate(
#'   data        = cohort,
#'   grs_cols    = c("GRS_a_z", "GRS_b_z"),
#'   outcome_col = "outcome"
#' )
#'
#' # Cox (survival)
#' res <- grs_validate(
#'   data        = cohort,
#'   grs_cols    = c("GRS_a_z", "GRS_b_z"),
#'   outcome_col = "outcome",
#'   time_col    = "followup_years",
#'   covariates  = c("age", "sex", paste0("pc", 1:10))
#' )
#'
#' res$per_sd
#' res$discrimination
#' }
grs_validate <- function(data,
                         grs_cols    = NULL,
                         outcome_col,
                         time_col    = NULL,
                         covariates  = NULL) {

  # ---------------------------------------------------------------------------
  # 1. Validate inputs
  # ---------------------------------------------------------------------------
  if (!is.data.frame(data))
    cli::cli_abort("{.arg data} must be a data.frame or data.table.", call = NULL)

  # Work on a copy so derive_cut() in-place ops don't touch the user's data
  dt <- data.table::copy(data.table::as.data.table(data))

  if (is.null(grs_cols)) {
    grs_cols <- names(dt)[grepl("grs", names(dt), ignore.case = TRUE)]
    if (length(grs_cols) == 0L)
      cli::cli_abort("No GRS columns found. Supply column names via {.arg grs_cols}.", call = NULL)
    cli::cli_inform("Auto-detected {length(grs_cols)} GRS column(s): {.val {grs_cols}}")
  }

  missing_cols <- setdiff(c(grs_cols, outcome_col, time_col, covariates), names(dt))
  if (length(missing_cols) > 0L)
    cli::cli_abort("Column(s) not found in data: {.val {missing_cols}}", call = NULL)

  is_cox <- !is.null(time_col)

  # ---------------------------------------------------------------------------
  # 2. Create Q4 (quartile) and E3 (20/60/20) grouping columns via derive_cut
  # ---------------------------------------------------------------------------
  cli::cli_h1("Creating GRS groups")

  quad_cols <- setNames(paste0(grs_cols, "_quad"), grs_cols)
  tri_cols  <- setNames(paste0(grs_cols, "_tri"),  grs_cols)

  for (col in grs_cols) {
    dt <- derive_cut(dt, col = col, n = 4L)

    e3_breaks <- stats::quantile(dt[[col]], probs = c(0.2, 0.8), na.rm = TRUE)
    dt <- derive_cut(dt, col = col, n = 3L,
                     breaks = e3_breaks,
                     labels = c("Low", "Mid", "High"))

    # Ensure "Low" is reference level for High vs Low contrast
    dt[, (tri_cols[col]) := relevel(factor(get(tri_cols[col])), ref = "Low")]
  }

  # ---------------------------------------------------------------------------
  # 3. Effect per SD
  # ---------------------------------------------------------------------------
  cli::cli_h1("Effect per SD ({if (is_cox) 'HR' else 'OR'})")

  per_sd <- if (is_cox) {
    assoc_coxph(dt,
                outcome_col  = outcome_col, time_col    = time_col,
                exposure_col = grs_cols,    covariates  = covariates)
  } else {
    assoc_logistic(dt,
                   outcome_col  = outcome_col,
                   exposure_col = grs_cols,   covariates = covariates)
  }

  # ---------------------------------------------------------------------------
  # 4. High vs Low (E3 grouping; keep only the High row from results)
  # ---------------------------------------------------------------------------
  cli::cli_h1("High vs Low")

  high_vs_low <- if (is_cox) {
    assoc_coxph(dt,
                outcome_col  = outcome_col,        time_col   = time_col,
                exposure_col = unname(tri_cols),   covariates = covariates)
  } else {
    assoc_logistic(dt,
                   outcome_col  = outcome_col,
                   exposure_col = unname(tri_cols), covariates = covariates)
  }
  high_vs_low <- high_vs_low[grepl("High$", term)]

  # ---------------------------------------------------------------------------
  # 5. Trend test across Q4 quartiles
  # ---------------------------------------------------------------------------
  cli::cli_h1("Trend test")

  trend <- assoc_trend(dt,
                       outcome_col  = outcome_col,
                       time_col     = time_col,
                       exposure_col = unname(quad_cols),
                       method       = if (is_cox) "coxph" else "logistic",
                       covariates   = covariates)

  # ---------------------------------------------------------------------------
  # 6. Discrimination: AUC (logistic) or C-index (Cox)
  # ---------------------------------------------------------------------------
  cli::cli_h1("{if (is_cox) 'C-index' else 'AUC'}")

  if (!is_cox && !requireNamespace("pROC", quietly = TRUE))
    cli::cli_abort(
      "Package {.pkg pROC} is required for AUC. Install with {.code install.packages('pROC')}.",
      call = NULL
    )

  disc_list <- lapply(grs_cols, function(col) {
    if (is_cox) {
      fit   <- survival::coxph(
        survival::Surv(dt[[time_col]], dt[[outcome_col]]) ~ dt[[col]]
      )
      conc  <- survival::concordance(fit)
      c_idx <- conc$concordance
      c_se  <- sqrt(conc$var)
      data.table::data.table(
        GRS      = col,
        C_index  = c_idx,
        CI_lower = c_idx - 1.96 * c_se,
        CI_upper = c_idx + 1.96 * c_se
      )
    } else {
      roc_obj <- pROC::roc(dt[[outcome_col]], dt[[col]], quiet = TRUE)
      auc_val <- as.numeric(pROC::auc(roc_obj))
      ci_obj  <- pROC::ci.auc(roc_obj)
      data.table::data.table(
        GRS      = col,
        AUC      = auc_val,
        CI_lower = ci_obj[1L],
        CI_upper = ci_obj[3L]
      )
    }
  })
  discrimination <- data.table::rbindlist(disc_list)

  cli::cli_alert_success("Validation complete.")

  list(
    per_sd         = per_sd,
    high_vs_low    = high_vs_low,
    trend          = trend,
    discrimination = discrimination
  )
}
