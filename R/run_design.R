#' @title Define an automatic run grid
#'
#' @description
#' Create a run-design specification for automatically generating multiple
#' optimization runs in multi-objective methods.
#'
#' The meaning of the grid depends on the method:
#' \itemize{
#'   \item in weighted-sum methods, it defines a grid of weight combinations;
#'   \item in epsilon-constraint methods, it defines epsilon levels;
#'   \item in AUGMECON, it defines epsilon levels for secondary objectives.
#' }
#'
#' @param n Integer. Grid resolution.
#' @param include_extremes Logical. Whether to include extreme values.
#'
#' @return An object of class \code{RunGrid}.
#'
#' @export
run_grid <- function(n, include_extremes = TRUE) {
  n <- as.integer(n)[1]

  if (!is.finite(n) || is.na(n) || n < 2L) {
    stop("`n` must be an integer >= 2.", call. = FALSE)
  }

  if (!is.logical(include_extremes) ||
      length(include_extremes) != 1L ||
      is.na(include_extremes)) {
    stop("`include_extremes` must be TRUE or FALSE.", call. = FALSE)
  }

  structure(
    list(
      type = "grid",
      n = n,
      include_extremes = isTRUE(include_extremes)
    ),
    class = c("RunGrid", "RunDesign")
  )
}


#' @title Define a manual run design
#'
#' @description
#' Create a manual run-design specification. Each row represents one
#' optimization run. Required columns depend on the method.
#'
#' For weighted-sum methods, columns must be named \code{weight_<alias>}.
#' For epsilon-constraint and AUGMECON methods, columns must be named
#' \code{eps_<alias>}.
#'
#' @param x A \code{data.frame} with one row per run.
#'
#' @return An object of class \code{RunManual}.
#'
#' @export
run_manual <- function(x) {
  if (is.null(x) || !inherits(x, "data.frame")) {
    stop("`x` must be a data.frame.", call. = FALSE)
  }

  if (nrow(x) == 0L) {
    stop("`x` must contain at least one row.", call. = FALSE)
  }

  structure(
    list(
      type = "manual",
      values = as.data.frame(x, stringsAsFactors = FALSE)
    ),
    class = c("RunManual", "RunDesign")
  )
}


# -------------------------------------------------------------------------
# Internal helpers
# -------------------------------------------------------------------------

.pamo_is_run_design <- function(x) {
  inherits(x, "RunDesign")
}

.pamo_is_run_grid <- function(x) {
  inherits(x, "RunGrid")
}

.pamo_is_run_manual <- function(x) {
  inherits(x, "RunManual")
}

.pamo_check_run_design <- function(x) {
  if (!.pamo_is_run_design(x)) {
    stop(
      "`runs` must be created with `run_grid()` or `run_manual()`.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}
