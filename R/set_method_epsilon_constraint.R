#' @include internalMO.R
#'
#' @title Configure the epsilon-constraint multi-objective method
#'
#' @description
#' Optimise one registered objective while imposing performance thresholds on
#' the others. By varying these thresholds, the epsilon-constraint method
#' produces alternative spatial plans along an observed trade-off frontier.
#'
#' @details
#' First, register at least two objectives with distinct `alias` values.
#' `primary` identifies the objective to optimise directly; every other alias
#' included in `aliases` becomes an epsilon-constrained objective. For example,
#' maximising woodland improvement while restricting expenditure gives
#' \deqn{\max f_{\mathrm{woodland}}(x)}
#' subject to
#' \deqn{f_{\mathrm{cost}}(x) \le \varepsilon.}
#' For a constrained maximisation objective, the corresponding requirement is
#' a lower bound, \eqn{f_k(x) \ge \varepsilon_k}. Epsilon values are objective
#' values in their original units, not weights or relative preferences.
#'
#' **Automatic grids.** `runs = set_runs_grid(n = 5)` generates five epsilon
#' levels, including the two endpoints, from objective extreme-point or payoff
#' information computed during `solve()`. Automatic grids currently support
#' exactly **two objectives**: one primary and one constrained objective.
#' With `lexicographic = TRUE`, the anchor solutions are refined using the
#' other objective to break near-ties. `lexicographic_tol` controls the allowed
#' deterioration of the first objective during that refinement; it is expressed
#' in that objective's units. This option concerns automatic-grid anchors, not
#' every subsequent epsilon-constrained run.
#'
#' **Automatic warm starts.** Successful solutions are reused as initial
#' candidates for subsequent anchor stages and epsilon runs when supported by
#' the solver (CBC and Gurobi). Automatic grids proceed from the most restrictive
#' secondary bound to the most permissive; manual designs keep their supplied
#' order. A run without a usable solution retains the last successful candidate.
#' This behaviour is internal and requires no additional argument.
#'
#' **Manual thresholds.** Use `runs = set_runs_manual()` to supply explicit
#' bounds. Each row defines one run, with a column named `eps_<alias>` for
#' every constrained objective. For example, `eps_cost = 10` means *cost at
#' most 10*, even if the optimal plan spends less. Manual designs support
#' **two or more objectives**; they do not automatically expand combinations
#' of epsilon levels. Use `expand.grid()` to create such a design explicitly.
#'
#' **Interpreting results.** The method does not guarantee a different plan
#' for each epsilon level, nor does a finite grid enumerate the full Pareto
#' frontier. A basic epsilon-constraint formulation can also produce weakly
#' efficient solutions when an unconstrained secondary objective could improve
#' without worsening the primary objective. For augmented tie-breaking, see
#' `set_method_augmecon()`. Some requested thresholds may be infeasible; use
#' `set_runs_control()` to specify how unsuccessful runs are handled. The
#' returned solution diagnostics include checks of the epsilon bounds.
#'
#' Only one multi-objective method can be configured on a `Problem`. To compare
#' methods or threshold designs, start again from the problem before its
#' method was configured. The older `eps`, `mode`, `n_points`, and
#' `include_extremes` arguments are deprecated; use `runs` instead.
#'
#' @param x A `Problem` with at least two registered objective aliases.
#' @param primary Character scalar naming the objective to optimise directly.
#' @param aliases Optional character vector of registered objective aliases.
#'   By default, all registered objectives are used; `primary` must be included.
#' @param runs A run design from `set_runs_grid()` or `set_runs_manual()`.
#'   Automatic grids require exactly two objectives. Manual designs require
#'   `eps_<alias>` columns for all constrained objectives.
#' @param eps,mode,n_points,include_extremes Deprecated arguments from the
#'   previous interface. Use `runs` instead. `include_extremes` is ignored;
#'   automatic grids always include their endpoints.
#' @param lexicographic Logical. Whether to refine automatic-grid anchor
#'   solutions lexicographically; the default is `TRUE`.
#' @param lexicographic_tol Non-negative tolerance for lexicographic anchor
#'   refinement, expressed in the first objective's original units.
#' @param control Optional run-failure settings from `set_runs_control()`.
#'
#' @return An updated `Problem` with the method stored in `x$data$method`.
#'   Run-specific epsilon bounds are constructed or read during `solve()`.
#'
#' @examples
#' # EXAMPLE: Maximise woodland improvement under alternative cost limits.
#' # The landscape has 64 planning units and two candidate actions per unit.
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
#'   # Require some woodland improvement, so the low-cost plan is not empty.
#'   add_constraint_targets_relative(0.05, features = "woodland") |>
#'   add_objective_max_effect(
#'     features = "woodland", alias = "woodland"
#'   ) |>
#'   add_objective_min_cost(
#'     include_pu_cost = FALSE, alias = "cost"
#'   )
#'
#' # Generate five cost limits automatically from the objective extremes.
#' epsilon <- set_method_epsilon_constraint(
#'   base,
#'   primary = "woodland",
#'   aliases = c("woodland", "cost"),
#'   runs = set_runs_grid(n = 5),
#'   lexicographic = TRUE
#' )
#'
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(
#'     set_solver_cbc(epsilon, time_limit = 30, verbose = FALSE)
#'   )
#'
#'   # Each run maximises woodland gain subject to its own cost ceiling.
#'   get_objectives(solutions, format = "wide")
#'
#'   # The horizontal axis shows actual cost, not the epsilon ceiling.
#'   plot_tradeoff(
#'     solutions, objectives = c("cost", "woodland"),
#'     label_runs = TRUE
#'   )
#'
#'   # Compare low-, intermediate- and high-cost spatial prescriptions.
#'   # Epsilon levels can sometimes produce the same selected actions.
#'   plot_spatial_actions(
#'     solutions, solutions = c(1, 3, 5), layout = "single", ncol = 3
#'   )
#' }
#'
#' # ALTERNATIVE: specify explicit cost ceilings rather than a grid.
#' # Start from 'base', since each Problem can have only one method.
#' manual <- set_method_epsilon_constraint(
#'   base,
#'   primary = "woodland",
#'   aliases = c("woodland", "cost"),
#'   runs = set_runs_manual(data.frame(eps_cost = c(10, 20, 40)))
#' )
#'
#' @references
#' Haimes, Y. Y., Lasdon, L. S., and Wismer, D. A. (1971). On a
#' bicriterion formulation of the problems of integrated system identification
#' and system optimization. *IEEE Transactions on Systems, Man, and
#' Cybernetics*, SMC-1(3), 296-297. \doi{10.1109/TSMC.1971.4308298}.
#'
#' Mavrotas, G. (2009). Effective implementation of the epsilon-constraint
#' method in multi-objective mathematical programming problems. *Applied
#' Mathematics and Computation*, 213(2), 455-465.
#' \doi{10.1016/j.amc.2009.03.037}.
#'
#' @seealso
#' `set_method_weighted_sum()`, `set_method_augmecon()`, `set_runs_grid()`,
#' `set_runs_manual()`, `set_runs_control()`, `get_objectives()`,
#' `plot_tradeoff()`, `plot_spatial_actions()`, `solve()`
#'
#' @export
set_method_epsilon_constraint <- function(x,
                                          primary,
                                          aliases = NULL,
                                          runs = NULL,
                                          eps = NULL,
                                          mode = NULL,
                                          n_points = NULL,
                                          include_extremes = NULL,
                                          lexicographic = TRUE,
                                          lexicographic_tol = 1e-8,
                                          control = NULL) {
  stopifnot(inherits(x, "Problem"))
  .pa_assert_unconfigured(x, "method", "Multi-objective method", "set_method_*()")

  if (exists(".pa_clone_data", mode = "function")) {
    x <- .pa_clone_data(x)
  }

  # ---- primary
  primary <- as.character(primary)[1]

  if (is.na(primary) || !nzchar(primary)) {
    stop("`primary` must be a non-empty objective alias.", call. = FALSE)
  }

  # ---- objectives
  .pamo_validate_objectives(x)

  specs_all <- .pamo_get_specs(x)
  obj_alias <- names(specs_all)

  if (!primary %in% obj_alias) {
    stop("`primary` alias not found: '", primary, "'.", call. = FALSE)
  }

  if (is.null(aliases)) {
    aliases <- obj_alias
  } else {
    if (!is.character(aliases) || length(aliases) == 0L || anyNA(aliases)) {
      stop(
        "`aliases` must be NULL or a non-empty character vector without NA.",
        call. = FALSE
      )
    }

    aliases <- as.character(aliases)

    if (any(!nzchar(aliases))) {
      stop("`aliases` must not contain empty strings.", call. = FALSE)
    }

    if (anyDuplicated(aliases) != 0L) {
      dups <- unique(aliases[duplicated(aliases)])
      stop(
        "`aliases` must not contain duplicates: ",
        paste(dups, collapse = ", "),
        call. = FALSE
      )
    }
  }

  if (any(!aliases %in% obj_alias)) {
    bad <- aliases[!aliases %in% obj_alias]
    stop("Unknown aliases: ", paste(bad, collapse = ", "), call. = FALSE)
  }

  if (!primary %in% aliases) {
    stop("`primary` must be included in `aliases`.", call. = FALSE)
  }

  if (length(aliases) < 2L) {
    stop("epsilon-constraint requires at least two objectives.", call. = FALSE)
  }

  constrained <- setdiff(aliases, primary)

  if (length(constrained) == 0L) {
    stop("At least one constrained objective is required.", call. = FALSE)
  }

  .pamo_get_objective_specs(x, aliases)

  # -----------------------------------------------------------------------
  # Backwards compatibility layer
  # -----------------------------------------------------------------------

  old_args_used <- !is.null(eps) ||
    !is.null(mode) ||
    !is.null(n_points) ||
    !is.null(include_extremes)

  if (old_args_used && !is.null(runs)) {
    stop(
      paste0(
        "Use either `runs` or deprecated arguments ",
        "(`eps`, `mode`, `n_points`, `include_extremes`), not both."
      ),
      call. = FALSE
    )
  }

  if (is.null(runs) && old_args_used) {
    .pa_deprecate_arg(
      old = "eps/mode/n_points/include_extremes",
      new = "runs = set_runs_grid(...) or runs = set_runs_manual(...)"
    )

    if (!is.null(include_extremes) && !isTRUE(include_extremes)) {
      lifecycle::deprecate_warn(
        "1.1.0",
        "set_method_epsilon_constraint(include_extremes = )",
        details = paste0(
          "Boundary levels are now always included in automatic run grids. ",
          "The `include_extremes` argument is ignored."
        )
      )
    }

    mode <- mode %||% if (!is.null(eps)) "manual" else "auto"
    mode <- match.arg(mode, choices = c("manual", "auto"))

    if (identical(mode, "manual")) {
      if (is.null(eps)) {
        stop(
          "In deprecated `mode = 'manual'`, `eps` must be supplied.",
          call. = FALSE
        )
      }

      eps_df <- .pamo_eps_to_manual_df(
        eps = eps,
        constrained = constrained
      )

      runs <- set_runs_manual(eps_df)

    } else {
      n_points <- as.integer(n_points %||% 10L)[1]

      runs <- set_runs_grid(
        n = n_points
      )
    }
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

  # Automatic epsilon grid is currently only implemented for 2 objectives.
  # Manual runs can still be used for 3+ objectives.
  if (.pamo_is_run_grid(runs) && length(constrained) != 1L) {
    stop(
      paste0(
        "`runs = set_runs_grid()` for epsilon-constraint currently supports ",
        "exactly one constrained objective. Use `set_runs_manual()` for 3+ ",
        "objectives."
      ),
      call. = FALSE
    )
  }

  # ---- lexicographic
  if (
    !is.logical(lexicographic) ||
    length(lexicographic) != 1L ||
    is.na(lexicographic)
  ) {
    stop("`lexicographic` must be TRUE or FALSE.", call. = FALSE)
  }

  lexicographic_tol <- as.numeric(lexicographic_tol)[1]

  if (!is.finite(lexicographic_tol) || lexicographic_tol < 0) {
    stop(
      "`lexicographic_tol` must be a finite non-negative number.",
      call. = FALSE
    )
  }

  # ---- control
  control <- .pamo_check_mo_control(control)

  x$data$method <- list(
    name = "epsilon_constraint",
    type = "epsilon_constraint",
    primary = primary,
    aliases = aliases,
    constrained = constrained,
    runs = runs,
    lexicographic = isTRUE(lexicographic),
    lexicographic_tol = lexicographic_tol,
    control = control,
    stop_on_infeasible = control$stop_on_infeasible,
    stop_on_no_solution = control$stop_on_no_solution,
    stop_on_error = control$stop_on_error
  )

  x
}
