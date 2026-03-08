# =============================================================================
# utils_fetch.R — Internal helpers for fetch_ series
# Depends on .dx_run() defined in utils_auth.R
# =============================================================================


#' Normalize a remote RAP path to dx-compatible format
#'
#' @keywords internal
#' @noRd
.dx_normalize_path <- function(path) {
  # Reason: dx CLI uses relative paths from project root — a leading slash
  # causes ResolutionError ("Could not find project named 'C'")
  path <- sub("^/+", "", trimws(path))
  if (path == ".") path <- ""
  path
}


#' Run dx ls -l on a remote path and return raw output
#'
#' @keywords internal
#' @noRd
.dx_ls_raw <- function(path, timeout = 60) {
  norm <- .dx_normalize_path(path)
  args <- c("ls", "-l")
  if (nzchar(norm)) args <- c(args, norm)
  .dx_run(args, timeout = timeout)
}


#' Run dx ls (names only) on a remote path and return raw output
#'
#' @keywords internal
#' @noRd
.dx_ls_names <- function(path, timeout = 60) {
  norm <- .dx_normalize_path(path)
  args <- c("ls")
  if (nzchar(norm)) args <- c(args, norm)
  .dx_run(args, timeout = timeout)
}


#' Generate a pre-authenticated download URL for a remote RAP file
#'
#' @param path (character) Remote file path.
#' @param duration (character) URL validity duration. Default: \code{"1d"}.
#' @return Character string — the pre-authenticated HTTPS URL.
#'
#' @keywords internal
#' @noRd
.dx_make_url <- function(path, duration = "1d") {
  norm <- .dx_normalize_path(path)
  result <- .dx_run(c("make_download_url", "--duration", duration, norm), timeout = 30)
  if (!result$success) {
    stop("Failed to generate URL for '", path, "': ", result$stderr, call. = FALSE)
  }
  trimws(result$stdout)
}


#' Download a single file via pre-authenticated URL
#'
#' @param url (character) Pre-authenticated HTTPS URL.
#' @param destfile (character) Full local file path to save to.
#' @param overwrite (logical) Overwrite if file exists. Default: FALSE.
#' @param resume (logical) Resume interrupted download. Default: FALSE.
#'
#' @keywords internal
#' @noRd
.dx_download_file <- function(url, destfile, overwrite = FALSE, resume = FALSE, verbose = TRUE) {
  if (file.exists(destfile) && !overwrite && !resume) {
    cli::cli_inform("Skipping (already exists): {.file {basename(destfile)}}")
    return(invisible(destfile))
  }

  h <- curl::new_handle()
  curl::handle_setopt(h, followlocation = TRUE, noprogress = !verbose)

  # Reason: resume appends from the current file size if signatures match
  if (resume && file.exists(destfile)) {
    curl::handle_setopt(h, resume_from = file.info(destfile)$size)
  }

  curl::curl_download(url, destfile = destfile, handle = h, quiet = !verbose)
  invisible(destfile)
}


#' Download multiple files in parallel via pre-authenticated URLs
#'
#' @param urls (character) Named character vector of URLs (names = filenames).
#' @param destfiles (character) Character vector of full local file paths.
#' @param overwrite (logical) Overwrite existing files. Default: FALSE.
#' @param resume (logical) Resume interrupted downloads. Default: FALSE.
#' @param workers (integer) Number of parallel connections. Default: 4.
#'
#' @keywords internal
#' @noRd
.dx_download_batch <- function(urls, destfiles, overwrite = FALSE,
                                resume = FALSE, verbose = TRUE) {
  # Reason: skip files that already exist when overwrite = FALSE and resume = FALSE
  if (!overwrite && !resume) {
    skip    <- file.exists(destfiles)
    if (any(skip)) {
      cli::cli_inform("Skipping {sum(skip)} already existing file(s).")
      urls      <- urls[!skip]
      destfiles <- destfiles[!skip]
    }
  }

  if (length(urls) == 0) {
    cli::cli_inform("All files already exist, nothing to download.")
    return(invisible(destfiles))
  }

  curl::multi_download(
    urls     = urls,
    destfile = destfiles,
    resume   = resume,
    progress = verbose,
    multiplex = TRUE
  )

  invisible(destfiles)
}


#' Parse dx ls -l stdout into a data.frame
#'
#' @param stdout (character) Raw stdout from dx ls -l.
#' @return data.frame with columns: name, type, size, modified.
#'
#' @keywords internal
#' @noRd
.dx_ls_parse <- function(stdout) {

  lines <- strsplit(stdout, "\n")[[1]]
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]

  # Drop dx header lines (Project: / Folder :)
  lines <- lines[!grepl("^(Project:|Folder\\s*:)", lines)]

  folder_rows <- list()
  file_rows   <- list()
  in_files    <- FALSE

  for (line in lines) {

    # "State   Last modified ..." marks start of file section
    if (grepl("^State\\s+Last modified", line)) {
      in_files <- TRUE
      next
    }

    # dx prints this when a folder has no files
    if (grepl("^No data objects found", line)) next

    if (!in_files) {
      # Folder lines always end with "/"
      if (endsWith(line, "/")) {
        folder_rows[[length(folder_rows) + 1]] <- data.frame(
          name     = sub("/$", "", line),
          type     = "folder",
          size     = NA_character_,
          modified = as.POSIXct(NA_character_),
          stringsAsFactors = FALSE
        )
      }

    } else {
      # File line format: state  YYYY-MM-DD HH:MM:SS  [size]  name (id)
      # Step 1: strip the trailing (id) so name parsing is clean
      id_m <- regexpr("\\s+\\([a-z]+-[A-Za-z0-9]+\\)\\s*$", line, perl = TRUE)
      if (id_m < 0) next
      core <- trimws(substr(line, 1, id_m - 1))

      # Step 2: parse fixed fields with optional size
      m <- regexec(
        paste0(
          "^(\\S+)",                                      # state
          "\\s+(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})",  # modified
          "\\s+(?:([\\d.]+ (?:[KMGT]?B|bytes))\\s+)?",    # optional size (KB/MB/GB/bytes)
          "(.+?)\\s*$"                                    # name
        ),
        core, perl = TRUE
      )
      cap <- regmatches(core, m)[[1]]
      if (length(cap) < 5) next

      file_rows[[length(file_rows) + 1]] <- data.frame(
        name     = cap[5],
        type     = "file",
        size     = if (nzchar(cap[4])) cap[4] else NA_character_,
        modified = as.POSIXct(cap[3], format = "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE
      )
    }
  }

  empty <- data.frame(
    name     = character(0),
    type     = character(0),
    size     = character(0),
    modified = as.POSIXct(character(0)),
    stringsAsFactors = FALSE
  )

  rbind(
    if (length(folder_rows) > 0) do.call(rbind, folder_rows) else empty,
    if (length(file_rows)   > 0) do.call(rbind, file_rows)   else empty
  )
}
