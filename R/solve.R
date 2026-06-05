#' @include internal.R
#'
#' @title Solve a planning problem
#'
#' @description
#' Solve a planning problem stored in a \code{Problem} object.
#'
#' This is the main execution step of the \pkg{multiscape} workflow. It reads
#' the problem specification stored in a \code{Problem} object, builds the
#' corresponding optimization model when needed, applies the configured solver
#' settings, and returns a \code{\link{solutionset-class}} object.
#'
#' A \code{SolutionSet} is the standard result object returned by
#' \code{solve()}. Single-objective workflows are represented as one-run
#' \code{SolutionSet} objects, while multi-objective workflows are represented
#' as multi-run \code{SolutionSet} objects.
#'
#' @details
#' \strong{Role of \code{solve()}}
#'
#' The typical \pkg{multiscape} workflow is:
#' \preformatted{
#' x <- create_problem(...)
#' x <- add_...(x, ...)
#' x <- set_...(x, ...)
#' res <- solve(x)
#' }
#'
#' Thus, \code{solve()} is the stage at which the stored problem specification
#' is turned into one or more optimization runs.
#'
#' For most users, \code{solve()} is the standard execution entry point.
#' Explicit compilation with \code{\link{compile_model}} is optional and is
#' mainly useful for advanced inspection or debugging workflows.
#'
#' \strong{What \code{solve()} uses from the problem object}
#'
#' The function uses the information already stored in the \code{Problem}
#' object, including:
#' \itemize{
#'   \item baseline planning data;
#'   \item actions, effects, profit, and spatial relations;
#'   \item targets and constraints;
#'   \item registered objectives;
#'   \item an optional multi-objective method configuration;
#'   \item solver settings.
#' }
#'
#' If a model has not yet been built, it is built internally during the solve
#' process. If a model snapshot or pointer already exists, the solving layer may
#' reuse or refresh it depending on the internal model state.
#'
#' \strong{Single-objective and multi-objective behaviour}
#'
#' \code{solve()} always returns a \code{\link{solutionset-class}} object.
#'
#' \itemize{
#'   \item \strong{Single-objective case.} If exactly one objective is active
#'   and no multi-objective method is configured, \code{solve()} runs a single
#'   optimization problem and returns a one-run \code{SolutionSet}.
#'
#'   \item \strong{Multi-objective case.} If a multi-objective method is
#'   configured, \code{solve()} dispatches internally according to the stored
#'   method name and returns a multi-run \code{SolutionSet}.
#' }
#'
#' This unified output structure makes it possible to use the same inspection,
#' plotting, and analysis functions regardless of whether the original problem
#' was single-objective or multi-objective.
#'
#' Currently supported multi-objective method names are:
#' \itemize{
#'   \item \code{"weighted"};
#'   \item \code{"epsilon_constraint"};
#'   \item \code{"augmecon"}.
#' }
#'
#' \strong{Consistency rule}
#'
#' If multiple objectives are registered but no multi-objective method has been
#' selected, \code{solve()} stops with an error. In practical terms:
#'
#' \itemize{
#'   \item one objective and no multi-objective method
#'   \eqn{\Rightarrow} single-objective solve;
#'   \item multiple objectives and a valid multi-objective method
#'   \eqn{\Rightarrow} multi-objective solve;
#'   \item multiple objectives and no multi-objective method
#'   \eqn{\Rightarrow} error.
#' }
#'
#' \strong{Implicit conservation-planning model}
#'
#' If no explicit actions and no explicit effects are provided, \code{solve()}
#' can build the corresponding classical conservation-planning formulation
#' internally. In this case, selecting a planning unit is interpreted as applying
#' an implicit conservation action, and the baseline feature amounts stored in
#' \code{dist_features} count toward representation targets.
#'
#' This allows standard reserve-selection problems to be solved without
#' requiring users to manually define actions and effects. Explicit
#' action-based workflows remain available by using \code{\link{add_actions}}
#' and \code{\link{add_effects}}.
#'
#' \strong{Solver settings}
#'
#' Solver configuration is read from the \code{Problem} object, typically after
#' calling \code{\link{set_solver}} or one of its convenience wrappers such as
#' \code{\link{set_solver_gurobi}} or \code{\link{set_solver_cbc}}.
#'
#' These settings may include:
#' \itemize{
#'   \item the selected backend;
#'   \item time limits;
#'   \item optimality-gap settings;
#'   \item CPU cores;
#'   \item verbosity options;
#'   \item backend-specific solver parameters.
#' }
#'
#' \strong{Method dispatch}
#'
#' \code{solve()} is an S3 generic. The public method documented here is
#' \code{solve.Problem()}, which operates on \code{Problem} objects.
#'
#' @param x A \code{Problem} object created with \code{\link{create_problem}}
#'   and optionally enriched with actions, effects, targets, constraints,
#'   objectives, spatial relations, method settings, and solver settings.
#'
#' @param ... Additional arguments reserved for internal or legacy solver
#'   handling. These are not part of the main recommended user interface.
#'
#' @return
#' A \code{\link{solutionset-class}} object.
#'
#' The returned object contains run-level information, solver diagnostics,
#' objective values, and stored optimization outputs. For single-objective
#' problems, the returned \code{SolutionSet} contains one run. For
#' multi-objective workflows, it contains one or more runs generated by the
#' selected method.
#'
#' Users will typically inspect or visualize results using accessor and plotting
#' functions such as \code{\link{get_pu}}, \code{\link{get_actions}},
#' \code{\link{get_features}}, \code{\link{get_targets}}, and
#' \code{\link{plot_tradeoff}}.
#'
#' @examples
#' # ------------------------------------------------------------
#' # Minimal single-objective example
#' # ------------------------------------------------------------
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
#' x <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   x <- set_solver_cbc(x, verbose = FALSE)
#'   solset <- solve(x)
#'   print(solset)
#' }
#'
#' # ------------------------------------------------------------
#' # Minimal action-based example
#' # ------------------------------------------------------------
#' actions <- data.frame(
#'   id = c("conservation", "restoration")
#' )
#'
#' effects <- data.frame(
#'   action = rep(c("conservation", "restoration"), each = 2),
#'   feature = rep(features$id, times = 2),
#'   multiplier = c(1.00, 1.00, 1.50, 1.50)
#' )
#'
#' x_actions <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     actions = actions,
#'     cost = c(conservation = 1, restoration = 2)
#'   ) |>
#'   add_effects(
#'     effects = effects,
#'     effect_type = "after"
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   x_actions <- set_solver_cbc(x_actions, verbose = FALSE)
#'   solset_actions <- solve(x_actions)
#'   print(solset_actions)
#' }
#'
#' # ------------------------------------------------------------
#' # Minimal multi-objective example
#' # ------------------------------------------------------------
#' x_mo <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_max_benefit(alias = "benefit") |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     weights = c(0.5, 0.5),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   x_mo <- set_solver_cbc(x_mo, verbose = FALSE)
#'   solset_mo <- solve(x_mo)
#'   print(solset_mo)
#' }
#'
#' @seealso
#' \code{\link{problem-class}},
#' \code{\link{solutionset-class}},
#' \code{\link{compile_model}},
#' \code{\link{set_solver}},
#' \code{\link{set_solver_cbc}},
#' \code{\link{set_solver_gurobi}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{add_actions}},
#' \code{\link{add_effects}}
#'
#' @export
solve <- function(x, ...) {
  UseMethod("solve")
}

#' @rdname solve
#' @export
solve.Problem <- function(x, ...) {

  assertthat::assert_that(inherits(x, "Problem"))

  objs <- x$data$objectives %||% list()
  n_obj <- if (is.list(objs)) length(objs) else 0L

  method <- x$data$method %||% NULL
  has_method <- is.list(method) && length(method) > 0L

  if (has_method) {
    method_name <- as.character(method$type %||% method$name %||% NA_character_)[1]

    if (is.na(method_name) || !nzchar(method_name)) {
      stop("Invalid multi-objective method configuration: missing method name.", call. = FALSE)
    }

    .pamo_validate_objectives(x)
    #x <- compile_model(x)

    res <- switch(
      method_name,
      weighted = .pamo_solve_weighted(x, ...),
      epsilon_constraint = .pamo_solve_epsilon_constraint(x, ...),
      augmecon = .pamo_solve_augmecon(x, ...),
      stop("Unknown/unsupported multi-objective method: '", method_name, "'.", call. = FALSE)
    )

    if (!inherits(res, "SolutionSet")) {
      stop(
        "Internal error: multi-objective solve did not return a SolutionSet object.\n",
        "Returned class: ", paste(class(res), collapse = ", "),
        call. = FALSE
      )
    }

    return(res)
  }

  if (n_obj > 1L) {
    stop(
      "Multiple objectives are registered but no multi-objective method was selected.\n",
      "Use set_method_weighted_sum(), set_method_epsilon_constraint(), etc.",
      call. = FALSE
    )
  }

  x <- compile_model(x)
  res <- .pa_solve_single_problem(x, ...)

  if (!inherits(res, "Solution")) {
    stop(
      "Internal error: single-objective solve did not return a Solution object.\n",
      "Returned class: ", paste(class(res), collapse = ", "),
      call. = FALSE
    )
  }

  res <- .pa_as_single_solution_set(
    sol = res,
    problem = x,
    name = "solset"
  )

  if (!inherits(res, "SolutionSet")) {
    stop(
      "Internal error: single-objective solve could not be wrapped as a SolutionSet object.\n",
      "Returned class: ", paste(class(res), collapse = ", "),
      call. = FALSE
    )
  }

  res
}
