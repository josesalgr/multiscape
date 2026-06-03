#' @title Set the epsilon-constraint multi-objective method
#'
#' @description
#' Configure a \code{Problem} object to be solved with the
#' epsilon-constraint multi-objective method.
#'
#' In this method, one objective is designated as the \emph{primary} objective
#' and is optimized directly, while the remaining objectives are transformed
#' into \eqn{\varepsilon}-constraints. Multiple subproblems are generated using
#' a run design supplied through \code{runs}.
#'
#' This function does not solve the problem. It stores the method configuration
#' in \code{x$data$method}, to be used later by \code{\link{solve}}.
#'
#' @details
#' Use this method when one objective should be optimized directly while the
#' remaining objectives are controlled through explicit performance thresholds.
#'
#' \strong{General idea}
#'
#' Suppose that \eqn{m \ge 2} objective functions have already been registered
#' in the problem:
#' \deqn{
#' f_1(x), f_2(x), \dots, f_m(x).
#' }
#'
#' The epsilon-constraint method selects one of them as the primary objective,
#' say \eqn{f_p(x)}, and treats the remaining objectives as constrained
#' objectives.
#'
#' For a fixed vector of epsilon levels, the method solves subproblems in which
#' the primary objective is optimized directly and the remaining objectives are
#' imposed through epsilon constraints.
#'
#' A representative formulation is:
#'
#' \deqn{
#' \max \; f_p(x)
#' }
#'
#' subject to
#'
#' \deqn{
#' f_k(x) \ge \varepsilon_k, \qquad k \in \mathcal{C},
#' }
#'
#' together with all original feasibility constraints of the planning problem,
#' where \eqn{\mathcal{C}} is the set of constrained objectives.
#'
#' Depending on the sense of each objective, the internal implementation may
#' transform minimization and maximization objectives into equivalent
#' solver-ready constrained forms. The method always follows the same principle:
#' \itemize{
#'   \item one objective is optimized directly,
#'   \item all remaining objectives are imposed through
#'   \eqn{\varepsilon}-constraints.
#' }
#'
#' By solving the problem repeatedly for different epsilon levels, the method
#' generates a set of trade-off solutions.
#'
#' \strong{Run designs}
#'
#' Epsilon-constraint runs are specified through the \code{runs} argument. This
#' argument must be created with either \code{\link{run_grid}} or
#' \code{\link{run_manual}}.
#'
#' \code{run_grid(n = ...)} requests automatic generation of epsilon levels
#' during \code{\link{solve}}. The epsilon levels are computed from
#' extreme-point or payoff information. In the current implementation,
#' \code{run_grid()} for epsilon-constraint supports exactly two objectives:
#' one primary objective and one constrained objective.
#'
#' \code{run_manual()} allows users to provide explicit epsilon combinations.
#' In manual epsilon-constraint runs, each row is one optimization run and
#' columns must be named \code{eps_<alias>}, where \code{<alias>} is the alias of
#' a constrained objective. For example, if \code{primary = "benefit"} and
#' \code{aliases = c("benefit", "cost", "loss")}, the manual run table must
#' contain columns \code{eps_cost} and \code{eps_loss}.
#'
#' In \code{run_manual()}, each row is used exactly as supplied. The function
#' does not automatically create a Cartesian product of epsilon values. If a
#' Cartesian product is desired, it should be created explicitly by the user,
#' for example with \code{\link{expand.grid}}, and then passed to
#' \code{run_manual()}.
#'
#' The older arguments \code{eps}, \code{mode}, \code{n_points}, and
#' \code{include_extremes} are deprecated. They are still accepted for
#' backwards compatibility and are internally converted to \code{run_grid()} or
#' \code{run_manual()} designs.
#'
#' \strong{Atomic objectives requirement}
#'
#' The epsilon-constraint method can only be used with atomic objectives that
#' have already been registered under aliases. These aliases are typically
#' created by calling objective setters with an \code{alias} argument, for
#' example:
#' \preformatted{
#' x <- x |>
#'   add_objective_max_benefit(alias = "benefit") |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_min_fragmentation(alias = "frag")
#' }
#'
#' The \code{primary} argument selects which registered objective is optimized
#' directly. The remaining aliases are treated as constrained objectives.
#'
#' \strong{Automatic epsilon grids}
#'
#' When \code{runs = run_grid(n = ...)} is used, the epsilon grid is not built
#' immediately. Instead, it is constructed later during \code{\link{solve}}
#' using extreme-point or payoff information.
#'
#' In the current implementation, automatic epsilon-grid generation supports
#' exactly two objectives:
#' \itemize{
#'   \item one primary objective,
#'   \item one constrained objective.
#' }
#'
#' Therefore, if \code{runs = run_grid(...)}, then \code{aliases} must contain
#' exactly two objective aliases. Problems with three or more objectives must
#' use \code{runs = run_manual(...)}.
#'
#' If \code{include_extremes = TRUE} is supplied inside \code{run_grid()}, the
#' automatically generated grid includes the extreme values of the constrained
#' objective. Otherwise, only interior values are used.
#'
#' If \code{lexicographic = TRUE}, the extreme points used to generate the grid
#' are computed lexicographically. In that case, one objective is optimized
#' first, and then the second objective is optimized while constraining the
#' first to remain within \code{lexicographic_tol} of its optimum.
#'
#' \strong{Manual epsilon runs}
#'
#' Manual run designs support two or more objectives. They are the general way
#' to use the epsilon-constraint method when more than two objectives are
#' involved.
#'
#' For example, with one primary objective and two constrained objectives,
#' a manual run design may contain:
#' \preformatted{
#' data.frame(
#'   eps_cost = c(4, 6, 8),
#'   eps_loss = c(0, 1, 1)
#' )
#' }
#'
#' This creates three runs, not a full Cartesian grid. To create all
#' combinations, use \code{expand.grid()} before calling \code{run_manual()}.
#'
#' \strong{Failure handling}
#'
#' The \code{control} argument controls how failed runs are handled. It must be
#' created with \code{\link{mo_control}}.
#'
#' Some epsilon levels may define infeasible subproblems. By default, failed
#' runs can be retained in the returned \code{SolutionSet} with missing
#' objective values, while feasible runs are preserved. Alternatively, users can
#' request that the solve stops when an infeasible run, a run without a solution,
#' or an unexpected error is encountered.
#'
#' \strong{Stored configuration}
#'
#' The configured method stores:
#' \itemize{
#'   \item \code{name = "epsilon_constraint"},
#'   \item \code{type = "epsilon_constraint"},
#'   \item \code{primary},
#'   \item \code{aliases},
#'   \item \code{constrained},
#'   \item \code{runs},
#'   \item lexicographic configuration,
#'   \item \code{control}.
#' }
#'
#' With \code{runs = run_grid(...)}, the actual epsilon design is generated
#' later during \code{\link{solve}}. With \code{runs = run_manual(...)}, the
#' explicit user-supplied run design is stored and then used by
#' \code{\link{solve}}.
#'
#' @param x A \code{Problem} object.
#' @param primary Character string giving the alias of the primary objective to
#'   optimize directly.
#' @param aliases Optional character vector of objective aliases to include.
#'   By default, all registered objective aliases are used. The value of
#'   \code{primary} must be included in \code{aliases}.
#' @param runs A run design created with \code{\link{run_grid}} or
#'   \code{\link{run_manual}}. For epsilon-constraint methods,
#'   \code{run_grid()} requests automatic epsilon-level generation, while
#'   \code{run_manual()} requires columns named \code{eps_<alias>} for each
#'   constrained objective.
#' @param eps Deprecated. Epsilon specification used by the previous
#'   \code{mode = "manual"} interface. It may be a named numeric vector or a
#'   named list of numeric vectors. New code should use
#'   \code{runs = run_manual(...)} instead.
#' @param mode Deprecated. Previous interface selector, either \code{"manual"}
#'   or \code{"auto"}. New code should use \code{runs = run_manual(...)} or
#'   \code{runs = run_grid(...)} instead.
#' @param n_points Deprecated. Previous automatic-grid argument. New code should
#'   use \code{runs = run_grid(n = ...)} instead.
#' @param include_extremes Deprecated. Previous automatic-grid argument. New
#'   code should use \code{runs = run_grid(n = ..., include_extremes = ...)}
#'   instead.
#' @param lexicographic Logical scalar. If \code{TRUE}, compute automatic-grid
#'   extreme points lexicographically when \code{runs = run_grid(...)} is used.
#' @param lexicographic_tol Numeric scalar \eqn{\ge 0}. Tolerance used in
#'   lexicographic extreme-point computation.
#' @param control A control object created with \code{\link{mo_control}}. It
#'   controls how infeasible runs, runs without a solution, and unexpected
#'   errors are handled.
#'
#' @return An updated \code{Problem} object with the epsilon-constraint method
#'   configuration stored in \code{x$data$method}.
#'
#' @examples
#' # Small toy problem
#' pu_tbl <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' feat_tbl <- data.frame(
#'   id = 1:2,
#'   name = c("feature_1", "feature_2")
#' )
#'
#' dist_feat_tbl <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' actions_df <- data.frame(
#'   id = c("conservation", "restoration"),
#'   name = c("conservation", "restoration")
#' )
#'
#' effects_df <- data.frame(
#'   pu = c(1, 2, 3, 4, 1, 2, 3, 4),
#'   action = c("conservation", "conservation", "conservation", "conservation",
#'              "restoration", "restoration", "restoration", "restoration"),
#'   feature = c(1, 1, 1, 1, 2, 2, 2, 2),
#'   benefit = c(2, 1, 0, 1, 3, 0, 1, 2),
#'   loss = c(0, 0, 1, 0, 0, 1, 0, 0)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
#'   cost = "cost"
#' ) |>
#'   add_actions(actions_df, cost = c(conservation = 1, restoration = 2)) |>
#'   add_effects(effects_df) |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_max_benefit(alias = "benefit") |>
#'   add_objective_min_loss(alias = "loss")
#'
#' # Automatic epsilon grid for two objectives
#' x1 <- set_method_epsilon_constraint(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   runs = run_grid(n = 5, include_extremes = TRUE),
#'   lexicographic = TRUE,
#'   lexicographic_tol = 1e-8
#' )
#'
#' x1$data$method
#'
#' # Manual runs with one constrained objective
#' eps_runs <- data.frame(
#'   eps_cost = c(4, 6, 8)
#' )
#'
#' x2 <- set_method_epsilon_constraint(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   runs = run_manual(eps_runs)
#' )
#'
#' x2$data$method
#'
#' # Manual runs with more than two objectives
#' eps_runs_3obj <- data.frame(
#'   eps_cost = c(4, 6, 8),
#'   eps_loss = c(0, 1, 1)
#' )
#'
#' x3 <- set_method_epsilon_constraint(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost", "loss"),
#'   runs = run_manual(eps_runs_3obj)
#' )
#'
#' x3$data$method
#'
#' # Cartesian epsilon design created explicitly by the user
#' eps_cartesian <- expand.grid(
#'   eps_cost = c(4, 6, 8),
#'   eps_loss = c(0, 1),
#'   KEEP.OUT.ATTRS = FALSE
#' )
#'
#' x4 <- set_method_epsilon_constraint(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost", "loss"),
#'   runs = run_manual(eps_cartesian)
#' )
#'
#' x4$data$method
#'
#' # Backwards-compatible deprecated usage
#' x5 <- set_method_epsilon_constraint(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   mode = "manual",
#'   eps = list(cost = c(4, 6, 8))
#' )
#'
#' x5$data$method
#'
#' # Control failure handling
#' x6 <- set_method_epsilon_constraint(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   runs = run_manual(data.frame(eps_cost = c(4, 6, 8))),
#'   control = mo_control(
#'     stop_on_infeasible = FALSE,
#'     stop_on_no_solution = FALSE,
#'     stop_on_error = TRUE
#'   )
#' )
#'
#' x6$data$method
#'
#' @seealso
#' \code{\link{run_grid}},
#' \code{\link{run_manual}},
#' \code{\link{mo_control}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{solve}}
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
                                          control = mo_control()) {
  stopifnot(inherits(x, "Problem"))

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
      stop("`aliases` must be NULL or a non-empty character vector without NA.", call. = FALSE)
    }

    aliases <- as.character(aliases)

    if (any(!nzchar(aliases))) {
      stop("`aliases` must not contain empty strings.", call. = FALSE)
    }

    if (anyDuplicated(aliases) != 0L) {
      dups <- unique(aliases[duplicated(aliases)])
      stop("`aliases` must not contain duplicates: ", paste(dups, collapse = ", "), call. = FALSE)
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
      "Use either `runs` or deprecated arguments (`eps`, `mode`, `n_points`, `include_extremes`), not both.",
      call. = FALSE
    )
  }

  if (is.null(runs) && old_args_used) {
    .pa_deprecate_arg(
      old = "eps/mode/n_points/include_extremes",
      new = "runs = run_grid(...) or runs = run_manual(...)"
    )

    mode <- mode %||% if (!is.null(eps)) "manual" else "auto"
    mode <- match.arg(mode, choices = c("manual", "auto"))

    if (identical(mode, "manual")) {
      if (is.null(eps)) {
        stop("In deprecated `mode = 'manual'`, `eps` must be supplied.", call. = FALSE)
      }

      eps_df <- .pamo_eps_to_manual_df(
        eps = eps,
        constrained = constrained
      )

      runs <- run_manual(eps_df)

    } else {
      n_points <- as.integer(n_points %||% 10L)[1]
      include_extremes <- include_extremes %||% TRUE

      runs <- run_grid(
        n = n_points,
        include_extremes = isTRUE(include_extremes)
      )
    }
  }

  if (is.null(runs)) {
    stop(
      "`runs` must be supplied. Use `runs = run_grid(n = ...)` or `runs = run_manual(...)`.",
      call. = FALSE
    )
  }

  .pamo_check_run_design(runs)

  # Automatic epsilon grid is currently only implemented for 2 objectives.
  # Manual runs can still be used for 3+ objectives.
  if (.pamo_is_run_grid(runs) && length(constrained) != 1L) {
    stop(
      "`runs = run_grid()` for epsilon-constraint currently supports exactly ",
      "one constrained objective. Use `run_manual()` for 3+ objectives.",
      call. = FALSE
    )
  }

  # ---- lexicographic
  if (!is.logical(lexicographic) ||
      length(lexicographic) != 1L ||
      is.na(lexicographic)) {
    stop("`lexicographic` must be TRUE or FALSE.", call. = FALSE)
  }

  lexicographic_tol <- as.numeric(lexicographic_tol)[1]

  if (!is.finite(lexicographic_tol) || lexicographic_tol < 0) {
    stop("`lexicographic_tol` must be a finite non-negative number.", call. = FALSE)
  }

  # ---- control
  .pamo_check_mo_control(control)

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
