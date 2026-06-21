#' Define an automatic multi-objective run grid
#'
#' @description
#' Create an automatic run-design specification for generating multiple
#' optimization runs in a multi-objective workflow.
#'
#' \code{set_runs_grid()} provides a common interface for controlling the
#' resolution of weighted-sum, epsilon-constraint, and AUGMECON run designs.
#' The returned object does not contain the final run table. Instead, it stores
#' the requested grid resolution, which is resolved later by the corresponding
#' \code{set_method_*()} function using the registered objectives and their
#' optimization senses.
#'
#' @details
#' Multi-objective methods generally require several optimization runs to
#' explore different regions of objective space. \code{set_runs_grid()} asks
#' \pkg{multiscape} to generate those runs automatically from a grid.
#'
#' The interpretation of the grid depends on the selected method:
#'
#' \itemize{
#'   \item In \code{\link{set_method_weighted_sum}}, the grid defines
#'   combinations of objective weights. For two objectives, \code{n} gives the
#'   number of weight combinations between the two pure-objective extremes. For
#'   three or more objectives, \code{n} controls the resolution of the generated
#'   simplex grid. The generated weights are normalized according to the method
#'   settings and represent alternative preferences among the registered
#'   objectives.
#'
#'   \item In \code{\link{set_method_epsilon_constraint}}, the grid defines
#'   epsilon levels for the constrained objective. The primary objective is
#'   optimized directly, while the remaining objective is progressively
#'   restricted across the generated runs.
#'
#'   \item In \code{\link{set_method_augmecon}}, the grid defines epsilon
#'   levels for the secondary objectives, which are then used in the augmented
#'   epsilon-constraint formulation. When several secondary objectives are used,
#'   the final run design is obtained by combining the generated epsilon levels
#'   across objectives.
#' }
#'
#' The argument \code{n} controls the resolution of the automatically generated
#' design. It should not always be interpreted as the final number of runs.
#' For example, when several secondary objectives are present, epsilon levels
#' may be combined across objectives and generate more runs than the value
#' supplied to \code{n}. Likewise, the number of valid weighted combinations
#' depends on the number of objectives and on how the weight grid is
#' constructed.
#'
#' Boundary levels are always included. For weighted-sum methods, this means
#' that pure-objective weight vectors are included, where all weight is assigned
#' to one objective. For epsilon-constraint and AUGMECON methods, this means
#' that the lower and upper bounds of the automatically derived epsilon ranges
#' are included.
#'
#' Including boundary levels helps recover the best observed value of each
#' objective and provides reference points for subsequent frontier analyses.
#'
#' The resolved design is stored in the resulting
#' \code{\link{solutionset-class}} object and can be inspected after solving
#' through \code{\link{get_runs}}.
#'
#' Use \code{\link{set_runs_manual}} instead when exact weights or epsilon levels
#' must be supplied explicitly.
#'
#' @param n Integer. Resolution of the automatically generated run design.
#'   Must be at least \code{2}. The final number of optimization runs may differ
#'   from \code{n}, depending on the selected method and the number of
#'   objectives.
#'
#' @return An object of class \code{RunGrid} and \code{RunDesign}. The object
#'   stores the requested grid resolution and is intended to be supplied to the
#'   \code{runs} argument of a multi-objective method function.
#'
#' @examples
#' # Create an automatic run-grid specification
#' grid <- set_runs_grid(n = 5)
#'
#' grid
#'
#' # Use the automatic grid in a weighted-sum workflow
#' pu <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' features <- data.frame(
#'   id = 1:2,
#'   name = c("sp1", "sp2")
#' )
#'
#' dist_features <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' actions <- data.frame(
#'   id = c("conservation", "restoration")
#' )
#'
#' effects <- data.frame(
#'   action = rep(actions$id, each = 2),
#'   feature = rep(features$id, times = 2),
#'   multiplier = c(
#'     1.0, 1.0,
#'     1.5, 1.5
#'   )
#' )
#'
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     actions = actions,
#'     cost = c(
#'       conservation = 1,
#'       restoration = 2
#'     )
#'   ) |>
#'   add_effects(
#'     effects = effects,
#'     effect_type = "after"
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_max_benefit(alias = "benefit") |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(n = 5),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # Inspect the resolved run design and objective values
#'   get_runs(solutions)
#'   get_objectives(
#'     solutions,
#'     format = "wide"
#'   )
#' }
#'
#' @seealso
#' \code{\link{set_runs_manual}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{get_runs}}
#'
#' @export
set_runs_grid <- function(n) {
  n <- as.integer(n)[1]

  if (!is.finite(n) || is.na(n) || n < 2L) {
    stop("`n` must be an integer >= 2.", call. = FALSE)
  }

  structure(
    list(
      type = "grid",
      n = n,
      include_extremes = TRUE
    ),
    class = c("RunGrid", "RunDesign")
  )
}


#' Define an automatic multi-objective run grid
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' \code{run_grid()} has been replaced by \code{\link{set_runs_grid}}.
#'
#' The argument \code{include_extremes} is deprecated and ignored. Boundary
#' levels are now always included.
#'
#' @param n Integer. Resolution of the automatically generated run design.
#'   Must be at least \code{2}.
#' @param include_extremes Deprecated. Boundary levels are now always included.
#'
#' @return An object of class \code{RunGrid} and \code{RunDesign}.
#'
#' @seealso
#' \code{\link{set_runs_grid}}
#'
#' @export
run_grid <- function(n, include_extremes = TRUE) {
  lifecycle::deprecate_warn(
    "1.1.0",
    "run_grid()",
    "set_runs_grid()"
  )

  if (!isTRUE(include_extremes)) {
    lifecycle::deprecate_warn(
      "1.1.0",
      "run_grid(include_extremes = )",
      details = paste0(
        "Boundary levels are now always included. ",
        "The `include_extremes` argument is ignored."
      )
    )
  }

  set_runs_grid(n = n)
}

#' Define a manual multi-objective run design
#'
#' @description
#' Create an explicit run-design specification in which each row defines one
#' multi-objective optimization run.
#'
#' \code{set_runs_manual()} is used when exact objective weights or epsilon
#' levels should be supplied by the user instead of being generated
#' automatically with \code{\link{set_runs_grid}}.
#'
#' @details
#' The input must be a non-empty \code{data.frame} with one row per requested
#' optimization run.
#'
#' Weighted-sum columns must follow the convention:
#'
#' \preformatted{
#' weight_<alias>
#' }
#'
#' Epsilon-constraint and AUGMECON columns must follow the convention:
#'
#' \preformatted{
#' eps_<alias>
#' }
#'
#' A manual design must contain at least one column beginning with
#' \code{weight_} or \code{eps_}. Mixing both column families in the same
#' design is not allowed.
#'
#' All run-design columns must be numeric, finite, and free of missing values.
#' Weight columns must contain non-negative values, and each weighted-sum row
#' must assign a strictly positive total weight.
#'
#' This function performs method-independent structural validation.
#' Method-specific validation is performed later by the corresponding
#' \code{set_method_*()} function. This includes checking:
#'
#' \itemize{
#'   \item that all required objective aliases are represented;
#'   \item that no unknown objective columns are supplied;
#'   \item that epsilon columns correspond only to secondary objectives;
#'   \item and that the supplied design is compatible with the selected method.
#' }
#'
#' Therefore, an object may be structurally valid for
#' \code{set_runs_manual()} but rejected later by
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}}, or
#' \code{\link{set_method_augmecon}}.
#'
#' @param x A non-empty \code{data.frame} with one row per optimization run.
#'   Run-design columns must be named using the \code{weight_<alias>} or
#'   \code{eps_<alias>} convention.
#'
#' @return An object of class \code{RunManual} and \code{RunDesign} containing
#'   the validated run table.
#'
#' @examples
#' weighted_runs <- set_runs_manual(
#'   data.frame(
#'     weight_cost = c(1.0, 0.5, 0.0),
#'     weight_benefit = c(0.0, 0.5, 1.0)
#'   )
#' )
#'
#' epsilon_runs <- set_runs_manual(
#'   data.frame(
#'     eps_benefit = c(2, 4, 6, 8)
#'   )
#' )
#'
#' weighted_runs
#' epsilon_runs
#'
#' @seealso
#' \code{\link{set_runs_grid}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}}
#'
#' @export
set_runs_manual <- function(x) {
  if (is.null(x) || !inherits(x, "data.frame")) {
    stop(
      "`x` must be a data.frame.",
      call. = FALSE
    )
  }

  if (nrow(x) == 0L) {
    stop(
      "`x` must contain at least one row.",
      call. = FALSE
    )
  }

  if (ncol(x) == 0L) {
    stop(
      "`x` must contain at least one run-design column.",
      call. = FALSE
    )
  }

  column_names <- names(x)

  if (
    is.null(column_names) ||
    anyNA(column_names) ||
    any(!nzchar(column_names))
  ) {
    stop(
      "All columns in `x` must have non-empty names.",
      call. = FALSE
    )
  }

  if (anyDuplicated(column_names) > 0L) {
    duplicated_names <- unique(
      column_names[duplicated(column_names)]
    )

    stop(
      "Duplicated run-design column name(s): ",
      paste(duplicated_names, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  weight_columns <- grep(
    "^weight_.+",
    column_names,
    value = TRUE
  )

  epsilon_columns <- grep(
    "^eps_.+",
    column_names,
    value = TRUE
  )

  if (
    length(weight_columns) == 0L &&
    length(epsilon_columns) == 0L
  ) {
    stop(
      paste0(
        "`x` must contain at least one column named ",
        "`weight_<alias>` or `eps_<alias>`."
      ),
      call. = FALSE
    )
  }

  if (
    length(weight_columns) > 0L &&
    length(epsilon_columns) > 0L
  ) {
    stop(
      paste0(
        "A manual run design cannot mix `weight_*` and `eps_*` ",
        "columns."
      ),
      call. = FALSE
    )
  }

  design_columns <- c(
    weight_columns,
    epsilon_columns
  )

  additional_columns <- setdiff(
    column_names,
    design_columns
  )

  if (length(additional_columns) > 0L) {
    stop(
      "Unknown run-design column(s): ",
      paste(additional_columns, collapse = ", "),
      ". Columns must follow the `weight_<alias>` or `eps_<alias>` convention.",
      call. = FALSE
    )
  }

  non_numeric <- design_columns[
    !vapply(
      x[design_columns],
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric) > 0L) {
    stop(
      "Run-design column(s) must be numeric: ",
      paste(non_numeric, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  values <- as.matrix(
    x[, design_columns, drop = FALSE]
  )

  storage.mode(values) <- "double"

  if (anyNA(values)) {
    stop(
      "Run-design columns must not contain missing values.",
      call. = FALSE
    )
  }

  if (any(!is.finite(values))) {
    stop(
      "Run-design columns must contain only finite values.",
      call. = FALSE
    )
  }

  if (length(weight_columns) > 0L) {
    weight_values <- values[
      ,
      weight_columns,
      drop = FALSE
    ]

    if (any(weight_values < 0)) {
      stop(
        "Manual weights must be non-negative.",
        call. = FALSE
      )
    }

    if (any(rowSums(weight_values) <= 0)) {
      stop(
        paste0(
          "Each manual weighted-sum run must assign a ",
          "strictly positive total weight."
        ),
        call. = FALSE
      )
    }
  }

  structure(
    list(
      type = "manual",
      values = as.data.frame(
        x,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    ),
    class = c("RunManual", "RunDesign")
  )
}


#' Define a manual multi-objective run design
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' \code{run_manual()} has been replaced by \code{\link{set_runs_manual}}.
#'
#' @inheritParams set_runs_manual
#'
#' @return An object of class \code{RunManual} and \code{RunDesign}.
#'
#' @seealso
#' \code{\link{set_runs_manual}}
#'
#' @export
run_manual <- function(x) {
  lifecycle::deprecate_warn(
    "1.1.0",
    "run_manual()",
    "set_runs_manual()"
  )

  set_runs_manual(x = x)
}



#' Control multi-objective run behavior
#'
#' @description
#' Create a control object that determines how multi-objective workflows respond
#' to infeasible runs, missing solution vectors, and unexpected errors.
#'
#' The resulting object is supplied to the \code{control} argument of
#' \code{\link{set_method_epsilon_constraint}} or
#' \code{\link{set_method_augmecon}}.
#'
#' @details
#' Multi-objective methods commonly solve a sequence of related optimization
#' models. Some parameter combinations, particularly restrictive epsilon
#' levels, may be infeasible or may fail to produce a usable solution.
#'
#' \code{set_runs_control()} determines whether such events stop the entire
#' multi-objective workflow or are recorded in the resulting
#' \code{\link{solutionset-class}} object.
#'
#' A \code{SolutionSet} distinguishes between:
#'
#' \itemize{
#'   \item a \code{run_id}, which identifies every attempted optimization run;
#'   \item a \code{solution_id}, which is assigned only when a run produces a
#'   stored solution.
#' }
#'
#' When a run is retained after an infeasibility or missing-solution event, its
#' run-level metadata remains available through \code{\link{get_runs}}, but its
#' \code{solution_id} and objective values will generally be missing.
#'
#' \strong{Infeasible runs}
#'
#' If \code{stop_on_infeasible = FALSE}, an infeasible run is recorded and the
#' workflow continues with the remaining run design. This is generally useful
#' when exploring automatically generated epsilon grids because restrictive
#' combinations of epsilon levels may be infeasible.
#'
#' If \code{stop_on_infeasible = TRUE}, the workflow stops when the first
#' infeasible run is encountered.
#'
#' \strong{Runs without a solution vector}
#'
#' A solver may terminate without returning a usable decision vector even when
#' the outcome is not classified explicitly as infeasible.
#'
#' If \code{stop_on_no_solution = FALSE}, the attempted run is recorded without
#' a stored solution and the remaining runs are attempted. If
#' \code{stop_on_no_solution = TRUE}, the workflow stops immediately.
#'
#' \strong{Unexpected errors}
#'
#' If \code{stop_on_error = TRUE}, unexpected errors raised while preparing,
#' solving, or processing a run are propagated and stop the workflow. This is
#' the recommended default because such errors may indicate an invalid model,
#' unsupported solver behaviour, or an internal implementation problem.
#'
#' If \code{stop_on_error = FALSE}, the workflow attempts to record the failed
#' run and continue. This option should be used cautiously because it may conceal
#' modelling or implementation errors.
#'
#' The default settings favour completing the requested run design while still
#' stopping on unexpected errors:
#'
#' \preformatted{
#' stop_on_infeasible = FALSE
#' stop_on_no_solution = FALSE
#' stop_on_error = TRUE
#' }
#'
#' @param stop_on_infeasible Logical. If \code{TRUE}, stop the complete
#'   multi-objective workflow when a run is reported as infeasible. If
#'   \code{FALSE}, retain the attempted run in the run table and continue with
#'   the remaining runs. Defaults to \code{FALSE}.
#'
#' @param stop_on_no_solution Logical. If \code{TRUE}, stop when a run does not
#'   return a usable solution vector. If \code{FALSE}, retain the attempted run
#'   without a stored \code{solution_id} and continue. Defaults to
#'   \code{FALSE}.
#'
#' @param stop_on_error Logical. If \code{TRUE}, stop on unexpected errors
#'   raised during model preparation, solving, or result processing. If
#'   \code{FALSE}, attempt to record the failed run and continue. Defaults to
#'   \code{TRUE}.
#'
#' @return An object of class \code{RunsControl} and \code{MOControl} containing
#'   the validated execution-control settings. The object is intended to be
#'   supplied to the \code{control} argument of a supported multi-objective
#'   method.
#'
#' @examples
#' # Default behaviour: continue after infeasible runs or runs without a
#' # solution, but stop on unexpected errors
#' control <- set_runs_control()
#' control
#'
#' # Stop as soon as an infeasible run or missing solution is encountered
#' strict_control <- set_runs_control(
#'   stop_on_infeasible = TRUE,
#'   stop_on_no_solution = TRUE
#' )
#'
#' strict_control
#'
#' @seealso
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{set_runs_grid}},
#' \code{\link{set_runs_manual}},
#' \code{\link{get_runs}},
#' \code{\link{solutionset-class}}
#'
#' @export
set_runs_control <- function(stop_on_infeasible = FALSE,
                             stop_on_no_solution = FALSE,
                             stop_on_error = TRUE) {

  if (
    !is.logical(stop_on_infeasible) ||
    length(stop_on_infeasible) != 1L ||
    is.na(stop_on_infeasible)
  ) {
    stop(
      "`stop_on_infeasible` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.logical(stop_on_no_solution) ||
    length(stop_on_no_solution) != 1L ||
    is.na(stop_on_no_solution)
  ) {
    stop(
      "`stop_on_no_solution` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.logical(stop_on_error) ||
    length(stop_on_error) != 1L ||
    is.na(stop_on_error)
  ) {
    stop(
      "`stop_on_error` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  structure(
    list(
      stop_on_infeasible = isTRUE(stop_on_infeasible),
      stop_on_no_solution = isTRUE(stop_on_no_solution),
      stop_on_error = isTRUE(stop_on_error)
    ),
    class = c("RunsControl", "MOControl", "list")
  )
}


#' Control multi-objective run behavior
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' \code{mo_control()} has been replaced by \code{\link{set_runs_control}}.
#'
#' The argument \code{slack_upper_bound} is deprecated and ignored. For
#' AUGMECON, use the \code{slack_upper_bound} argument directly in
#' \code{\link{set_method_augmecon}}.
#'
#' @param stop_on_infeasible Logical. If \code{TRUE}, stop the complete
#'   multi-objective workflow when a run is reported as infeasible.
#' @param stop_on_no_solution Logical. If \code{TRUE}, stop when a run does not
#'   return a usable solution vector.
#' @param stop_on_error Logical. If \code{TRUE}, stop on unexpected errors.
#' @param slack_upper_bound Deprecated. Use \code{slack_upper_bound} in
#'   \code{\link{set_method_augmecon}} instead.
#'
#' @return An object of class \code{RunsControl}, \code{MOControl}, and
#'   \code{list}.
#'
#' @seealso
#' \code{\link{set_runs_control}},
#' \code{\link{set_method_augmecon}}
#'
#' @export
mo_control <- function(stop_on_infeasible = FALSE,
                       stop_on_no_solution = FALSE,
                       stop_on_error = TRUE,
                       slack_upper_bound = NULL) {
  lifecycle::deprecate_warn(
    "1.1.0",
    "mo_control()",
    "set_runs_control()"
  )

  if (!is.null(slack_upper_bound)) {
    lifecycle::deprecate_warn(
      "1.1.0",
      "mo_control(slack_upper_bound = )",
      "set_method_augmecon(slack_upper_bound = )"
    )
  }

  set_runs_control(
    stop_on_infeasible = stop_on_infeasible,
    stop_on_no_solution = stop_on_no_solution,
    stop_on_error = stop_on_error
  )
}
