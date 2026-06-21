#' @include internalMO.R internal.R
#'
#' @title Get planning-unit results from a solution set
#'
#' @description
#' Extract the planning-unit summary table from a \code{\link{solutionset-class}}
#' object returned by \code{\link{solve}}.
#'
#' The returned table summarizes solution values at the planning-unit level and
#' typically includes a \code{selected} indicator showing whether each planning
#' unit is selected in a solution.
#'
#' @details
#' This function reads the planning-unit summary stored in
#' \code{x$summary$pu}. It does not reconstruct the table from the raw decision
#' vector; it simply returns the stored summary after optional run filtering.
#'
#' Let \eqn{w_i} denote the planning-unit selection variable for planning unit
#' \eqn{i}. In standard \pkg{multiscape} workflows, the \code{selected} column
#' is the user-facing representation of that planning-unit decision, typically
#' coded as \code{0} or \code{1}.
#'
#' If \code{solution} is provided, only rows belonging to that solution are returned. This
#' requires the summary table to contain a \code{solution_id} column.
#'
#' To return only selected planning units, filter the returned table using
#' \code{selected == 1}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param solution Optional positive integer giving the solution index to extract. If
#'   \code{NULL}, all solutions are returned when available.
#'
#' @return A \code{data.frame} containing the stored planning-unit summary.
#'   Typical columns include planning-unit identifiers, optional labels, and a
#'   \code{selected} indicator.
#'
#' @examples
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
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # Planning-unit results for all stored runs
#'   get_planning_units(solutions)
#'
#'   # Return only selected planning units
#'   selected_pu <- get_planning_units(solutions)
#'   selected_pu <- selected_pu[selected_pu$selected == 1L, , drop = FALSE]
#'   selected_pu
#'
#'   # Extract one run using its solution_id
#'   solution_ids <- get_runs(solutions)$solution_id
#'
#'   get_planning_units(
#'     solutions,
#'     solution = solution_ids[1]
#'   )
#' }
#'
#' @seealso
#' \code{\link{get_actions}},
#' \code{\link{get_features}},
#' \code{\link{get_targets}}
#'
#' @export
get_planning_units <- function(x, solution = NULL, ...) {

  if (!inherits(x, c("SolutionSet"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  solution <- .pa_resolve_solution_arg(
    solution = solution,
    ...,
    caller = "get_planning_units"
  )

  pu <- x$summary$pu %||% NULL
  if (is.null(pu)) {
    stop("No planning-unit summary found (x$summary$pu is NULL).", call. = FALSE)
  }

  pu <- .pa_filter_summary_by_solution(
    x = x,
    tab = pu,
    solution = solution,
    table_name = "Planning-unit summary"
  )

  rownames(pu) <- NULL
  pu <- .pa_drop_run_id_if_solution_id_present(pu)
  pu
}


#' @title Get planning-unit results from a solution set
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' \code{get_pu()} has been replaced by
#' \code{\link{get_planning_units}}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param solution Optional positive integer giving the solution index to extract. If
#'   \code{NULL}, all solutions are returned when available.
#'
#' @return A \code{data.frame} containing the stored planning-unit summary.
#'
#' @export
get_pu <- function(x, solution = NULL, ...) {
  lifecycle::deprecate_warn(
    "1.1.0",
    "get_pu()",
    "get_planning_units()"
  )

  get_planning_units(
    x = x,
    solution = solution,
    ...
  )
}


#' @title Get action results from a solution set
#'
#' @description
#' Extract the action-allocation summary table from a
#' \code{\link{solutionset-class}} object returned by \code{\link{solve}}.
#'
#' The returned table summarizes solution values at the
#' planning unit--action level and typically includes a \code{selected}
#' indicator showing whether each feasible \code{(pu, action)} pair is selected
#' in a solution.
#'
#' @details
#' This function reads the action summary stored in \code{x$summary$actions}. It
#' does not reconstruct the table from the raw decision vector; it simply
#' returns the stored summary after optional run filtering.
#'
#' Let \eqn{x_{ia}} denote the decision variable associated with selecting
#' action \eqn{a} in planning unit \eqn{i}. In standard \pkg{multiscape}
#' workflows, the \code{selected} column is the user-facing representation of
#' that decision, typically coded as \code{0} or \code{1}.
#'
#' If \code{solution} is provided, only rows belonging to that solution are returned. This
#' requires the summary table to contain a \code{solution_id} column.
#'
#' To return only selected action allocations, filter the returned table using
#' \code{selected == 1}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param solution Optional positive integer giving the solution index to extract. If
#'   \code{NULL}, all runs are returned when available.
#'
#' @return A \code{data.frame} containing the stored action-allocation summary.
#'   Typical columns include planning-unit ids, action ids, optional labels, and
#'   a \code{selected} indicator.
#'
#' @examples
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
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # All feasible planning-unit/action assignments
#'   get_actions(solutions)
#'
#'   # Only selected action assignments
#'   selected_actions <- get_actions(solutions)
#'   selected_actions <- selected_actions[
#'     selected_actions$selected == 1L,
#'     ,
#'     drop = FALSE
#'   ]
#'   selected_actions
#'
#'   # Action allocations for one solution
#'   solution_ids <- get_runs(solutions)$solution_id
#'
#'   get_actions(
#'     solutions,
#'     solution = solution_ids[1]
#'   )
#' }
#'
#' @seealso
#' \code{\link{get_planning_units}},
#' \code{\link{get_features}},
#' \code{\link{get_targets}}
#'
#' @export
get_actions <- function(x, solution = NULL, ...) {

  if (!inherits(x, c("SolutionSet"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  solution <- .pa_resolve_solution_arg(
    solution = solution,
    ...,
    caller = "get_actions"
  )

  a <- x$summary$actions %||% NULL
  if (is.null(a)) {
    stop("No actions summary found (x$summary$actions is NULL).", call. = FALSE)
  }

  a <- .pa_filter_summary_by_solution(
    x = x,
    tab = a,
    solution = solution,
    table_name = "Actions summary"
  )

  a <- a[
    ,
    setdiff(names(a), c("internal_pu", "internal_action", "internal_row")),
    drop = FALSE
  ]

  rownames(a) <- NULL
  a <- .pa_drop_run_id_if_solution_id_present(a)
  a
}


#' @title Get feature summary from a solution set
#'
#' @description
#' Extract the per-feature summary table from a
#' \code{\link{solutionset-class}} object returned by \code{\link{solve}}.
#'
#' The returned table summarizes, for each feature, how much of the feature was
#' available in the full baseline landscape and how much is represented by the
#' selected planning units or selected actions in each run.
#'
#' @details
#' This function reads the feature summary stored in \code{x$summary$features}.
#' It errors if that table is missing.
#'
#' Feature summaries distinguish between baseline availability in the full
#' landscape and the contribution of selected planning units or selected actions.
#'
#' Let \eqn{B_f} denote the total baseline amount of feature \eqn{f} available
#' in the full landscape. Let \eqn{S_f} denote the baseline amount of feature
#' \eqn{f} in selected rows. Let \eqn{A_f} denote the after-action amount of
#' feature \eqn{f} contributed by those selected rows. Let \eqn{G_f} and
#' \eqn{L_f} denote the positive and negative net-change components induced by
#' selected actions. Then:
#'
#' \deqn{
#' \mathrm{selected\_net}_f = G_f - L_f,
#' }
#'
#' and:
#'
#' \deqn{
#' A_f = S_f + \mathrm{selected\_net}_f.
#' }
#'
#' The main returned columns are:
#' \itemize{
#'   \item \code{baseline_total}: total baseline amount in the full landscape;
#'   \item \code{selected_baseline}: baseline amount in selected rows;
#'   \item \code{selected_amount_after}: after-action amount contributed by
#'   selected rows;
#'   \item \code{selected_benefit}: positive net-change component from selected
#'   actions;
#'   \item \code{selected_loss}: negative net-change component from selected
#'   actions;
#'   \item \code{selected_net}: net change from selected actions;
#'   \item \code{selected_fraction_of_baseline}: ratio between
#'   \code{selected_amount_after} and \code{baseline_total}.
#' }
#'
#' Importantly, this summary does not assume that planning units without a
#' selected action contribute to the achieved feature amount. Therefore, the
#' achieved amount for a feature is represented by
#' \code{selected_amount_after}, not by a full-landscape total obtained by adding
#' net changes to the baseline.
#'
#' For backwards compatibility with older result objects, if the newer
#' selected-action columns are missing, this function attempts to construct them
#' from older columns such as \code{total_available}, \code{benefit},
#' \code{loss}, \code{net}, and \code{amount_after}. However, the returned table
#' is organized using the newer selected-action terminology.
#'
#' If \code{solution} is provided, only rows belonging to that solution are returned. If
#' the result contains a \code{solution_id} column but only a single solution is present and
#' \code{solution} was not requested explicitly, the \code{solution_id} column is removed
#' for convenience.
#'
#' This function summarizes feature outcomes in the result. It is different from
#' \code{\link{get_targets}}, which focuses on target achievement.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param solution Optional positive integer giving the solution index to extract. If
#'   \code{NULL}, all runs are returned when available.
#'
#' @return A \code{data.frame} with one row per feature, or one row per
#'   feature--run combination when multiple runs are present. The returned table
#'   includes, when available or derivable, the columns
#'   \code{baseline_total}, \code{selected_baseline},
#'   \code{selected_amount_after}, \code{selected_benefit},
#'   \code{selected_loss}, \code{selected_net}, and
#'   \code{selected_fraction_of_baseline}.
#'
#' @examples
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
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # Feature outcomes for all stored runs
#'   get_features(solutions)
#'
#'   # Feature outcomes for one run
#'   solution_ids <- get_runs(solutions)$solution_id
#'
#'   get_features(
#'     solutions,
#'     solution = solution_ids[1]
#'   )
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_actions}},
#' \code{\link{get_targets}}
#'
#' @export
get_features <- function(x, solution = NULL, ...) {

  if (!inherits(x, c("SolutionSet"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  solution <- .pa_resolve_solution_arg(
    solution = solution,
    ...,
    caller = "get_features"
  )

  f <- x$summary$features %||% NULL
  if (is.null(f)) {
    stop("No features summary found (x$summary$features is NULL).", call. = FALSE)
  }

  f <- .pa_filter_summary_by_solution(
    x = x,
    tab = f,
    solution = solution,
    table_name = "Features summary"
  )

  out <- f

  # --------------------------------------------------------------------------
  # Backward-compatible normalization of feature summary names
  # --------------------------------------------------------------------------

  if (!("baseline_total" %in% names(out))) {
    if ("total_available" %in% names(out)) {
      out$baseline_total <- out$total_available
    } else {
      out$baseline_total <- 0
    }
  }

  if (!("selected_benefit" %in% names(out))) {
    if ("benefit" %in% names(out)) {
      out$selected_benefit <- out$benefit
    } else {
      out$selected_benefit <- 0
    }
  }

  if (!("selected_loss" %in% names(out))) {
    if ("loss" %in% names(out)) {
      out$selected_loss <- out$loss
    } else {
      out$selected_loss <- 0
    }
  }

  out$baseline_total <- as.numeric(out$baseline_total)
  out$selected_benefit <- as.numeric(out$selected_benefit)
  out$selected_loss <- as.numeric(out$selected_loss)

  out$baseline_total[is.na(out$baseline_total)] <- 0
  out$selected_benefit[is.na(out$selected_benefit)] <- 0
  out$selected_loss[is.na(out$selected_loss)] <- 0

  if (!("selected_net" %in% names(out))) {
    if ("net" %in% names(out)) {
      out$selected_net <- as.numeric(out$net)
    } else {
      out$selected_net <- out$selected_benefit - out$selected_loss
    }
  } else {
    out$selected_net <- as.numeric(out$selected_net)
  }

  out$selected_net[is.na(out$selected_net)] <- 0

  if (!("selected_amount_after" %in% names(out))) {
    if ("amount_after" %in% names(out)) {
      out$selected_amount_after <- out$amount_after
    } else if ("selected_baseline" %in% names(out)) {
      out$selected_amount_after <- as.numeric(out$selected_baseline) + out$selected_net
    } else {
      out$selected_amount_after <- 0
    }
  }

  out$selected_amount_after <- as.numeric(out$selected_amount_after)
  out$selected_amount_after[is.na(out$selected_amount_after)] <- 0

  if (!("selected_baseline" %in% names(out))) {
    out$selected_baseline <- out$selected_amount_after - out$selected_net
  }

  out$selected_baseline <- as.numeric(out$selected_baseline)
  out$selected_baseline[is.na(out$selected_baseline)] <- 0

  if (!("selected_fraction_of_baseline" %in% names(out))) {
    out$selected_fraction_of_baseline <- ifelse(
      out$baseline_total > 0,
      out$selected_amount_after / out$baseline_total,
      NA_real_
    )
  } else {
    out$selected_fraction_of_baseline <- as.numeric(out$selected_fraction_of_baseline)
  }

  keep_first <- c(
    "run_id",
    "feature",
    "feature_name",
    "baseline_total",
    "selected_baseline",
    "selected_amount_after",
    "selected_benefit",
    "selected_loss",
    "selected_net",
    "selected_fraction_of_baseline"
  )

  old_aliases <- c(
    "total_available",
    "benefit",
    "loss",
    "net",
    "total",
    "amount_after"
  )

  keep_first <- intersect(keep_first, names(out))
  keep_rest <- setdiff(names(out), c(keep_first, old_aliases))

  out <- out[, c(keep_first, keep_rest), drop = FALSE]

  if ("solution_id" %in% names(out) &&
      length(unique(out$solution_id[!is.na(out$solution_id)])) <= 1L &&
      is.null(solution)) {
    out$solution_id <- NULL
  }

  rownames(out) <- NULL
  out <- .pa_drop_run_id_if_solution_id_present(out)
  out
}


#' @title Get target achievement summary from a solution set
#'
#' @description
#' Extract a user-facing target-achievement table from a
#' \code{\link{solutionset-class}} object returned by \code{\link{solve}}.
#'
#' The returned table summarizes, for each stored target, the target level, the
#' achieved value, the gap between achieved and required values, and whether the
#' target was met in each run.
#'
#' @details
#' Targets are optional in \pkg{multiscape}. If the result object does not
#' contain a targets summary table at \code{x$summary$targets}, this function
#' returns \code{NULL} without error.
#'
#' This function reads the stored targets summary and returns a simplified
#' user-facing table. If the summary contains \code{achieved} and
#' \code{target_value}, target satisfaction is evaluated as follows.
#'
#' For lower-bound targets:
#' \deqn{
#' \mathrm{met} = (\mathrm{achieved} \ge \mathrm{target}),
#' }
#'
#' and for upper-bound targets:
#' \deqn{
#' \mathrm{met} = (\mathrm{achieved} \le \mathrm{target}).
#' }
#'
#' The interpretation of the target direction is taken from the \code{sense}
#' column when available:
#' \itemize{
#'   \item \code{"ge"}, \code{">="}, or \code{"min"} are treated as lower-bound
#'   targets;
#'   \item \code{"le"}, \code{"<="}, or \code{"max"} are treated as upper-bound
#'   targets;
#'   \item if \code{sense} is missing, the target is treated as a lower bound by
#'   default.
#' }
#'
#' The returned table is simplified and renames some internal fields for
#' readability:
#' \itemize{
#'   \item \code{target_raw} is returned as \code{target_level};
#'   \item \code{basis_total} is returned as \code{total_available};
#'   \item \code{target_value} is returned as \code{target}.
#' }
#'
#' If \code{solution} is provided, only rows belonging to that solution are returned. If
#' the result contains a \code{run_id} column but only a single solution is present and
#' \code{solution} was not requested explicitly, the \code{solution_id} column is removed
#' for convenience.
#'
#' The \code{gap} column is expected to be part of the stored summary. When
#' present, it typically represents:
#' \deqn{
#' \mathrm{gap} = \mathrm{achieved} - \mathrm{target}.
#' }
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param solution Optional positive integer giving the solution index to extract. If
#'   \code{NULL}, all runs are returned when available.
#'
#' @return A simplified \code{data.frame} target summary, or \code{NULL} if the
#'   result does not contain targets. Typical columns include \code{feature},
#'   \code{feature_name}, \code{target_level}, \code{total_available},
#'   \code{target}, \code{achieved}, \code{gap}, and \code{met}.
#'
#' @examples
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
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # Target requirements and achieved amounts
#'   get_targets(solutions)
#'
#'   # Target achievement for one run
#'   solution_ids <- get_runs(solutions)$solution_id
#'
#'   get_targets(
#'     solutions,
#'     solution = solution_ids[1]
#'   )
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_actions}},
#' \code{\link{get_features}}
#'
#' @export
get_targets <- function(x, solution = NULL, ...) {

  if (!inherits(x, c("SolutionSet"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  solution <- .pa_resolve_solution_arg(
    solution = solution,
    ...,
    caller = "get_targets"
  )

  t <- x$summary$targets %||% NULL
  if (is.null(t)) {
    return(NULL)
  }

  t <- .pa_filter_summary_by_solution(
    x = x,
    tab = t,
    solution = solution,
    table_name = "Targets summary"
  )

  out <- t

  if (all(c("achieved", "target_value") %in% names(out))) {
    if ("sense" %in% names(out)) {
      out$met <- ifelse(
        out$sense %in% c("ge", ">=", "min"),
        out$achieved >= out$target_value,
        ifelse(
          out$sense %in% c("le", "<=", "max"),
          out$achieved <= out$target_value,
          NA
        )
      )
    } else {
      out$met <- out$achieved >= out$target_value
    }
  }

  keep <- c(
    "run_id",
    "feature",
    "feature_name",
    "target_raw",
    "basis_total",
    "target_value",
    "achieved",
    "gap",
    "met"
  )
  keep <- intersect(keep, names(out))
  out <- out[, keep, drop = FALSE]

  names(out)[names(out) == "target_raw"] <- "target_level"
  names(out)[names(out) == "basis_total"] <- "total_available"
  names(out)[names(out) == "target_value"] <- "target"

  if ("solution_id" %in% names(out) &&
      length(unique(out$solution_id[!is.na(out$solution_id)])) <= 1L &&
      is.null(solution)) {
    out$solution_id <- NULL
  }

  out <- .pa_drop_run_id_if_solution_id_present(out)
  out
}


#' @title Get raw decision vector from a solution set
#'
#' @description
#' Return the raw decision-variable vector for a selected run in a
#' \code{\link{solutionset-class}} object returned by \code{\link{solve}}.
#'
#' The vector is returned in the internal model-variable order used by the
#' optimization backend.
#'
#' @details
#' This function extracts the raw decision vector for one run. The returned
#' vector is in the internal variable order of the optimization model. Depending
#' on the problem formulation, it may include:
#' \itemize{
#'   \item planning-unit selection variables;
#'   \item action-allocation variables;
#'   \item auxiliary variables introduced for targets, budgets, fragmentation,
#'   or other constraints/objectives;
#'   \item and potentially additional blocks created internally by the model
#'   builder.
#' }
#'
#' Therefore, this vector is primarily intended for advanced users, debugging,
#' diagnostics, or internal verification. It is not a user-facing allocation
#' table.
#'
#' To inspect selected planning units or selected actions in a more interpretable
#' form, use \code{\link{get_pu}} or \code{\link{get_actions}} instead.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param solution Optional character string giving the solution id to
#'   extract. If supplied, \code{run} must be \code{NULL}.
#'
#' @return A numeric vector with one value per internal model variable.
#'
#' @examples
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
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost")
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # Extract the first stored raw solution vector
#'   vector <- get_solution_vector(solutions)
#'   vector
#'   length(vector)
#'
#'   # Extract a vector using its solution_id
#'   runs <- get_runs(solutions)
#'   solution_ids <- runs$solution_id[
#'     !is.na(runs$solution_id)
#'   ]
#'
#'   if (length(solution_ids) > 0L) {
#'     get_solution_vector(
#'       solutions,
#'       solution = solution_ids[1]
#'     )
#'   }
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_actions}},
#' \code{\link{get_features}},
#' \code{\link{get_targets}}
#' @noRd
get_solution_vector <- function(x, solution = NULL, ...) {

  if (!inherits(x, c("SolutionSet"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  solution <- .pa_resolve_solution_arg(
    solution = solution,
    ...,
    caller = "get_solution_vector"
  )

  sol <- .mo_get_solution_from(
    x,
    solution_id = solution
  )

  v <- sol$solution$vector %||% NULL
  if (is.null(v)) {
    stop("No raw decision vector found for the selected solution.", call. = FALSE)
  }

  as.numeric(v)
}


#' Get run-level metadata from a solution set
#'
#' @description
#' Extract the run table from a \code{\link{solutionset-class}} object.
#'
#' @details
#' A run represents an attempted optimization solve. Each run has a unique
#' \code{run_id}. Only runs that produce a stored solution receive a
#' \code{solution_id}.
#'
#' The \code{solution_id} is numeric and matches the corresponding
#' \code{run_id}. Therefore, if a run fails or is infeasible, its
#' \code{solution_id} is \code{NA}; if a later run succeeds, its
#' \code{solution_id} keeps the same value as its \code{run_id}.
#'
#' This function is the user-facing place where the relationship between
#' attempted runs and stored solutions is reported.
#'
#' Objective values are not returned by \code{get_runs()}. To extract objective
#' values, use \code{\link{get_objectives}}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @return A \code{data.frame} with one row per attempted optimization run.
#'   The table contains run metadata and the numeric mapping between
#'   \code{run_id} and \code{solution_id}, but not objective-value columns.
#'
#' @seealso
#' \code{\link{get_objectives}},
#' \code{\link{solution_filter}},
#' \code{\link{set_runs_grid}},
#' \code{\link{set_runs_manual}}
#'
#' @export
get_runs <- function(x) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  runs <- x$solution$runs %||% NULL

  if (is.null(runs) || !inherits(runs, "data.frame")) {
    stop("No run table found in x$solution$runs.", call. = FALSE)
  }

  out <- runs

  if (!("run_id" %in% names(out))) {
    stop("Run table has no 'run_id' column.", call. = FALSE)
  }

  out$run_id <- as.integer(out$run_id)

  if (!("solution_id" %in% names(out))) {
    out$solution_id <- NA_integer_
  } else {
    out$solution_id <- suppressWarnings(as.integer(out$solution_id))
  }

  value_cols <- grep("^value_", names(out), value = TRUE)

  if (length(value_cols) > 0L) {
    out <- out[, setdiff(names(out), value_cols), drop = FALSE]
  }

  first <- intersect(
    c("run_id", "solution_id", "status", "runtime", "gap", "message"),
    names(out)
  )

  rest <- setdiff(names(out), first)

  out <- out[, c(first, rest), drop = FALSE]

  if ("message" %in% names(out)) {
    msg <- as.character(out$message)
    msg[is.na(msg)] <- ""

    if (all(!nzchar(trimws(msg)))) {
      out$message <- NULL
    }
  }

  rownames(out) <- NULL

  out
}


#' Get objective values from a solution set
#'
#' @description
#' Extract objective values from the runs stored in a
#' \code{\link{solutionset-class}} object.
#'
#' @details
#' Objective values are read from run-table columns named
#' \code{value_<objective>}, where \code{<objective>} is the registered
#' objective alias.
#'
#' Runs without a stored solution may contain missing objective values. Use
#' \code{feasible_only = TRUE}, or filter the \code{SolutionSet} beforehand,
#' when only solved runs should be included.
#'
#' In long format, every run-objective combination occupies one row. In wide
#' format, every run occupies one row and every objective occupies one column.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param format Character. Output representation, either \code{"long"} or
#'   \code{"wide"}. Defaults to \code{"long"}.
#'
#' @return If \code{format = "long"}, a \code{data.frame} with columns
#'   \code{run_id}, \code{solution_id}, \code{objective}, and \code{value}.
#'
#' If \code{format = "wide"}, a \code{data.frame} with \code{run_id},
#' \code{solution_id}, and one column per objective.
#'
#' @examples
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
#'     runs = set_runs_grid(
#'       n = 5
#'     ),
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
#'   # Long format
#'   get_objectives(solutions)
#'
#'   # Wide format
#'   get_objectives(
#'     solutions,
#'     format = "wide"
#'   )
#'
#'   # Objective values from usable runs only
#'   get_objectives(
#'     solutions
#'   )
#' }
#'
#' @seealso
#' \code{\link{get_runs}},
#' \code{\link{frontier_extremes}},
#' \code{\link{frontier_distances}}
#'
#' @export
get_objectives <- function(x,
                           format = c("wide", "long")) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  format <- match.arg(format)

  out <- .pa_get_objectives_internal(
    x = x,
    format = format
  )

  out <- .pa_drop_run_id_if_solution_id_present(out)

  out
}


#' Get objective specifications from a solution set
#'
#' @description
#' Extract the definitions of the objectives registered in the original
#' planning problem associated with a \code{\link{solutionset-class}} object.
#'
#' @details
#' Objective specifications are read from
#' \code{x$problem$data$objectives}. They describe how each objective was
#' registered, independently of the multi-objective method later used to solve
#' the problem.
#'
#' The returned optimization sense is used by frontier and dominance functions
#' to place objectives in a common minimization space.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @return A \code{data.frame} with one row per registered objective and the
#'   columns:
#' \itemize{
#'   \item \code{objective}: user-defined objective alias;
#'   \item \code{objective_id}: internal objective type;
#'   \item \code{model_type}: internal model formulation;
#'   \item \code{sense}: optimization direction, \code{"min"} or \code{"max"};
#'   \item \code{created_at}: objective registration timestamp.
#' }
#'
#' @examples
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
#'     runs = set_runs_grid(
#'       n = 5
#'     ),
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
#'   get_objective_specs(solutions)
#' }
#'
#' @seealso
#' \code{\link{get_runs}},
#' \code{\link{get_objectives}},
#' \code{\link{frontier_extremes}},
#' \code{\link{solution_filter}}
#' @noRd
get_objective_specs <- function(x) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  problem <- x$problem %||% NULL

  if (is.null(problem) || !inherits(problem, "Problem")) {
    stop(
      "No valid Problem object found in x$problem.",
      call. = FALSE
    )
  }

  specs <- problem$data$objectives %||% NULL

  if (is.null(specs) || !is.list(specs) || length(specs) == 0L) {
    stop(
      "No objective specifications found in x$problem$data$objectives.",
      call. = FALSE
    )
  }

  out <- lapply(names(specs), function(nm) {
    spec <- specs[[nm]]

    alias <- spec$alias %||% nm
    objective_id <- spec$objective_id %||% NA_character_
    model_type <- spec$model_type %||% NA_character_
    sense <- spec$sense %||% NA_character_
    created_at <- spec$created_at %||% NA_character_

    if (is.na(alias) || !nzchar(alias)) {
      stop("Objective specification has an empty alias.", call. = FALSE)
    }

    if (is.na(sense) || !nzchar(sense)) {
      stop(
        "Objective '", alias, "' has no registered optimization sense.",
        call. = FALSE
      )
    }

    if (!sense %in% c("min", "max")) {
      stop(
        "Objective '", alias, "' has invalid sense '", sense,
        "'. Expected 'min' or 'max'.",
        call. = FALSE
      )
    }

    data.frame(
      objective = as.character(alias)[1],
      objective_id = as.character(objective_id)[1],
      model_type = as.character(model_type)[1],
      sense = as.character(sense)[1],
      created_at = as.character(created_at)[1],
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, out)
  rownames(out) <- NULL

  out
}


#' Resolve solution argument in public getters
#'
#' @noRd
.pa_resolve_solution_arg <- function(solution = NULL,
                                     ...,
                                     caller = "this function") {
  dots <- list(...)

  if ("run" %in% names(dots)) {
    if (!is.null(solution)) {
      stop(
        "Use either `solution` or deprecated `run`, not both.",
        call. = FALSE
      )
    }

    lifecycle::deprecate_warn(
      "1.1.0",
      paste0(caller, "(run = )"),
      paste0(caller, "(solution = )")
    )

    solution <- dots$run
    dots$run <- NULL
  }

  if ("solution_id" %in% names(dots)) {
    if (!is.null(solution)) {
      stop(
        "Use either `solution` or deprecated `solution_id`, not both.",
        call. = FALSE
      )
    }

    lifecycle::deprecate_warn(
      "1.1.0",
      paste0(caller, "(solution_id = )"),
      paste0(caller, "(solution = )")
    )

    solution <- dots$solution_id
    dots$solution_id <- NULL
  }

  if (length(dots) > 0L) {
    stop(
      "Unused argument(s): ",
      paste(names(dots), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (is.null(solution)) {
    return(NULL)
  }

  solution <- as.integer(solution)[1]

  if (!is.finite(solution) || is.na(solution) || solution < 1L) {
    stop(
      "`solution` must be a positive integer solution id.",
      call. = FALSE
    )
  }

  solution
}


#' Filter a SolutionSet summary table by solution id
#'
#' @noRd
.pa_filter_summary_by_solution <- function(x,
                                           tab,
                                           solution = NULL,
                                           table_name = "summary") {
  if (is.null(solution)) {
    return(tab)
  }

  if (!("solution_id" %in% names(tab))) {
    stop(
      table_name,
      " has no 'solution_id' column.",
      call. = FALSE
    )
  }

  sid <- suppressWarnings(as.integer(tab$solution_id))

  out <- tab[
    !is.na(sid) & sid == solution,
    ,
    drop = FALSE
  ]

  if (nrow(out) == 0L) {
    stop(
      "No rows found in ",
      table_name,
      " for solution = ",
      solution,
      ".",
      call. = FALSE
    )
  }

  out
}


.pa_drop_run_id_if_solution_id_present <- function(tab) {
  if (!inherits(tab, "data.frame")) {
    return(tab)
  }

  if ("solution_id" %in% names(tab) && "run_id" %in% names(tab)) {
    tab$run_id <- NULL
  }

  tab
}
