#' @include internalMO.R
#'
#' @title Configure the weighted-sum multi-objective method
#'
#' @description
#' Combine two or more registered objectives using alternative non-negative
#' weights. Each weight combination defines one optimisation run, allowing
#' users to explore trade-offs between objectives such as implementation cost
#' and ecological improvement.
#'
#' @details
#' First, register at least two objectives with distinct \code{alias} values.
#' The \code{aliases} argument selects which objectives to combine. For each
#' run, \pkg{multiscape} constructs a weighted scalar criterion and solves the
#' resulting mixed-integer optimisation problem.
#'
#' If \eqn{f_k(x)} is a registered objective and \eqn{w_k \ge 0} is its weight,
#' the scalarisation combines terms of the form \eqn{w_k f_k(x)}. Minimisation
#' and maximisation directions are reconciled internally: larger values remain
#' preferable for maximisation objectives, smaller values for minimisation
#' objectives. Weights express preferences, not objective values or targets.
#'
#' \strong{Selecting weights.} Use \code{runs = set_runs_grid(n = 5)} to
#' generate five combinations for two objectives, including the two single-
#' objective extremes. Use \code{set_runs_manual()} to provide exact weights
#' in columns named \code{weight_<alias>}; each row is a separate run.
#'
#' \strong{Normalisation versus objective scaling.} \code{normalize_weights}
#' rescales the weights within each run to sum to one. By default, grid weights
#' are normalised, whereas manual weights are retained as supplied. This does
#' not make objectives with different units numerically comparable.
#' \code{objective_scaling = TRUE} instead requests scaling of the objective
#' values before aggregation, so the preferences are less sensitive to their
#' numerical ranges. The scaling is performed when solving; reported objective
#' values retain their original units.
#'
#' \strong{Interpreting solutions.} Different weights can produce the same
#' spatial plan, particularly in discrete optimisation problems. Weighted sums
#' generally recover supported efficient solutions; they need not find all
#' non-dominated solutions of a non-convex frontier. For a more systematic
#' exploration, consider \code{set_method_epsilon_constraint()} or
#' \code{set_method_augmecon()}. Zero-weight runs may also have ties that are
#' not resolved with respect to the omitted objective.
#'
#' The \code{control} argument specifies how to handle unsuccessful runs. A
#' problem can have only one configured multi-objective method; to compare
#' methods or weight designs, begin from the same problem before calling a
#' \code{set_method_*()} function. The deprecated \code{weights} argument is
#' still accepted for compatibility, but \code{runs} is recommended.
#'
#' @param x A \code{Problem} with at least two registered objective aliases.
#' @param aliases Character vector of at least two distinct objective aliases.
#' @param runs A run design from \code{set_runs_grid()} or
#'   \code{set_runs_manual()}. Manual designs contain columns named
#'   \code{weight_<alias>} for each selected objective.
#' @param weights Deprecated numeric weight vector, in \code{aliases} order.
#'   Use \code{runs = set_runs_manual(...)} instead.
#' @param normalize_weights Logical or \code{NULL}. With \code{NULL}, use
#'   \code{TRUE} for a grid and \code{FALSE} for manual weights.
#' @param objective_scaling Logical. Request scaling of objective values before
#'   weighted aggregation. The default is \code{FALSE}.
#' @param control Optional run-failure settings from \code{set_runs_control()}.
#'
#' @return An updated \code{Problem} with the method stored in
#'   \code{x$data$method}. The optimisation runs are executed by \code{solve()}.
#'
#' @examples
#' # EXAMPLE: Trade off management costs against woodland improvement.
#' # The simulated landscape has 64 planning units and two possible actions.
#' sim <- load_sim_multiaction()
#'
#' base <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(sim$actions, cost = sim$action_costs) |>
#'   add_effects(sim$effect_assumptions) |>
#'   # Require some improvement, so the cheapest plan is not empty.
#'   add_constraint_targets_relative(0.05, features = "woodland") |>
#'   add_objective_min_cost(
#'     include_pu_cost = FALSE, alias = "cost"
#'   ) |>
#'   add_objective_max_effect(
#'     features = "woodland", alias = "woodland"
#'   )
#'
#' # Five different preferences, from cost-only to woodland-only.
#' weighted <- set_method_weighted_sum(
#'   base,
#'   aliases = c("cost", "woodland"),
#'   runs = set_runs_grid(n = 5),
#'   objective_scaling = TRUE
#' )
#'
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(
#'     set_solver_cbc(weighted, time_limit = 30, verbose = FALSE)
#'   )
#'
#'   # Inspect the original objective values across runs.
#'   get_objectives(solutions, format = "wide")
#'
#'   # Explore the observed cost-improvement trade-off.
#'   plot_tradeoff(
#'     solutions, objectives = c("cost", "woodland"),
#'     label_runs = TRUE
#'   )
#'
#'   # Compare three spatial prescriptions in the same figure.
#'   # These are preferences, not necessarily three distinct plans.
#'   plot_spatial_actions(
#'     solutions, solutions = c(1, 3, 5), layout = "single", ncol = 3
#'   )
#' }
#'
#' # ALTERNATIVE: supply three explicit weight combinations.
#' # Reuse 'base', because a Problem can have only one method.
#' manual <- set_method_weighted_sum(
#'   base,
#'   aliases = c("cost", "woodland"),
#'   runs = set_runs_manual(data.frame(
#'     weight_cost = c(1, 0.5, 0),
#'     weight_woodland = c(0, 0.5, 1)
#'   )),
#'   objective_scaling = TRUE
#' )
#'
#' @references
#' Ehrgott, M. (2005). \emph{Multicriteria Optimization}, 2nd ed.
#' Springer. \doi{10.1007/3-540-27659-9}.
#'
#' Miettinen, K. (1998). \emph{Nonlinear Multiobjective Optimization}.
#' Kluwer Academic Publishers. \doi{10.1007/978-1-4615-5563-6}.
#'
#' @seealso
#' \code{\link{set_runs_grid}}, \code{\link{set_runs_manual}},
#' \code{\link{set_runs_control}}, \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}}, \code{\link{plot_tradeoff}},
#' \code{\link{plot_spatial_actions}}, \code{\link{solve}}

#' @export
set_method_weighted_sum <- function(x,
                                    aliases,
                                    runs = NULL,
                                    weights = NULL,
                                    normalize_weights = NULL,
                                    objective_scaling = FALSE,
                                    control = NULL) {
  stopifnot(inherits(x, "Problem"))
  .pa_assert_unconfigured(x, "method", "Multi-objective method", "set_method_*()")

  if (exists(".pa_clone_data", mode = "function")) {
    x <- .pa_clone_data(x)
  }

  # ---- aliases
  if (
    !is.character(aliases) ||
    length(aliases) < 2L ||
    anyNA(aliases)
  ) {
    stop(
      paste0(
        "`aliases` must be a character vector with at least ",
        "two objective aliases."
      ),
      call. = FALSE
    )
  }

  aliases <- as.character(aliases)

  if (any(!nzchar(aliases))) {
    stop(
      "`aliases` must not contain empty strings.",
      call. = FALSE
    )
  }

  if (anyDuplicated(aliases) != 0L) {
    duplicates <- unique(
      aliases[duplicated(aliases)]
    )

    stop(
      "`aliases` must not contain duplicates: ",
      paste(duplicates, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  .pamo_get_objective_specs(
    x,
    aliases
  )

  # ---- objective scaling
  if (
    !is.logical(objective_scaling) ||
    length(objective_scaling) != 1L ||
    is.na(objective_scaling)
  ) {
    stop(
      "`objective_scaling` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  # ---- backwards compatibility: weights -> set_runs_manual()
  if (!is.null(weights)) {
    if (!is.null(runs)) {
      stop(
        "Use only one of `runs` or deprecated `weights`.",
        call. = FALSE
      )
    }

    .pa_deprecate_arg(
      old = "weights",
      new = "runs = set_runs_manual(data.frame(weight_<alias> = ...))"
    )

    if (
      !is.numeric(weights) ||
      length(weights) != length(aliases) ||
      anyNA(weights)
    ) {
      stop(
        paste0(
          "`weights` must be a numeric vector with the same length ",
          "as `aliases` and without missing values."
        ),
        call. = FALSE
      )
    }

    weights <- as.numeric(weights)

    if (any(!is.finite(weights))) {
      stop(
        "`weights` must contain only finite values.",
        call. = FALSE
      )
    }

    if (any(weights < 0)) {
      stop(
        "`weights` must be non-negative.",
        call. = FALSE
      )
    }

    if (sum(weights) <= 0) {
      stop(
        "`weights` must assign a positive total weight.",
        call. = FALSE
      )
    }

    # Do not include run_id here. run_id is assigned when the design is
    # resolved; it is not part of the user-supplied manual weight table.
    weight_df <- stats::setNames(
      as.data.frame(
        as.list(weights),
        stringsAsFactors = FALSE,
        check.names = FALSE
      ),
      paste0("weight_", aliases)
    )

    runs <- set_runs_manual(weight_df)
  }

  if (is.null(runs)) {
    stop(
      paste0(
        "`runs` must be supplied. Use `runs = set_runs_grid(n = ...)` ",
        "or `runs = set_runs_manual(...)`."
      ),
      call. = FALSE
    )
  }

  .pamo_check_run_design(runs)

  # Resolve the default after the run design is known.
  #
  # Automatic grids are already generated over a normalized simplex and should
  # be treated as normalized by default. Manual runs should use exactly the
  # weights supplied by the user unless normalization is explicitly requested.
  if (is.null(normalize_weights)) {
    normalize_weights <- !.pamo_is_run_manual(runs)
  }

  if (
    !is.logical(normalize_weights) ||
    length(normalize_weights) != 1L ||
    is.na(normalize_weights)
  ) {
    stop(
      "`normalize_weights` must be TRUE, FALSE, or NULL.",
      call. = FALSE
    )
  }

  # Validate manual columns only after the selected aliases and normalization
  # behaviour are known.
  .pamo_validate_manual_weight_design(
    runs = runs,
    aliases = aliases,
    normalize_weights = normalize_weights
  )

  # ---- control
  control <- .pamo_check_mo_control(control)

  x$data$method <- list(
    name = "weighted",
    type = "weighted",
    aliases = aliases,
    runs = runs,
    normalize_weights = isTRUE(normalize_weights),
    objective_scaling = isTRUE(objective_scaling),
    control = control,
    stop_on_infeasible = control$stop_on_infeasible,
    stop_on_no_solution = control$stop_on_no_solution,
    stop_on_error = control$stop_on_error
  )

  x
}


#' Validate a manual weighted-sum design
#'
#' @param runs A \code{RunManual} object.
#' @param aliases Character vector of objective aliases.
#' @param normalize_weights Logical indicating whether rows will be normalized.
#'
#' @return Invisibly returns \code{TRUE}.
#'
#' @noRd
.pamo_validate_manual_weight_design <- function(
    runs,
    aliases,
    normalize_weights = TRUE
) {
  if (!.pamo_is_run_manual(runs)) {
    return(invisible(TRUE))
  }

  if (
    is.null(runs$values) ||
    !inherits(runs$values, "data.frame") ||
    nrow(runs$values) == 0L
  ) {
    stop(
      "Invalid manual weighted-sum design: no run rows are available.",
      call. = FALSE
    )
  }

  required_columns <- paste0("weight_", aliases)

  supplied_weight_columns <- grep(
    "^weight_",
    names(runs$values),
    value = TRUE
  )

  missing_columns <- setdiff(
    required_columns,
    supplied_weight_columns
  )

  if (length(missing_columns) > 0L) {
    stop(
      "Manual weighted-sum design is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unknown_weight_columns <- setdiff(
    supplied_weight_columns,
    required_columns
  )

  if (length(unknown_weight_columns) > 0L) {
    stop(
      "Manual weighted-sum design contains unknown weight column(s): ",
      paste(unknown_weight_columns, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unsupported_columns <- setdiff(
    names(runs$values),
    required_columns
  )

  if (length(unsupported_columns) > 0L) {
    stop(
      "Manual weighted-sum design contains unsupported column(s): ",
      paste(unsupported_columns, collapse = ", "),
      ". Only columns named `weight_<alias>` are allowed.",
      call. = FALSE
    )
  }

  non_numeric <- required_columns[
    !vapply(
      runs$values[required_columns],
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric) > 0L) {
    stop(
      "Manual weight column(s) must be numeric: ",
      paste(non_numeric, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  weight_matrix <- as.matrix(
    runs$values[, required_columns, drop = FALSE]
  )

  storage.mode(weight_matrix) <- "double"

  if (anyNA(weight_matrix)) {
    stop(
      "Manual weight columns must not contain missing values.",
      call. = FALSE
    )
  }

  if (any(!is.finite(weight_matrix))) {
    stop(
      "Manual weights must contain only finite values.",
      call. = FALSE
    )
  }

  if (any(weight_matrix < 0)) {
    stop(
      "Manual weights must be non-negative.",
      call. = FALSE
    )
  }

  totals <- rowSums(weight_matrix)

  if (any(totals <= 0)) {
    bad_rows <- which(totals <= 0)

    stop(
      "Each manual weighted-sum run must assign a positive total weight. ",
      "Invalid row(s): ",
      paste(bad_rows, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}
