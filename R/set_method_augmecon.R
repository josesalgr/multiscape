#' @include internalMO.R
#'
#' @title Set the AUGMECON multi-objective method
#'
#' @description
#' Configure a \code{Problem} object to be solved with the augmented
#' epsilon-constraint method (AUGMECON).
#'
#' AUGMECON is an exact multi-objective optimization method in which one
#' objective is treated as the primary objective and the remaining objectives
#' are converted into \eqn{\varepsilon}-constraints. In the augmented
#' formulation, each secondary objective is associated with a non-negative
#' slack variable, and the primary objective is augmented with a small reward
#' term based on the normalized slacks. This augmentation is used to avoid
#' weakly efficient solutions, following Mavrotas (2009).
#'
#' This function does not solve the problem directly. It stores the AUGMECON
#' configuration in \code{x$data$method}, to be used later by
#' \code{\link{solve}}.
#'
#' @details
#' Use this method when one objective should be optimized directly, the
#' remaining objectives should be controlled through epsilon levels, and weakly
#' efficient solutions should be reduced through the augmented formulation.
#'
#' \strong{General idea}
#'
#' Suppose that \eqn{m \ge 2} objective functions have already been registered
#' in the problem:
#' \deqn{
#' f_1(x), f_2(x), \dots, f_m(x).
#' }
#'
#' AUGMECON selects one of them as the primary objective, say
#' \eqn{f_p(x)}, and treats the remaining \eqn{m - 1} objectives as secondary
#' objectives.
#'
#' For a fixed combination of epsilon levels, the method solves a
#' single-objective subproblem of the form:
#'
#' \deqn{
#' \max \; f_p(x) + \rho \sum_{k \in \mathcal{S}} \frac{s_k}{R_k}
#' }
#'
#' subject to
#'
#' \deqn{
#' f_k(x) - s_k = \varepsilon_k, \qquad k \in \mathcal{S},
#' }
#'
#' \deqn{
#' s_k \ge 0, \qquad k \in \mathcal{S},
#' }
#'
#' together with all original feasibility constraints of the planning problem.
#'
#' Here:
#' \itemize{
#'   \item \eqn{f_p(x)} is the primary objective,
#'   \item \eqn{\mathcal{S}} is the set of secondary objectives,
#'   \item \eqn{\varepsilon_k} is the imposed level for secondary objective
#'   \eqn{k},
#'   \item \eqn{s_k} is a non-negative slack variable,
#'   \item \eqn{R_k} is the payoff-table range used to normalize objective
#'   \eqn{k},
#'   \item \eqn{\rho > 0} is a small augmentation coefficient.
#' }
#'
#' In the original AUGMECON formulation of Mavrotas (2009), the augmentation
#' term ensures that, among solutions with the same primary objective value, the
#' solver prefers those with larger normalized slack, thereby avoiding weakly
#' efficient points and improving Pareto-front generation.
#'
#' \strong{Secondary-objective equalities and slacks}
#'
#' The key difference between standard epsilon-constraint and AUGMECON is that
#' the secondary objectives are written as equalities with slacks rather than as
#' simple inequalities. For a maximization-type secondary objective, this takes
#' the form:
#'
#' \deqn{
#' f_k(x) - s_k = \varepsilon_k, \qquad s_k \ge 0.
#' }
#'
#' This implies:
#' \deqn{
#' f_k(x) \ge \varepsilon_k,
#' }
#'
#' while explicitly measuring the excess above the imposed epsilon level through
#' \eqn{s_k}. The augmentation term then rewards such excess in normalized form.
#'
#' In implementation terms, the exact sign convention for each objective depends
#' on whether it is internally treated as a minimization or maximization
#' objective, but the method always preserves the same AUGMECON principle:
#' \itemize{
#'   \item one objective is optimized directly,
#'   \item all others are turned into constrained objectives,
#'   \item non-negative slacks measure controlled deviation from the imposed
#'   epsilon levels,
#'   \item the primary objective is augmented with a small slack-based reward.
#' }
#'
#' \strong{Run designs}
#'
#' AUGMECON runs are specified through the \code{runs} argument. This argument
#' must be created with either \code{\link{set_runs_grid}} or
#' \code{\link{set_runs_manual}}.
#'
#' \code{set_runs_grid(n = ...)} requests automatic generation of epsilon
#' levels for the secondary objectives during \code{\link{solve}}. In that case,
#' the method first computes extreme points and payoff-table ranges for the
#' secondary objectives, and then generates \code{n} levels for each one.
#'
#' Boundary epsilon levels are always included in automatic grids. Therefore,
#' the lower and upper bounds of the automatically derived epsilon ranges are
#' part of the generated run design.
#'
#' \code{set_runs_manual()} allows users to provide explicit epsilon
#' combinations. In manual AUGMECON runs, each row is one optimization run and
#' columns must be named \code{eps_<alias>}, where \code{<alias>} is the alias of
#' a secondary objective. For example, if \code{primary = "benefit"} and
#' \code{aliases = c("benefit", "cost", "loss")}, the manual run table must
#' contain columns \code{eps_cost} and \code{eps_loss}.
#'
#' In \code{set_runs_manual()}, each row is used exactly as supplied. The
#' function does not automatically create a Cartesian product of epsilon values.
#' If a Cartesian product is desired, it should be created explicitly by the
#' user, for example with \code{\link{expand.grid}}, and then passed to
#' \code{set_runs_manual()}.
#'
#' The older arguments \code{grid}, \code{n_points}, and
#' \code{include_extremes} are deprecated. They are still accepted for backwards
#' compatibility and are internally converted to \code{set_runs_grid()} or
#' \code{set_runs_manual()} designs. The deprecated \code{include_extremes}
#' argument is ignored because automatic run grids now always include boundary
#' levels.
#'
#' \strong{Automatic epsilon grids}
#'
#' When \code{runs = set_runs_grid(n = ...)} is used, the epsilon design is not
#' built immediately. Instead, it is constructed later during
#' \code{\link{solve}} using extreme-point or payoff-table information.
#'
#' For each secondary objective, \code{set_runs_grid()} generates a sequence of
#' epsilon levels. With multiple secondary objectives, the final AUGMECON design
#' is the Cartesian product of these sequences. Therefore, the number of runs
#' can grow quickly as the number of secondary objectives increases.
#'
#' If \code{lexicographic = TRUE}, extreme points are computed using
#' lexicographic anchoring, which can improve payoff-table quality when
#' objectives are tightly competing. The tolerance used for lexicographic
#' anchoring is controlled by \code{lexicographic_tol}.
#'
#' \strong{Manual epsilon runs}
#'
#' Manual run designs are the most explicit way to use AUGMECON, especially
#' when more than two objectives are involved or when only selected epsilon
#' combinations should be explored.
#'
#' For example, with one primary objective and two secondary objectives, a
#' manual run design may contain:
#' \preformatted{
#' data.frame(
#'   eps_cost = c(4, 6, 8),
#'   eps_loss = c(0, 1, 1)
#' )
#' }
#'
#' This creates three runs, not a full Cartesian grid. To create all
#' combinations, use \code{expand.grid()} before calling
#' \code{set_runs_manual()}.
#'
#' \strong{Normalization and augmentation}
#'
#' The augmentation term is scaled using the payoff-table ranges of the
#' secondary objectives. If \eqn{R_k} denotes the range of secondary objective
#' \eqn{k}, then the effective coefficient applied to the slack is:
#'
#' \deqn{
#' \frac{\rho}{R_k},
#' }
#'
#' where \eqn{\rho = \code{augmentation}}.
#'
#' This normalization is important because different objectives may be measured
#' on very different numerical scales. Without normalization, a slack belonging
#' to a large-scale objective could dominate the augmentation term simply due to
#' units.
#'
#' In this implementation, the user supplies \code{augmentation} as the base
#' coefficient \eqn{\rho}, while the normalized slack coefficients are computed
#' internally at solve time using the corresponding payoff-table ranges.
#'
#' \strong{Failure handling}
#'
#' The \code{control} argument controls how failed runs are handled. It must be
#' created with \code{\link{set_runs_control}}.
#'
#' Some epsilon combinations may define infeasible subproblems. By default,
#' failed runs can be retained in the returned \code{SolutionSet} with missing
#' objective values, while feasible runs are preserved. Alternatively, users can
#' request that the solve stops when an infeasible run, a run without a solution,
#' or an unexpected error is encountered.
#'
#' \strong{AUGMECON slack upper bound}
#'
#' \code{slack_upper_bound} defines an explicit upper bound for slack variables
#' introduced by the AUGMECON formulation. The value should be sufficiently large
#' to avoid excluding valid solutions, but unnecessarily large bounds can weaken
#' the mixed-integer formulation and reduce numerical performance.
#'
#' When possible, a problem-specific bound based on the ranges of the constrained
#' objectives should be used.
#'
#' \strong{Stored configuration}
#'
#' This function stores the method definition in \code{x$data$method} with:
#' \itemize{
#'   \item \code{name = "augmecon"},
#'   \item \code{type = "augmecon"},
#'   \item the primary objective alias,
#'   \item the full set of participating aliases,
#'   \item the set of secondary aliases,
#'   \item \code{runs},
#'   \item lexicographic configuration,
#'   \item \code{augmentation},
#'   \item \code{slack_upper_bound},
#'   \item \code{control}.
#' }
#'
#' The actual payoff table, grid construction, and subproblem solution loop are
#' performed later by \code{\link{solve}}.
#'
#' @param x A \code{Problem} object.
#'
#' @param primary Character string giving the alias of the primary objective,
#'   that is, the objective optimized directly in the AUGMECON formulation.
#'
#' @param aliases Optional character vector of objective aliases to include in
#'   the method. If \code{NULL}, all registered objective aliases are used. The
#'   value of \code{primary} must be included in \code{aliases}.
#'
#' @param runs A run design created with \code{\link{set_runs_grid}} or
#'   \code{\link{set_runs_manual}}. For AUGMECON,
#'   \code{set_runs_grid()} requests automatic epsilon-level generation for
#'   secondary objectives, while \code{set_runs_manual()} requires columns named
#'   \code{eps_<alias>} for each secondary objective.
#'
#' @param grid Deprecated. Previous manual-grid argument. It must be a named
#'   list with one numeric vector per secondary objective. New code should use
#'   \code{runs = set_runs_manual(...)} instead.
#'
#' @param n_points Deprecated. Previous automatic-grid argument. New code should
#'   use \code{runs = set_runs_grid(n = ...)} instead.
#'
#' @param include_extremes Deprecated and ignored. Automatic run grids now
#'   always include boundary levels. New code should use
#'   \code{runs = set_runs_grid(n = ...)}.
#'
#' @param lexicographic Logical. If \code{TRUE}, use lexicographic anchoring
#'   when computing extreme points for automatic grid construction.
#'
#' @param lexicographic_tol Non-negative numeric tolerance used in
#'   lexicographic anchoring.
#'
#' @param augmentation Positive numeric augmentation coefficient
#'   \eqn{\rho}. The effective coefficient of each secondary slack is computed
#'   internally as \eqn{\rho / R_k}, where \eqn{R_k} is the payoff-table range
#'   of the corresponding secondary objective.
#'
#' @param slack_upper_bound A single positive finite numeric value defining the
#'   upper bound of AUGMECON slack variables. Defaults to \code{1e6}.
#'
#' @param control A control object created with
#'   \code{\link{set_runs_control}}. It controls how infeasible runs, runs
#'   without a solution, and unexpected errors are handled.
#'
#' @return The updated \code{Problem} object with the AUGMECON method
#'   configuration stored in \code{x$data$method}.
#'
#' @references
#' Mavrotas, G. (2009). Effective implementation of the
#' \eqn{\varepsilon}-constraint method in multi-objective mathematical
#' programming problems. \emph{Applied Mathematics and Computation}, 213(2),
#' 455--465.
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
#'   add_objective_max_benefit(alias = "benefit") |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_min_loss(alias = "loss")
#'
#' # Automatic epsilon grids generated later during solve()
#' x1 <- set_method_augmecon(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   runs = set_runs_grid(n = 5),
#'   lexicographic = TRUE,
#'   augmentation = 1e-3
#' )
#'
#' x1$data$method
#'
#' # Manual runs for one secondary objective
#' aug_runs <- data.frame(
#'   eps_cost = c(4, 6, 8)
#' )
#'
#' x2 <- set_method_augmecon(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   runs = set_runs_manual(aug_runs),
#'   augmentation = 1e-3
#' )
#'
#' x2$data$method
#'
#' # Manual runs for two secondary objectives
#' aug_runs_3obj <- data.frame(
#'   eps_cost = c(4, 6, 8),
#'   eps_loss = c(0, 1, 1)
#' )
#'
#' x3 <- set_method_augmecon(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost", "loss"),
#'   runs = set_runs_manual(aug_runs_3obj),
#'   augmentation = 1e-3
#' )
#'
#' x3$data$method
#'
#' # Cartesian epsilon design created explicitly by the user
#' aug_cartesian <- expand.grid(
#'   eps_cost = c(4, 6, 8),
#'   eps_loss = c(0, 1),
#'   KEEP.OUT.ATTRS = FALSE
#' )
#'
#' x4 <- set_method_augmecon(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost", "loss"),
#'   runs = set_runs_manual(aug_cartesian),
#'   augmentation = 1e-3
#' )
#'
#' x4$data$method
#'
#' # Backwards-compatible deprecated usage
#' x5 <- set_method_augmecon(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost", "loss"),
#'   grid = list(
#'     cost = c(4, 6, 8),
#'     loss = c(0, 1)
#'   ),
#'   augmentation = 1e-3
#' )
#'
#' x5$data$method
#'
#' # Control failure handling and the AUGMECON slack upper bound
#' x6 <- set_method_augmecon(
#'   x,
#'   primary = "benefit",
#'   aliases = c("benefit", "cost"),
#'   runs = set_runs_manual(data.frame(eps_cost = c(4, 6, 8))),
#'   augmentation = 1e-3,
#'   slack_upper_bound = 1e6,
#'   control = set_runs_control(
#'     stop_on_infeasible = FALSE,
#'     stop_on_no_solution = FALSE,
#'     stop_on_error = TRUE
#'   )
#' )
#'
#' x6$data$method
#'
#' @seealso
#' \code{\link{set_runs_grid}},
#' \code{\link{set_runs_manual}},
#' \code{\link{set_runs_control}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{solve}}
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
