#' Define an automatic multi-objective run grid
#'
#' @description
#' Create an automatic run-design specification for generating multiple
#' optimization runs in a multi-objective workflow.
#'
#' `run_grid()` provides a common interface for controlling the resolution of
#' weighted-sum, epsilon-constraint, and AUGMECON run designs. The returned
#' object does not contain the final run table. Instead, it stores the requested
#' grid settings, which are resolved later by the corresponding
#' `set_method_*()` function using the registered objectives and their
#' optimization senses.
#'
#' @details
#' Multi-objective methods generally require several optimization runs to
#' explore different regions of objective space. `run_grid()` asks
#' `multiscape` to generate those runs automatically.
#'
#' The interpretation of the grid depends on the selected method:
#'
#' \itemize{
#'   \item In \code{\link{set_method_weighted_sum}}, the grid defines
#'   combinations of objective weights. The generated weights are normalized
#'   according to the method settings and represent alternative preferences
#'   among the registered objectives.
#'
#'   \item In \code{\link{set_method_epsilon_constraint}}, the grid defines
#'   epsilon levels for the constrained objectives. The primary objective is
#'   optimized directly, while the remaining objectives are progressively
#'   restricted across the generated runs.
#'
#'   \item In \code{\link{set_method_augmecon}}, the grid similarly defines
#'   epsilon levels for the secondary objectives, which are then used in the
#'   augmented epsilon-constraint formulation.
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
#' If \code{include_extremes = TRUE}, the generated design includes settings
#' corresponding to the objective-space extremes whenever they are meaningful
#' for the selected method. For weighted-sum methods, this includes weight
#' combinations that place all weight on a single objective. For
#' epsilon-based methods, it includes the boundary levels of the automatically
#' derived objective ranges.
#'
#' Including extremes is generally recommended because it helps recover the
#' best observed value of each objective and provides reference points for
#' subsequent frontier analyses. However, users may set
#' \code{include_extremes = FALSE} when only interior trade-off solutions are
#' required or when extreme solutions have already been obtained separately.
#'
#' The resolved design is stored in the resulting
#' \code{\link{solutionset-class}} object and can be inspected after solving
#' through \code{\link{get_runs}} or the internal run-design table.
#'
#' Use \code{\link{run_manual}} instead when exact weights or epsilon levels
#' must be supplied explicitly.
#'
#' @param n Integer. Resolution of the automatically generated run design.
#'   Must be at least \code{2}. The final number of optimization runs may differ
#'   from \code{n}, depending on the selected method and the number of
#'   objectives.
#'
#' @param include_extremes Logical. Whether objective-space extreme settings
#'   should be included in the generated design. Defaults to \code{TRUE}.
#'
#' @return An object of class \code{RunGrid} and \code{RunDesign}. The object
#'   stores the requested grid resolution and extreme-point setting and is
#'   intended to be supplied to the \code{runs} argument of a multi-objective
#'   method function.
#'
#' @examples
#' # Create an automatic run-grid specification
#' grid <- run_grid(
#'   n = 5,
#'   include_extremes = TRUE
#' )
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
#'     runs = run_grid(
#'       n = 5,
#'       include_extremes = TRUE
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
#'   # Inspect the resolved run design and objective values
#'   get_runs(solutions)
#'   get_objectives(
#'     solutions,
#'     format = "wide"
#'   )
#' }
#'
#'
#' @seealso
#' \code{\link{run_manual}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{get_runs}}
#'
#' @export
run_grid <- function(n, include_extremes = TRUE) {
  n <- as.integer(n)[1]

  if (!is.finite(n) || is.na(n) || n < 2L) {
    stop("`n` must be an integer >= 2.", call. = FALSE)
  }

  if (
    !is.logical(include_extremes) ||
    length(include_extremes) != 1L ||
    is.na(include_extremes)
  ) {
    stop(
      "`include_extremes` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  structure(
    list(
      type = "grid",
      n = n,
      include_extremes = isTRUE(include_extremes)
    ),
    class = c("RunGrid", "RunDesign")
  )
}


#' Define a manual multi-objective run design
#'
#' @description
#' Create an explicit run-design specification in which each row defines one
#' multi-objective optimization run.
#'
#' `run_manual()` is used when the exact objective weights or epsilon levels
#' should be controlled by the user instead of being generated automatically
#' with \code{\link{run_grid}}.
#'
#' @details
#' The input must be a \code{data.frame} with one row per requested
#' optimization run. The required columns depend on the multi-objective method
#' in which the design is used.
#'
#' \strong{Weighted-sum designs}
#'
#' For \code{\link{set_method_weighted_sum}}, weight columns must follow the
#' convention:
#'
#' \preformatted{
#' weight_<alias>
#' }
#'
#' where \code{<alias>} is the alias of a registered objective.
#'
#' For example, objectives with aliases \code{"cost"} and \code{"benefit"}
#' require:
#'
#' \preformatted{
#' weight_cost
#' weight_benefit
#' }
#'
#' Each row defines the weights used in one weighted-sum run. Whether weights
#' must already sum to one depends on the normalization settings supplied to
#' \code{\link{set_method_weighted_sum}}.
#'
#' \strong{Epsilon-constraint and AUGMECON designs}
#'
#' For \code{\link{set_method_epsilon_constraint}} and
#' \code{\link{set_method_augmecon}}, epsilon columns must follow the
#' convention:
#'
#' \preformatted{
#' eps_<alias>
#' }
#'
#' where \code{<alias>} identifies a constrained secondary objective.
#'
#' The primary objective is optimized directly and therefore normally does not
#' require an epsilon column. Each row defines one combination of epsilon
#' bounds for the secondary objectives.
#'
#' Column names are matched against the registered objective aliases when the
#' run design is resolved by the corresponding \code{set_method_*()} function.
#' Therefore, aliases containing spaces or other non-syntactic characters
#' should be avoided when manual run tables are expected to be used.
#'
#' `run_manual()` performs only structural validation of the supplied object.
#' Method-specific validation—including required columns, unknown aliases,
#' missing values, weight validity, and epsilon compatibility—is performed when
#' the design is attached to a multi-objective method or resolved before
#' solving.
#'
#' Additional columns should not be used unless they are explicitly supported
#' by the selected method. The order of rows is preserved and corresponds to
#' the requested run order.
#'
#' Manual designs are useful when:
#' \itemize{
#'   \item exact preference weights are known;
#'   \item policy-relevant epsilon thresholds must be evaluated;
#'   \item irregular regions of the frontier require denser sampling;
#'   \item runs must reproduce a previously published experimental design;
#'   \item a small number of selected trade-off scenarios is preferred over a
#'   regular automatic grid.
#' }
#'
#' @param x A non-empty \code{data.frame} with one row per optimization run.
#'   Columns must use the naming conventions required by the selected
#'   multi-objective method, such as \code{weight_<alias>} or
#'   \code{eps_<alias>}.
#'
#' @return An object of class \code{RunManual} and \code{RunDesign}. The object
#'   stores the supplied run table and is intended to be passed to the
#'   \code{runs} argument of a multi-objective method function.
#'
#' @examples
#' # Create an explicit weighted-sum design
#' weighted_runs <- run_manual(
#'   data.frame(
#'     weight_cost = c(1.0, 0.75, 0.50, 0.25, 0.0),
#'     weight_benefit = c(0.0, 0.25, 0.50, 0.75, 1.0)
#'   )
#' )
#'
#' weighted_runs
#'
#' # Create an explicit epsilon-constraint design
#' epsilon_runs <- run_manual(
#'   data.frame(
#'     eps_benefit = c(2, 4, 6, 8)
#'   )
#' )
#'
#' epsilon_runs
#'
#' # Use a manual design in a weighted-sum workflow
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
#'     runs = run_manual(
#'       data.frame(
#'         weight_cost = c(1.0, 0.5, 0.0),
#'         weight_benefit = c(0.0, 0.5, 1.0)
#'       )
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
#'   # Inspect the requested manual design and resulting objective values
#'   get_runs(solutions)
#'   get_objectives(
#'     solutions,
#'     format = "wide"
#'   )
#' }
#'
#' @seealso
#' \code{\link{run_grid}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{get_runs}}
#'
#' @export
run_manual <- function(x) {
  if (is.null(x) || !inherits(x, "data.frame")) {
    stop("`x` must be a data.frame.", call. = FALSE)
  }

  if (nrow(x) == 0L) {
    stop("`x` must contain at least one row.", call. = FALSE)
  }

  structure(
    list(
      type = "manual",
      values = as.data.frame(
        x,
        stringsAsFactors = FALSE
      )
    ),
    class = c("RunManual", "RunDesign")
  )
}
