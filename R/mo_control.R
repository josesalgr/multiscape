#' @title Control multi-objective method behavior
#'
#' @description
#' Create a control object for multi-objective methods.
#'
#' @param stop_on_infeasible Logical. If TRUE, stop when a run is infeasible.
#'   If FALSE, keep the run in the SolutionSet with missing objective values.
#' @param stop_on_no_solution Logical. If TRUE, stop when the solver does not
#'   return a solution vector. If FALSE, keep the run in the SolutionSet with
#'   missing objective values.
#' @param stop_on_error Logical. If TRUE, stop on unexpected solver errors.
#' @param slack_upper_bound Positive numeric value used as upper bound for
#'   AUGMECON slack variables.
#'
#' @return An object of class \code{MOControl}.
#'
#' @export
mo_control <- function(stop_on_infeasible = FALSE,
                       stop_on_no_solution = FALSE,
                       stop_on_error = TRUE,
                       slack_upper_bound = 1e6) {

  if (!is.logical(stop_on_infeasible) ||
      length(stop_on_infeasible) != 1L ||
      is.na(stop_on_infeasible)) {
    stop("`stop_on_infeasible` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.logical(stop_on_no_solution) ||
      length(stop_on_no_solution) != 1L ||
      is.na(stop_on_no_solution)) {
    stop("`stop_on_no_solution` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.logical(stop_on_error) ||
      length(stop_on_error) != 1L ||
      is.na(stop_on_error)) {
    stop("`stop_on_error` must be TRUE or FALSE.", call. = FALSE)
  }

  slack_upper_bound <- as.numeric(slack_upper_bound)[1]

  if (!is.finite(slack_upper_bound) || is.na(slack_upper_bound) ||
      slack_upper_bound <= 0) {
    stop("`slack_upper_bound` must be a finite positive number.", call. = FALSE)
  }

  structure(
    list(
      stop_on_infeasible = isTRUE(stop_on_infeasible),
      stop_on_no_solution = isTRUE(stop_on_no_solution),
      stop_on_error = isTRUE(stop_on_error),
      slack_upper_bound = slack_upper_bound
    ),
    class = c("MOControl", "list")
  )
}


.pamo_check_mo_control <- function(control) {
  if (!inherits(control, "MOControl")) {
    stop("`control` must be created with `mo_control()`.", call. = FALSE)
  }

  invisible(TRUE)
}
