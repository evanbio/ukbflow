# =============================================================================
# fetch.R — Remote RAP file system exploration
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
#' fetch_ls("Bulk/Exome sequences/")
#' fetch_ls("Bulk/", type = "folder")
#' fetch_ls("Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/",
#'          pattern = "\\.bed$")
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
