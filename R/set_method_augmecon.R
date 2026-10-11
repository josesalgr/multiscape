#' @include internalMO.R
#'
#' @title Configure the augmented epsilon-constraint method (AUGMECON)
#'
#' @description
#' Explore trade-offs among registered objectives using AUGMECON. One
#' objective is optimised directly, while the others are constrained by
#' epsilon levels and contribute small, normalised improvement terms to
#' discourage weakly efficient solutions.
#'
#' @details
#' Register at least two objectives with distinct `alias` values. The
#' `primary` objective is optimised directly; the remaining objectives
#' selected by `aliases` become epsilon-constrained objectives. For example,
#' with woodland improvement as the primary objective and cost as secondary,
#' each run seeks the greatest improvement while keeping cost below a ceiling:
#' \deqn{\max\ f_{\mathrm{woodland}}(x), \qquad
#'       f_{\mathrm{cost}}(x) \le \varepsilon_{\mathrm{cost}}.}
#'
#' **What augmentation changes.** Ordinary epsilon-constraint may return a
#' weakly efficient plan when another objective could improve without changing
#' the primary objective. AUGMECON introduces a non-negative slack for every
#' secondary constraint and rewards normalised slack through a small positive
#' coefficient `augmentation` (Mavrotas, 2009). For a minimised cost objective,
#' the slack measures how far actual cost lies *below* its epsilon ceiling.
#' Schematically, with a maximised primary objective, AUGMECON uses
#' \deqn{\max\ f_p(x) + \rho\sum_k \frac{s_k}{R_k},}
#' where \eqn{\rho} is `augmentation`, \eqn{s_k} is the non-negative slack,
#' and \eqn{R_k} is the payoff-table range of the corresponding secondary
#' objective. The implementation handles the signs of minimisation and
#' maximisation objectives internally. Choose a small augmentation so that
#' secondary improvements do not unintentionally outweigh primary performance.
#'
#' **Automatic epsilon grids.** Use `runs = set_runs_grid(n = 5)` to obtain
#' five epsilon levels, including the endpoints, for each secondary objective.
#' Levels and payoff-table ranges are calculated during `solve()`.
#' With three objectives, for example, two secondary grids of five levels
#' yield up to 25 combinations. When `lexicographic = TRUE`, extreme-point
#' calculations use lexicographic anchoring, with `lexicographic_tol`
#' specifying the tolerance.
#'
#' **Manual thresholds.** Use `runs = set_runs_manual()` to supply explicit
#' epsilon values, one row per run and one column named `eps_<alias>` for each
#' secondary objective. For a minimised cost objective, `eps_cost = 20` means
#' *cost at most 20*, not exactly 20. Unlike automatic grids, manual rows are
#' not expanded into all possible combinations; use `expand.grid()` if needed.
#'
#' **Interpreting solutions.** The augmentation reduces weak-efficiency
#' problems, but a finite epsilon grid does not enumerate every Pareto-optimal
#' plan, and different runs can produce identical spatial decisions. Numerical
#' tolerances and finite solver time limits also matter. A numerical refinement
#' pass may improve secondary slacks after an optimal augmented solve;
#' solver settings and epsilon-bound checks are available in the solution
#' diagnostics. `slack_upper_bound` must be large enough for valid slacks,
#' without being unnecessarily loose. Use `set_runs_control()` to manage
#' infeasible or unsuccessful runs.
#'
#' Only one multi-objective method can be configured on a `Problem`; compare
#' methods by starting from the same problem before calling `set_method_*()`.
#' The older `grid`, `n_points`, and `include_extremes` arguments are deprecated
#' in favour of `runs`.
#'
#' @param x A `Problem` with at least two registered objective aliases.
#' @param primary Character scalar naming the objective optimised directly.
#' @param aliases Optional character vector of registered objective aliases.
#'   By default, all registered objectives are included; `primary` must be one
#'   of them.
#' @param runs A run design from `set_runs_grid()` or `set_runs_manual()`.
#'   Manual designs contain `eps_<alias>` columns for all secondary objectives.
#' @param grid,n_points,include_extremes Deprecated run-design arguments;
#'   use `runs` instead. `include_extremes` is ignored because automatic
#'   grids always include their endpoints.
#' @param lexicographic Logical. Whether to use lexicographic anchoring when
#'   computing automatic-grid extreme points. Defaults to `TRUE`.
#' @param lexicographic_tol Non-negative tolerance for the lexicographic
#'   extreme-point calculation, in the objective's original units.
#' @param augmentation Positive coefficient for the normalised slack reward.
#'   Defaults to `1e-3`.
#' @param slack_upper_bound Positive upper bound for AUGMECON slack variables.
#'   Defaults to `1e6`; it must not exclude feasible values.
#' @param control Optional run-failure settings from `set_runs_control()`.
#'
#' @return An updated `Problem` with the method stored in `x$data$method`.
#'   Payoff-table calculations and optimisation runs take place in `solve()`.
#'
#' @examples
#' # EXAMPLE: Maximise woodland improvement under alternative cost limits.
#' # Use the same 64-unit landscape and objectives as in the other MO methods.
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
#'   # Require some improvement to avoid an empty low-cost solution.
#'   add_constraint_targets_relative(0.05, features = "woodland") |>
#'   add_objective_max_effect(
#'     features = "woodland", alias = "woodland"
#'   ) |>
#'   add_objective_min_cost(
#'     include_pu_cost = FALSE, alias = "cost"
#'   )
#'
#' # Explore five cost ceilings. Small slack rewards help distinguish
#' # plans with similar woodland improvements but different costs.
#' augmecon <- set_method_augmecon(
#'   base,
#'   primary = "woodland",
#'   aliases = c("woodland", "cost"),
#'   runs = set_runs_grid(n = 5),
#'   lexicographic = TRUE,
#'   augmentation = 1e-3
#' )
#'
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(
#'     set_solver_cbc(augmecon, time_limit = 30, verbose = FALSE)
#'   )
#'
#'   # Actual cost may be lower than the epsilon ceiling.
#'   get_objectives(solutions, format = "wide")
#'
#'   # Inspect the trade-off frontier generated by AUGMECON.
#'   plot_tradeoff(
#'     solutions, objectives = c("cost", "woodland"),
#'     label_runs = TRUE
#'   )
#'
#'   # Compare selected management actions for three epsilon levels.
#'   # The three runs need not produce three different spatial plans.
#'   plot_spatial_actions(
#'     solutions, solutions = c(1, 3, 5), layout = "single", ncol = 3
#'   )
#' }
#'
#' # ALTERNATIVE: use three manually specified cost ceilings.
#' # Start again from 'base', before configuring a multi-objective method.
#' manual <- set_method_augmecon(
#'   base,
#'   primary = "woodland",
#'   aliases = c("woodland", "cost"),
#'   runs = set_runs_manual(data.frame(eps_cost = c(10, 20, 40))),
#'   augmentation = 1e-3
#' )
#'
#' @references
#' Mavrotas, G. (2009). Effective implementation of the
#' \eqn{\varepsilon}-constraint method in multi-objective mathematical
#' programming problems. *Applied Mathematics and Computation*, 213(2),
#' 455-465. \doi{10.1016/j.amc.2009.03.037}.
#'
#' Mavrotas, G., and Florios, K. (2013). An improved version of the augmented
#' \eqn{\varepsilon}-constraint method (AUGMECON2) for finding the exact
#' Pareto set in multi-objective integer programming problems. *Applied
#' Mathematics and Computation*, 219(18), 9652-9669.
#' \doi{10.1016/j.amc.2013.03.002}. (Related extension; not the same method.)
#'
#' @seealso
#' `set_method_epsilon_constraint()`, `set_method_weighted_sum()`,
#' `set_runs_grid()`, `set_runs_manual()`, `set_runs_control()`,
#' `get_objectives()`, `plot_tradeoff()`, `plot_spatial_actions()`, `solve()`
#'
#' @export
set_method_augmecon <- function(x,
                                primary,
                                aliases = NULL,
                                runs = NULL,
                                grid = NULL,
                                n_points = NULL,
                                include_extremes = NULL,
                                lexicographic = TRUE,
                                lexicographic_tol = 1e-9,
                                augmentation = 1e-3,
                                slack_upper_bound = 1e6,
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

  # ---- aliases
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
    stop("AUGMECON requires at least two objectives.", call. = FALSE)
  }

  secondary <- setdiff(aliases, primary)

  if (length(secondary) == 0L) {
    stop("AUGMECON requires at least one secondary objective.", call. = FALSE)
  }

  .pamo_get_objective_specs(x, aliases)

  # -----------------------------------------------------------------------
  # Backwards compatibility for run design only
  # -----------------------------------------------------------------------

  old_args_used <- !is.null(grid) ||
    !is.null(n_points) ||
    !is.null(include_extremes)

  if (old_args_used && !is.null(runs)) {
    stop(
      paste0(
        "Use either `runs` or deprecated arguments ",
        "(`grid`, `n_points`, `include_extremes`), not both."
      ),
      call. = FALSE
    )
  }

  if (is.null(runs) && old_args_used) {
    .pa_deprecate_arg(
      old = "grid/n_points/include_extremes",
      new = "runs = set_runs_grid(...) or runs = set_runs_manual(...)"
    )

    if (!is.null(include_extremes) && !isTRUE(include_extremes)) {
      lifecycle::deprecate_warn(
        "1.1.0",
        "set_method_augmecon(include_extremes = )",
        details = paste0(
          "Boundary levels are now always included in automatic run grids. ",
          "The `include_extremes` argument is ignored."
        )
      )
    }

    if (is.null(grid)) {
      n_points <- as.integer(n_points %||% 10L)[1]

      runs <- set_runs_grid(
        n = n_points
      )

    } else {
      grid_df <- .pamo_augmecon_grid_to_manual_df(
        grid = grid,
        secondary = secondary
      )

      # `set_runs_manual()` only accepts weight_<alias> and eps_<alias>
      # columns. Run identifiers are generated later.
      grid_df$run_id <- NULL

      runs <- set_runs_manual(grid_df)
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

  # ---- lexicographic
  if (
    !is.logical(lexicographic) ||
    length(lexicographic) != 1L ||
    is.na(lexicographic)
  ) {
    stop("`lexicographic` must be TRUE or FALSE.", call. = FALSE)
  }

  lexicographic <- isTRUE(lexicographic)

  lexicographic_tol <- as.numeric(lexicographic_tol)[1]

  if (!is.finite(lexicographic_tol) || lexicographic_tol < 0) {
    stop(
      "`lexicographic_tol` must be a finite non-negative number.",
      call. = FALSE
    )
  }

  # ---- augmentation
  augmentation <- as.numeric(augmentation)[1]

  if (!is.finite(augmentation) || augmentation <= 0) {
    stop("`augmentation` must be a finite positive number.", call. = FALSE)
  }

  # ---- slack upper bound
  slack_upper_bound <- as.numeric(slack_upper_bound)[1]

  if (!is.finite(slack_upper_bound) || slack_upper_bound <= 0) {
    stop(
      "`slack_upper_bound` must be a single positive finite number.",
      call. = FALSE
    )
  }

  # ---- control
  control <- .pamo_check_mo_control(control)

  x$data$method <- list(
    name = "augmecon",
    type = "augmecon",
    primary = primary,
    aliases = aliases,
    secondary = secondary,
    runs = runs,
    lexicographic = lexicographic,
    lexicographic_tol = lexicographic_tol,
    augmentation = augmentation,
    slack_upper_bound = slack_upper_bound,
    stop_on_infeasible = control$stop_on_infeasible,
    stop_on_no_solution = control$stop_on_no_solution,
    stop_on_error = control$stop_on_error,
    control = control
  )

  x
}
