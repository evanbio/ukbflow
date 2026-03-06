# =============================================================================
# fetch.R — Remote RAP file system exploration and data retrieval
# =============================================================================


#' List files and folders at a remote RAP path
#'
#' Returns a structured data.frame describing the contents of a remote
#' DNAnexus Research Analysis Platform (RAP) directory. Analogous to
#' \code{file_info()} but for remote project storage.
#'
#' @param path (character) Remote path to list. Default: \code{"."} (project
#'   root). Both \code{"Bulk/"} and \code{"/Bulk/"} are accepted.
#' @param type (character) Filter results by entry type: \code{"all"}
#'   (default), \code{"file"}, or \code{"folder"}.
#' @param pattern (character) Optional regex to filter by name, e.g.
#'   \code{"\\.bed$"}. Default: \code{NULL}.
#'
#' @return A data.frame with columns:
#'   \describe{
#'     \item{name}{Entry name (no trailing slash for folders).}
#'     \item{type}{\code{"file"} or \code{"folder"}.}
#'     \item{size}{File size string (e.g. \code{"120.94 GB"}), \code{NA} for
#'       folders or non-file objects.}
#'     \item{modified}{Last modified time (\code{POSIXct}), \code{NA} for
#'       folders.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_ls()
#' fetch_ls("Showcase metadata/", type = "file")
#' fetch_ls("results/", pattern = "\\.csv$")
#' }
fetch_ls <- function(path = ".", type = "all", pattern = NULL) {
  type <- match.arg(type, c("all", "file", "folder"))

  result <- .dx_ls_raw(path)
  if (!result$success) {
    stop("Failed to list '", path, "': ", result$stderr, call. = FALSE)
  }

  df <- .dx_ls_parse(result$stdout)

  if (type != "all") {
    df <- df[df$type == type, , drop = FALSE]
  }

  if (!is.null(pattern)) {
    df <- df[grepl(pattern, df$name, perl = TRUE), , drop = FALSE]
  }

  df
}


#' Print a remote RAP directory tree
#'
#' Displays the remote directory structure in a tree-like format by
#' recursively listing sub-folders up to \code{max_depth}. Analogous to
#' \code{file_tree()} but for remote project storage.
#'
#' @param path (character) Remote root path. Default: \code{"."} (project
#'   root). Both \code{"Bulk/"} and \code{"/Bulk/"} are accepted.
#' @param max_depth (integer) Maximum recursion depth. Default: \code{2}.
#' @param verbose (logical) Whether to print the tree to the console.
#'   Default: \code{TRUE}.
#'
#' @section Warning:
#' Each level of recursion triggers one HTTPS API call per folder. Deep trees
#' (e.g. \code{max_depth > 3}) on large UKB projects may issue 100+ network
#' requests, causing the console to hang for tens of seconds or time out.
#' Keep \code{max_depth} at 2–3 for interactive use.
#'
#' @return Invisibly returns a character vector of tree lines.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_tree()
#' fetch_tree("Bulk/", max_depth = 3)
#' fetch_tree(verbose = FALSE)
#' }
#' Get pre-authenticated download URL(s) for a remote RAP file or folder
#'
#' Generates temporary HTTPS URLs for files on the DNAnexus Research Analysis
#' Platform. For a single file, returns one URL. For a folder, lists all files
#' inside and returns a named character vector of URLs.
#'
#' @param path (character) Remote file path or folder path, e.g.
#'   \code{"Showcase metadata/field.tsv"} or \code{"Showcase metadata/"}.
#' @param duration (character) How long the URLs remain valid. Accepts
#'   suffixes: \code{s}, \code{m}, \code{h}, \code{d}, \code{w}, \code{M},
#'   \code{y}. Default: \code{"1d"} (one day).
#'
#' @return A named character vector of pre-authenticated HTTPS URLs.
#'   Names are the file names.
#' @export
#'
#' @examples
#' \dontrun{
#' # Single file
#' fetch_url("Showcase metadata/field.tsv")
#'
#' # Entire folder
#' fetch_url("Showcase metadata/", duration = "7d")
#' }
fetch_url <- function(path, duration = "1d") {
  norm <- .dx_normalize_path(path)

  # Reason: detect folder by trailing slash or by checking if ls returns folders
  is_folder <- endsWith(trimws(path), "/")

  if (!is_folder) {
    url <- .dx_make_url(norm, duration = duration)
    return(stats::setNames(url, basename(norm)))
  }

  # Folder: list all files then loop
  files <- fetch_ls(path, type = "file")
  if (nrow(files) == 0) {
    message("No files found in '", path, "'.")
    return(invisible(character(0)))
  }

  urls <- vapply(
    file.path(norm, files$name),
    function(f) .dx_make_url(f, duration = duration),
    character(1)
  )
  stats::setNames(urls, files$name)
}


#' Download a remote RAP file or folder to local disk
#'
#' Downloads one file or all files within a folder from the DNAnexus Research
#' Analysis Platform. Single files are downloaded sequentially; folders are
#' downloaded in parallel using \code{curl::multi_download()}.
#'
#' @param path (character) Remote file or folder path.
#' @param dest_dir (character) Local destination directory. Created
#'   automatically if it does not exist. Default: \code{"."}.
#' @param overwrite (logical) Overwrite existing local files. Default:
#'   \code{FALSE}.
#' @param resume (logical) Resume an interrupted download. Useful for large
#'   files (e.g. \code{.bed}, \code{.bgen}). Default: \code{FALSE}.
#'
#' @return Invisibly returns the local file path(s) as a character vector.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download a single metadata file
#' fetch_file("Showcase metadata/field.tsv", dest_dir = "data/")
#'
#' # Download an entire folder
#' fetch_file("Showcase metadata/", dest_dir = "data/metadata/")
#'
#' # Resume an interrupted download
#' fetch_file("results/summary_stats.csv", dest_dir = "data/", resume = TRUE)
#' }
fetch_file <- function(path, dest_dir = ".", overwrite = FALSE,
                       resume = FALSE, verbose = TRUE) {
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  is_folder <- endsWith(trimws(path), "/")

  if (!is_folder) {
    # Single file
    url      <- .dx_make_url(path)
    destfile <- file.path(dest_dir, basename(.dx_normalize_path(path)))
    .dx_download_file(url, destfile, overwrite = overwrite, resume = resume, verbose = verbose)

  } else {
    # Folder: list files, batch generate URLs, parallel download
    files <- fetch_ls(path, type = "file")
    if (nrow(files) == 0) {
      message("No files found in '", path, "'.")
      return(invisible(character(0)))
    }

    norm      <- .dx_normalize_path(path)
    urls      <- vapply(file.path(norm, files$name),
                        function(f) .dx_make_url(f), character(1))
    destfiles <- file.path(dest_dir, files$name)

    .dx_download_batch(urls, destfiles, overwrite = overwrite,
                       resume = resume, verbose = verbose)
  }
}


#' Download all UKB Showcase metadata files
#'
#' Downloads the entire \code{Showcase metadata/} folder from the DNAnexus
#' Research Analysis Platform to a local directory. This includes
#' \code{field.tsv}, \code{encoding.tsv}, and all associated encoding tables.
#'
#' @param dest_dir (character) Local destination directory. Created
#'   automatically if it does not exist. Default: \code{"data/metadata/"}.
#' @param overwrite (logical) Overwrite existing local files. Default:
#'   \code{FALSE}.
#' @param resume (logical) Resume interrupted downloads. Default: \code{FALSE}.
#' @param verbose (logical) Show download progress. Default: \code{TRUE}.
#'
#' @return Invisibly returns the local file paths as a character vector.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_metadata()
#' fetch_metadata(dest_dir = "metadata/", overwrite = TRUE)
#' }
fetch_metadata <- function(dest_dir = "data/metadata/", overwrite = FALSE,
                           resume = FALSE, verbose = TRUE) {
  fetch_file("Showcase metadata/", dest_dir = dest_dir,
             overwrite = overwrite, resume = resume, verbose = verbose)
}


#' Download the UKB field dictionary file
#'
#' Downloads \code{field.tsv} from the \code{Showcase metadata/} folder on the
#' DNAnexus Research Analysis Platform. This file contains the complete UKB
#' data dictionary: field IDs, titles, value types, and encoding references.
#'
#' @param dest_dir (character) Local destination directory. Created
#'   automatically if it does not exist. Default: \code{"data/metadata/"}.
#' @param overwrite (logical) Overwrite existing local file. Default:
#'   \code{FALSE}.
#' @param resume (logical) Resume an interrupted download. Default:
#'   \code{FALSE}.
#' @param verbose (logical) Show download progress. Default: \code{TRUE}.
#'
#' @return Invisibly returns the local file path as a character string.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_field()
#' fetch_field(dest_dir = "metadata/", overwrite = TRUE)
#' }
fetch_field <- function(dest_dir = "data/metadata/", overwrite = FALSE,
                        resume = FALSE, verbose = TRUE) {
  fetch_file("Showcase metadata/field.tsv", dest_dir = dest_dir,
             overwrite = overwrite, resume = resume, verbose = verbose)
}


fetch_tree <- function(path = ".", max_depth = 2, verbose = TRUE) {
  norm  <- .dx_normalize_path(path)
  lines <- character(0)

  tree_chars <- list(branch = "+-- ", pipe = "|   ", space = "    ")

  traverse <- function(p, depth = 0, prefix = "") {
    if (depth >= max_depth) return()

    res <- .dx_ls_names(p)
    if (!res$success || !nzchar(res$stdout)) return()

    entries <- strsplit(res$stdout, "\n")[[1]]
    entries <- trimws(entries[nzchar(entries)])

    for (i in seq_along(entries)) {
      entry     <- entries[i]
      is_folder <- endsWith(entry, "/")
      name      <- sub("/$", "", entry)
      is_last   <- (i == length(entries))

      lines <<- c(lines, paste0(prefix, tree_chars$branch, entry))

      if (is_folder) {
        # Reason: build full sub-path by appending folder name to current path
        sub_path   <- paste0(p, name, "/")
        new_prefix <- paste0(prefix, if (is_last) tree_chars$space else tree_chars$pipe)
        traverse(sub_path, depth + 1, new_prefix)
      }
    }
  }

  traverse(norm)

  if (verbose) {
    display <- if (nzchar(norm)) norm else "/"
    message("Remote: ", display)
    for (line in lines) message(line)
  }

  invisible(lines)
}
