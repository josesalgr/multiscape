#' @include internalMO.R


#' @title Get planning-unit results from a solution set
#'
#' @description
#' Extract the planning-unit summary table from a \code{\link{solutionset-class}}
#' object returned by \code{\link{solve}}.
#'
#' The returned table summarizes solution values at the planning-unit level and
#' typically includes a \code{selected} indicator showing whether each planning
#' unit is selected in a run.
#'
#' @details
#' This function reads the planning-unit summary stored in
#' \code{x$summary$pu}. It does not reconstruct the table from the raw decision
#' vector; it simply returns the stored summary after optional filtering.
#'
#' Let \eqn{w_i} denote the planning-unit selection variable for planning unit
#' \eqn{i}. In standard \pkg{multiscape} workflows, the \code{selected} column
#' is the user-facing representation of that planning-unit decision, typically
#' coded as \code{0} or \code{1}.
#'
#' If \code{run} is provided, only rows belonging to that run are returned. This
#' requires the summary table to contain a \code{run_id} column.
#'
#' If \code{only_selected = TRUE}, only rows with \code{selected == 1} are
#' returned. This requires the summary table to contain a \code{selected}
#' column.
#'
#' This function is intended for user-facing inspection of planning-unit results.
#' For the raw model variable vector, use \code{\link{get_solution_vector}}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param only_selected Logical. If \code{TRUE}, return only rows where
#'   \code{selected == 1}. Default is \code{FALSE}.
#' @param run Optional positive integer giving the run index to extract. If
#'   \code{NULL}, all runs are returned when available.
#'
#' @return A \code{data.frame} containing the stored planning-unit summary.
#'   Typical columns include planning-unit identifiers, optional labels, and a
#'   \code{selected} indicator.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   pu_tbl <- data.frame(
#'     id = 1:4,
#'     cost = c(1, 2, 3, 4)
#'   )
#'
#'   feat_tbl <- data.frame(
#'     id = 1:2,
#'     name = c("feature_1", "feature_2")
#'   )
#'
#'   dist_feat_tbl <- data.frame(
#'     pu = c(1, 1, 2, 3, 4),
#'     feature = c(1, 2, 2, 1, 2),
#'     amount = c(5, 2, 3, 4, 1)
#'   )
#'
#'   p <- create_problem(
#'     pu = pu_tbl,
#'     features = feat_tbl,
#'     dist_features = dist_feat_tbl,
#'     cost = "cost"
#'   ) |>
#'     add_constraint_targets_relative(0.2) |>
#'     add_objective_min_cost() |>
#'     set_solver_cbc(time_limit = 10)
#'
#'   solset <- solve(p)
#'
#'   get_pu(solset)
#'   get_pu(solset, only_selected = TRUE)
#' }
#' }
#'
#' @seealso
#' \code{\link{get_actions}},
#' \code{\link{get_features}},
#' \code{\link{get_targets}},
#' \code{\link{get_solution_vector}}
#'
#' @export
get_pu <- function(x, only_selected = FALSE, run = NULL) {

  if (!inherits(x, c("SolutionSet", "Solution"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  pu <- x$summary$pu %||% NULL
  if (is.null(pu)) {
    stop("No PU summary found (x$summary$pu is NULL).", call. = FALSE)
  }

  if (inherits(x, "SolutionSet") && !is.null(run)) {
    run <- as.integer(run)[1]
    if (!is.finite(run) || is.na(run) || run < 1L) {
      stop("run must be a positive integer (1-based).", call. = FALSE)
    }
    if (!("run_id" %in% names(pu))) {
      stop("PU summary has no 'run_id' column.", call. = FALSE)
    }
    pu <- pu[pu$run_id == run, , drop = FALSE]
  }

  if (isTRUE(only_selected)) {
    if (!("selected" %in% names(pu))) {
      stop("PU summary has no 'selected' column.", call. = FALSE)
    }
    pu <- pu[pu$selected == 1L, , drop = FALSE]
  }

  pu
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
#' in a run.
#'
#' @details
#' This function reads the action summary stored in \code{x$summary$actions}. It
#' does not reconstruct the table from the raw decision vector; it simply
#' returns the stored summary after optional filtering.
#'
#' Let \eqn{x_{ia}} denote the decision variable associated with selecting
#' action \eqn{a} in planning unit \eqn{i}. In standard \pkg{multiscape}
#' workflows, the \code{selected} column is the user-facing representation of
#' that decision, typically coded as \code{0} or \code{1}.
#'
#' If \code{run} is provided, only rows belonging to that run are returned. This
#' requires the summary table to contain a \code{run_id} column.
#'
#' If \code{only_selected = TRUE}, only rows with \code{selected == 1} are
#' returned. This requires the summary table to contain a \code{selected}
#' column.
#'
#' This function is intended for user-facing inspection of action allocations.
#' For the raw model variable vector, use \code{\link{get_solution_vector}}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param only_selected Logical. If \code{TRUE}, return only rows where
#'   \code{selected == 1}. Default is \code{FALSE}.
#' @param run Optional positive integer giving the run index to extract. If
#'   \code{NULL}, all runs are returned when available.
#'
#' @return A \code{data.frame} containing the stored action-allocation summary.
#'   Typical columns include planning-unit ids, action ids, optional labels, and
#'   a \code{selected} indicator.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   pu_tbl <- data.frame(
#'     id = 1:4,
#'     cost = c(1, 2, 3, 4)
#'   )
#'
#'   feat_tbl <- data.frame(
#'     id = 1:2,
#'     name = c("feature_1", "feature_2")
#'   )
#'
#'   dist_feat_tbl <- data.frame(
#'     pu = c(1, 1, 2, 3, 4),
#'     feature = c(1, 2, 2, 1, 2),
#'     amount = c(5, 2, 3, 4, 1)
#'   )
#'
#'   actions_df <- data.frame(
#'     id = c("conservation", "restoration"),
#'     name = c("conservation", "restoration")
#'   )
#'
#'   effects_df <- data.frame(
#'     action = rep(c("conservation", "restoration"), each = 2),
#'     feature = rep(feat_tbl$id, times = 2),
#'     multiplier = c(1.0, 1.0, 1.5, 1.5)
#'   )
#'
#'   p <- create_problem(
#'     pu = pu_tbl,
#'     features = feat_tbl,
#'     dist_features = dist_feat_tbl,
#'     cost = "cost"
#'   ) |>
#'     add_actions(actions_df, cost = c(conservation = 0, restoration = 2)) |>
#'     add_effects(effects_df, effect_type = "after") |>
#'     add_constraint_targets_relative(0.2) |>
#'     add_objective_min_cost() |>
#'     set_solver_cbc(time_limit = 10)
#'
#'   solset <- solve(p)
#'
#'   get_actions(solset)
#'   get_actions(solset, only_selected = TRUE)
#' }
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_features}},
#' \code{\link{get_targets}},
#' \code{\link{get_solution_vector}}
#'
#' @export
get_actions <- function(x, only_selected = FALSE, run = NULL) {

  if (!inherits(x, c("SolutionSet", "Solution"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  a <- x$summary$actions %||% NULL
  if (is.null(a)) {
    stop("No actions summary found (x$summary$actions is NULL).", call. = FALSE)
  }

  if (inherits(x, "SolutionSet") && !is.null(run)) {
    run <- as.integer(run)[1]
    if (!is.finite(run) || is.na(run) || run < 1L) {
      stop("run must be a positive integer (1-based).", call. = FALSE)
    }
    if (!("run_id" %in% names(a))) {
      stop("Actions summary has no 'run_id' column.", call. = FALSE)
    }
    a <- a[a$run_id == run, , drop = FALSE]
  }

  if (isTRUE(only_selected)) {
    if (!("selected" %in% names(a))) {
      stop("Actions summary has no 'selected' column.", call. = FALSE)
    }
    a <- a[a$selected == 1L, , drop = FALSE]
  }

  a <- a[, setdiff(names(a), c("internal_pu", "internal_action", "internal_row")), drop = FALSE]

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
#' If \code{run} is provided, only rows belonging to that run are returned. If
#' the result contains a \code{run_id} column but only a single run is present and
#' \code{run} was not requested explicitly, the \code{run_id} column is removed
#' for convenience.
#'
#' This function summarizes feature outcomes in the result. It is different from
#' \code{\link{get_targets}}, which focuses on target achievement.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param run Optional positive integer giving the run index to extract. If
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
#' \donttest{
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   pu_tbl <- data.frame(
#'     id = 1:4,
#'     cost = c(1, 2, 3, 4)
#'   )
#'
#'   feat_tbl <- data.frame(
#'     id = 1:2,
#'     name = c("feature_1", "feature_2")
#'   )
#'
#'   dist_feat_tbl <- data.frame(
#'     pu = c(1, 1, 2, 3, 4),
#'     feature = c(1, 2, 2, 1, 2),
#'     amount = c(5, 2, 3, 4, 1)
#'   )
#'
#'   p <- create_problem(
#'     pu = pu_tbl,
#'     features = feat_tbl,
#'     dist_features = dist_feat_tbl,
#'     cost = "cost"
#'   ) |>
#'     add_constraint_targets_relative(0.2) |>
#'     add_objective_min_cost() |>
#'     set_solver_cbc(time_limit = 10)
#'
#'   solset <- solve(p)
#'
#'   get_features(solset)
#' }
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_actions}},
#' \code{\link{get_targets}}
#'
#' @export
get_features <- function(x, run = NULL) {

  if (!inherits(x, c("SolutionSet", "Solution"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  f <- x$summary$features %||% NULL
  if (is.null(f)) {
    stop("No features summary found (x$summary$features is NULL).", call. = FALSE)
  }

  if (inherits(x, "SolutionSet") && !is.null(run)) {
    run <- as.integer(run)[1]

    if (!is.finite(run) || is.na(run) || run < 1L) {
      stop("run must be a positive integer (1-based).", call. = FALSE)
    }

    if (!("run_id" %in% names(f))) {
      stop("Features summary has no 'run_id' column.", call. = FALSE)
    }

    runs_avail <- sort(unique(f$run_id))

    if (!(run %in% runs_avail)) {
      stop(
        "run=", run, " is out of range. Available runs: ",
        paste(runs_avail, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    f <- f[f$run_id == run, , drop = FALSE]
  }

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

  if ("run_id" %in% names(out) &&
      length(unique(out$run_id)) <= 1L &&
      is.null(run)) {
    out$run_id <- NULL
  }

  rownames(out) <- NULL

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
#' If \code{run} is provided, only rows belonging to that run are returned. If
#' the result contains a \code{run_id} column but only a single run is present and
#' \code{run} was not requested explicitly, the \code{run_id} column is removed
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
#' @param run Optional positive integer giving the run index to extract. If
#'   \code{NULL}, all runs are returned when available.
#'
#' @return A simplified \code{data.frame} target summary, or \code{NULL} if the
#'   result does not contain targets. Typical columns include \code{feature},
#'   \code{feature_name}, \code{target_level}, \code{total_available},
#'   \code{target}, \code{achieved}, \code{gap}, and \code{met}.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   pu_tbl <- data.frame(
#'     id = 1:4,
#'     cost = c(1, 2, 3, 4)
#'   )
#'
#'   feat_tbl <- data.frame(
#'     id = 1:2,
#'     name = c("feature_1", "feature_2")
#'   )
#'
#'   dist_feat_tbl <- data.frame(
#'     pu = c(1, 1, 2, 3, 4),
#'     feature = c(1, 2, 2, 1, 2),
#'     amount = c(5, 2, 3, 4, 1)
#'   )
#'
#'   p <- create_problem(
#'     pu = pu_tbl,
#'     features = feat_tbl,
#'     dist_features = dist_feat_tbl,
#'     cost = "cost"
#'   ) |>
#'     add_constraint_targets_relative(0.2) |>
#'     add_objective_min_cost() |>
#'     set_solver_cbc(time_limit = 10)
#'
#'   solset <- solve(p)
#'
#'   get_targets(solset)
#' }
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_actions}},
#' \code{\link{get_features}}
#'
#' @export
get_targets <- function(x, run = NULL) {

  if (!inherits(x, c("SolutionSet", "Solution"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  t <- x$summary$targets %||% NULL
  if (is.null(t)) {
    return(NULL)
  }

  if (inherits(x, "SolutionSet") && !is.null(run)) {
    run <- as.integer(run)[1]
    if (!is.finite(run) || is.na(run) || run < 1L) {
      stop("run must be a positive integer (1-based).", call. = FALSE)
    }
    if (!("run_id" %in% names(t))) {
      stop("Targets summary has no 'run_id' column.", call. = FALSE)
    }
    t <- t[t$run_id == run, , drop = FALSE]
  }

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

  if ("run_id" %in% names(out) && length(unique(out$run_id)) <= 1L && is.null(run)) {
    out$run_id <- NULL
  }

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
#' @param run Optional positive integer giving the run id to extract. If
#'   \code{NULL}, the first stored solution is used unless \code{solution_id}
#'   is supplied.
#' @param solution_id Optional character string giving the solution id to
#'   extract. If supplied, \code{run} must be \code{NULL}.
#'
#' @return A numeric vector with one value per internal model variable.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   pu_tbl <- data.frame(
#'     id = 1:4,
#'     cost = c(1, 2, 3, 4)
#'   )
#'
#'   feat_tbl <- data.frame(
#'     id = 1:2,
#'     name = c("feature_1", "feature_2")
#'   )
#'
#'   dist_feat_tbl <- data.frame(
#'     pu = c(1, 1, 2, 3, 4),
#'     feature = c(1, 2, 2, 1, 2),
#'     amount = c(5, 2, 3, 4, 1)
#'   )
#'
#'   p <- create_problem(
#'     pu = pu_tbl,
#'     features = feat_tbl,
#'     dist_features = dist_feat_tbl,
#'     cost = "cost"
#'   ) |>
#'     add_constraint_targets_relative(0.2) |>
#'     add_objective_min_cost() |>
#'     set_solver_cbc(time_limit = 10)
#'
#'   solset <- solve(p)
#'
#'   v <- get_solution_vector(solset)
#'   v
#'   length(v)
#' }
#' }
#'
#' @seealso
#' \code{\link{get_pu}},
#' \code{\link{get_actions}},
#' \code{\link{get_features}},
#' \code{\link{get_targets}}
#'
#' @export
get_solution_vector <- function(x, run = NULL, solution_id = NULL) {

  if (!inherits(x, c("SolutionSet", "Solution"))) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  sol <- .mo_get_solution_from(x, run = run, solution_id = solution_id)

  v <- sol$solution$vector %||% NULL
  if (is.null(v)) {
    stop("No raw decision vector found for the selected solution.", call. = FALSE)
  }

  as.numeric(v)
}


#' Get run-level results from a solution set
#'
#' @description
#' Extract the run-level summary table from a
#' \code{\link{solutionset-class}} object returned by \code{\link{solve}}.
#'
#' @param x A \code{\link{solutionset-class}} object.
#' @param feasible_only Logical. If \code{TRUE}, return only runs with solver
#'   status interpreted as feasible or successful.
#'
#' @return A \code{data.frame} with one row per run.
#'
#' @export
get_runs <- function(x, feasible_only = FALSE) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  runs <- x$solution$runs %||% NULL

  if (is.null(runs) || !inherits(runs, "data.frame")) {
    stop("No run table found in x$solution$runs.", call. = FALSE)
  }

  out <- runs

  if (isTRUE(feasible_only)) {
    if (!("status" %in% names(out))) {
      stop("Cannot filter feasible runs because the run table has no 'status' column.", call. = FALSE)
    }

    feasible_status <- c(
      "optimal",
      "feasible",
      "suboptimal",
      "time_limit",
      "gap_limit"
    )

    out <- out[
      tolower(as.character(out$status)) %in% feasible_status,
      ,
      drop = FALSE
    ]
  }

  first <- intersect(c("run_id", "solution_id", "status"), names(out))
  rest <- setdiff(names(out), first)
  out <- out[, c(first, rest), drop = FALSE]

  rownames(out) <- NULL
  out
}


#' Get objective values from a solution set
#'
#' @description
#' Extract objective values from a \code{\link{solutionset-class}} object
#' returned by \code{\link{solve}}.
#'
#' Objective values are read from run-table columns named
#' \code{value_<objective>}, where \code{<objective>} is the objective alias.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param format Character. Either \code{"long"} or \code{"wide"}.
#' @param feasible_only Logical. If \code{TRUE}, use only feasible runs.
#'
#' @return
#' If \code{format = "long"}, a \code{data.frame} with columns
#' \code{run_id}, \code{solution_id}, \code{objective}, and \code{value}.
#'
#' If \code{format = "wide"}, a \code{data.frame} with one row per run,
#' columns \code{run_id} and \code{solution_id}, and one column per objective.
#'
#' @export
get_objectives <- function(x,
                           format = c("long", "wide"),
                           feasible_only = FALSE) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  format <- match.arg(format)

  runs <- get_runs(x, feasible_only = feasible_only)

  value_cols <- grep("^value_", names(runs), value = TRUE)

  if (length(value_cols) == 0L) {
    stop(
      "No objective value columns found in the run table. ",
      "Expected columns named 'value_<objective>'.",
      call. = FALSE
    )
  }

  if (!("run_id" %in% names(runs))) {
    runs$run_id <- seq_len(nrow(runs))
  }

  if (!("solution_id" %in% names(runs))) {
    runs$solution_id <- NA_character_
  }

  objectives <- sub("^value_", "", value_cols)

  if (identical(format, "wide")) {
    out <- runs[, c("run_id", "solution_id", value_cols), drop = FALSE]
    names(out) <- c("run_id", "solution_id", objectives)
    rownames(out) <- NULL
    return(out)
  }

  out <- do.call(
    rbind,
    lapply(seq_along(value_cols), function(i) {
      data.frame(
        run_id = runs$run_id,
        solution_id = runs$solution_id,
        objective = objectives[i],
        value = as.numeric(runs[[value_cols[i]]]),
        stringsAsFactors = FALSE
      )
    })
  )

  rownames(out) <- NULL
  out
}


#' Get objective specifications from a solution set
#'
#' @description
#' Extract objective aliases, model types, objective ids, optimization senses,
#' and objective arguments from a \code{\link{solutionset-class}} object.
#'
#' Objective specifications are read from the original \code{Problem} object
#' stored in the \code{SolutionSet}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @return A \code{data.frame} with one row per registered objective.
#'
#' @export
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
