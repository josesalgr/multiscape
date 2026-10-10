#' @include internal.R
#'
#' @title Register an atomic objective (internal)
#' @name register_atomic_objective_internal
#'
#' @description
#' Internal helper used by objective setter functions to define the active
#' single-objective configuration of a \code{Problem} object and, optionally,
#' register that objective as an atomic objective for multi-objective workflows.
#'
#' @details
#' In \code{multiscape}, an \emph{atomic objective} is a fully specified
#' objective definition that can later be reused by a multi-objective method
#' such as a weighted-sum formulation, an \eqn{\epsilon}-constraint method,
#' AUGMECON, or other objective-orchestration procedures.
#'
#' Each atomic objective is identified by:
#' \itemize{
#'   \item a stable internal identifier \code{objective_id},
#'   \item a solver-facing model label \code{model_type},
#'   \item a list of objective-specific arguments stored in
#'   \code{objective_args},
#'   \item an optimization sense, either \code{"min"} or \code{"max"},
#'   \item and, optionally, a user-facing identifier \code{alias}.
#' }
#'
#' If \code{alias} is not \code{NULL}, the objective is stored in
#' \code{x$data$objectives[[alias]]}. This makes it possible to refer to the
#' same objective later by a stable user-facing name. For example, a user may
#' register objectives under aliases such as \code{"cost"},
#' \code{"benefit"}, or \code{"frag"} and then pass those aliases to a
#' multi-objective method.
#'
#' If \code{alias} is \code{NULL}, no atomic-objective entry is created in
#' \code{x$data$objectives}. In that case, the calling function still defines
#' the currently active single-objective configuration through
#' \code{x$data$model_args}, but no reusable multi-objective registration is
#' created.
#'
#' Thus, this helper supports two complementary modes:
#' \itemize{
#'   \item \strong{single-objective mode}: only the active objective is stored,
#'   \item \strong{multi-objective-ready mode}: the active objective is stored
#'   and also registered under an alias for later reuse.
#' }
#'
#' Conceptually, if an objective function is denoted by \eqn{f(x)}, this helper
#' does not itself define the mathematical form of \eqn{f}; rather, it stores
#' the metadata required so that downstream code can reconstruct the correct
#' objective expression, its direction of optimization, and its user-visible
#' identity.
#'
#' @param x A \code{Problem} object.
#' @param alias Optional character scalar used to register the objective as an
#'   atomic objective. If \code{NULL}, no registration entry is created.
#' @param objective_id Character string giving the stable internal identifier of
#'   the objective, for example \code{"min_cost"} or \code{"max_benefit"}.
#' @param model_type Character string giving the model-builder label associated
#'   with this objective, for example \code{"minimizeCosts"}.
#' @param objective_args A list of objective-specific arguments to be stored with
#'   the objective definition.
#' @param sense Character string giving the optimization direction. Must be
#'   either \code{"min"} or \code{"max"}.
#'
#' @return An updated \code{Problem} object.
#'
#' @keywords internal
NULL

#' @title Add objective: minimize cost
#'
#' @description
#' Define an objective that minimizes the total cost of the solution.
#'
#' Depending on the function arguments, the objective may include planning-unit
#' costs, action costs, or both. Action costs can optionally be restricted to a
#' subset of actions.
#'
#' @details
#' Use this function when the planning problem is framed primarily as a
#' cost-minimization problem, with costs arising from planning-unit selection,
#' action implementation, or both.
#'
#' Let \eqn{\mathcal{I}} be the set of planning units and let
#' \eqn{\mathcal{D} \subseteq \mathcal{I} \times \mathcal{A}} denote the set of
#' feasible planning unit--action decisions.
#'
#' Let:
#' \itemize{
#'   \item \eqn{w_i \in \{0,1\}} denote whether planning unit \eqn{i} is
#'   selected,
#'   \item \eqn{x_{ia} \in \{0,1\}} denote whether action \eqn{a} is selected
#'   in planning unit \eqn{i},
#'   \item \eqn{c_i^{PU} \ge 0} denote the planning-unit cost of unit \eqn{i},
#'   \item \eqn{c_{ia}^{A} \ge 0} denote the cost of selecting action
#'   \eqn{a} in planning unit \eqn{i}.
#' }
#'
#' The most general form of this objective is:
#'
#' \deqn{
#' \min \left(
#' \sum_{i \in \mathcal{I}} c_i^{PU} w_i
#' +
#' \sum_{(i,a) \in \mathcal{D}^{\star}} c_{ia}^{A} x_{ia}
#' \right),
#' }
#'
#' where \eqn{\mathcal{D}^{\star}} denotes the subset of feasible decisions
#' whose action contributes to the action-cost term.
#'
#' If \code{include_pu_cost = FALSE}, the planning-unit cost term is omitted.
#'
#' If \code{include_action_cost = FALSE}, the action-cost term is omitted.
#'
#' If \code{actions = NULL}, all feasible actions contribute to the action-cost
#' term. If \code{actions} is supplied, only the selected subset contributes to
#' that term. Planning-unit costs are never subset by \code{actions}; they are
#' always global whenever \code{include_pu_cost = TRUE}.
#'
#' @param x A \code{Problem} object.
#' @param include_pu_cost Logical. If \code{TRUE}, include planning-unit costs
#'   in the objective.
#' @param include_action_cost Logical. If \code{TRUE}, include action costs in
#'   the objective.
#' @param actions Optional subset of actions to include in the action-cost
#'   component. Values may match \code{x$data$actions$id} and, if present,
#'   \code{x$data$actions$action_set}. If \code{NULL}, all feasible actions are
#'   included in the action-cost term.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # EXAMPLE: Minimum-cost management with a woodland target
#' #
#' # Use the 64 planning-unit landscape. The hypothetical outcome of 1
#' # credits one unit of woodland for either action in each selected unit.
#' # A target of 12 therefore requires at least 12 interventions.
#' sim <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(sim$actions, cost = sim$action_costs) |>
#'   add_effects(data.frame(
#'     action = c("protect", "restore"),
#'     feature = "woodland", outcome = 1
#'   )) |>
#'   add_constraint_targets_absolute(12, features = "woodland") |>
#'   add_objective_min_cost(include_pu_cost = FALSE, alias = "cost")
#'
#' # The solver selects the least costly set of actions that meets the target.
#' # This is a single-objective model: no set_method_*() call is needed.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_actions(solutions, layout = "single"))
#' }
#'
#' @seealso
#' \code{\link{add_objective_max_profit}},
#' \code{\link{add_objective_max_net_profit}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_min_cost <- function(
    x,
    include_pu_cost = TRUE,
    include_action_cost = TRUE,
    actions = NULL,
    alias = NULL
) {
  stopifnot(inherits(x, "Problem"))

  action_subset <- NULL
  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(x, actions)
  }

  args <- list(
    include_pu_cost = isTRUE(include_pu_cost),
    include_action_cost = isTRUE(include_action_cost),
    actions = if (is.null(action_subset)) NULL else as.character(action_subset$id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeCosts",
    objective_id = "min_cost",
    objective_args = args,
    sense = "min",
    alias = alias
  )
}

#' Deprecated benefit objective
#' @description Use [add_objective_max_effect()] for signed net effects.
#' @inheritParams add_objective_max_effect
#' @return An updated Problem object.
#' @export
add_objective_max_benefit <- function(x, actions = NULL, features = NULL, alias = NULL) {
  lifecycle::deprecate_warn("1.4.0", "add_objective_max_benefit()",
                            "add_objective_max_effect()", user_env = parent.frame())
  add_objective_max_effect(x, actions, features, alias)
}

#' @title Add objective: minimise signed effect
#'
#' @description
#' Minimise total signed changes relative to the reference. Whether
#' a decrease is desirable depends on the feature being optimised.
#'
#' @details
#' For the selected actions and features, this objective minimises
#' \eqn{\sum_{i,f} \Delta_{if}(x)}, where \eqn{\Delta_{if}(x)}
#' is the signed change after accounting for joint effects. Increases
#' and decreases can offset one another across units or features.
#'
#' For instance, minimising signed fuel-load change favours reductions
#' in fuel load. Specify a feature subset when features are measured in
#' incompatible units. Unselected units contribute zero change, and
#' implementation costs are not subtracted.
#'
#' This differs from the deprecated \code{add_objective_min_loss()},
#' which penalises only the negative part of aggregated changes.
#'
#' @inheritParams add_objective_max_effect
#' @return An updated Problem object.
#' @seealso [add_objective_max_effect()], [add_objective_min_loss()]
#' @examples
#' # EXAMPLE: Minimise the signed change in fuel load
#' #
#' # Use the geometry from the bundled 64-unit landscape, with a simple
#' # hypothetical fuel-load feature that increases from west to east.
#' # A 25% reduction has a NEGATIVE signed effect, so minimising the
#' # effect favours the units with the greatest fuel-load reduction.
#' sim <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = data.frame(id = 1L, name = "fuel_load"),
#'   dist_features = data.frame(
#'     pu = sim$planning_units$id, feature = 1L,
#'     amount = 10 + sim$planning_units$x
#'   ),
#'   cost = "cost"
#' ) |>
#'   add_actions(data.frame(id = "thin"), cost = 1) |>
#'   add_effects(data.frame(
#'     action = "thin", feature = "fuel_load", relative_change = -0.25
#'   )) |>
#'   add_constraint_budget(12, "equal", include_pu_cost = FALSE) |>
#'   add_objective_min_effect(features = "fuel_load", alias = "fuel_reduction")
#'
#' # With one monetary unit per action, the budget equality selects
#' # exactly 12 units. Without it, this negative-effect objective
#' # could favour implementing the action everywhere.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_actions(solutions, layout = "single"))
#' }
#'
#' @export
add_objective_min_effect <- function(x, actions = NULL, features = NULL, alias = NULL) {
  stopifnot(inherits(x, "Problem"))
  a <- if (is.null(actions)) NULL else .pa_resolve_action_subset(x, actions)$internal_id
  f <- if (is.null(features)) NULL else .pa_resolve_feature_subset(x, features)$internal_id
  .pa_set_active_and_register_objective(x, model_type = "maximizeBenefits",
                                        objective_id = "min_effect", objective_args = list(effect_sense = "min",
                                                                                           actions = if (is.null(a)) NULL else as.integer(a),
                                                                                           features = if (is.null(f)) NULL else as.integer(f)), sense = "min", alias = alias)
}

#' @title Add objective: maximize signed effect
#'
#' @description
#' Maximize the total signed change generated by selected management actions
#' relative to the reference scenario. Positive changes increase the objective;
#' negative changes reduce it.
#'
#' @details
#' Let \eqn{\Delta_{if}(x)} be the signed change for planning unit \eqn{i} and
#' feature \eqn{f}, after combining selected individual actions and their
#' interaction corrections. The objective is
#' \deqn{\max \sum_{i,f} \Delta_{if}(x).}
#' For one action per unit this reduces to the sum of selected signed effects.
#' With concurrent actions, supplied joint totals and inferred combinations are
#' evaluated together; a negative interaction correction is not discarded.
#'
#' The reference is the scenario supplied through \code{dist_features}, at the
#' same horizon and in the same units as action outcomes. An unselected unit
#' contributes zero change. Costs are not subtracted by this objective.
#' A positive effect means an increase in the feature; select features for which
#' an increase is desirable. Standardize incompatible units before aggregation,
#' or register separate feature objectives using distinct aliases.
#'
#' With \code{actions}, include only individual terms in that subset and joint
#' corrections whose every member belongs to it. This is an accounting scope,
#' not attribution of a cross-subset interaction to its individual members.
#' With \code{features}, include only the selected features.
#'
#' @section Changed behavior:
#' This development version maximizes signed net change. Earlier versions
#' maximized positive effects only. Models with negative effects or negative
#' interaction corrections may therefore produce different solutions. The
#' historical add_objective_max_benefit() name is deprecated in favor of
#' add_objective_max_effect(). \code{get_features()} still reports positive gains separately in
#' \code{selected_benefit}; the signed objective corresponds to
#' \code{selected_net} when their scopes match.
#'
#' @param x A \code{Problem} object.
#' @param actions Optional subset of actions to include in the objective. Values
#'   may match \code{x$data$actions$id} and, if present,
#'   \code{x$data$actions$action_set}. If \code{NULL}, all actions are included.
#' @param features Optional subset of features to include in the objective.
#'   Values may match \code{x$data$features$id} and, if present,
#'   \code{x$data$features$name}. If \code{NULL}, all features are included.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # EXAMPLE: Maximise woodland gain in a fixed number of units
#' #
#' # The bundled landscape has spatially varying woodland reference
#' # amounts. Assume restoration increases these amounts by 50%.
#' # The absolute signed effect is therefore larger where the
#' # reference amount is greater.
#' sim <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(data.frame(id = "restore"), cost = 1) |>
#'   add_effects(data.frame(
#'     action = "restore", feature = "woodland", relative_change = 0.50
#'   )) |>
#'   add_constraint_budget(12, "equal", include_pu_cost = FALSE) |>
#'   add_objective_max_effect(features = "woodland", alias = "woodland_gain")
#'
#' # Every restoration costs one monetary unit, so exactly 12 units
#' # must be managed. The objective favours the largest woodland gains.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_actions(solutions, layout = "single"))
#' }
#'
#' @seealso
#' \code{\link{add_objective_min_effect}},
#' \code{\link{add_effects}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_max_effect <- function(
    x,
    actions = NULL,
    features = NULL,
    alias = NULL
) {
  stopifnot(inherits(x, "Problem"))

  action_subset <- NULL
  feature_subset <- NULL

  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(x, actions)
  }

  if (!is.null(features)) {
    feature_subset <- .pa_resolve_feature_subset(x, features)
  }

  args <- list(
    effect_sense = "max",
    actions = if (is.null(action_subset)) NULL else as.integer(action_subset$internal_id),
    features = if (is.null(feature_subset)) NULL else as.integer(feature_subset$internal_id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "maximizeBenefits",
    objective_id = "max_effect",
    objective_args = args,
    sense = "max",
    alias = alias
  )
}

#' @title Deprecated objective: minimize loss
#' @section Lifecycle:
#' Deprecated since 1.4.0. Legacy calls retain the negative-part criterion.
#' add_objective_min_effect() is not a mathematically equivalent replacement.
#'
#' @description
#' Minimize deterioration relative to the reference scenario. Positive changes
#' in other planning units or features do not offset these losses.
#'
#' @details
#' Let \eqn{\Delta_{if}(x)} be the signed change for planning unit \eqn{i} and
#' feature \eqn{f}, after combining selected individual actions and their
#' interaction corrections. The objective is
#' \deqn{\min \sum_{i,f} \max(-\Delta_{if}(x), 0).}
#' The positive/negative split is applied after joint aggregation within each
#' unit and feature, before summing across units or features. A negative
#' interaction correction does not itself represent a loss if the final change
#' remains positive. Conversely, gains elsewhere cannot cancel deterioration.
#'
#' With one action per unit this retains the existing loss-only criterion.
#' With concurrent actions, an exact MILP linearization represents mixed-sign
#' final losses in single-objective and all multi-objective methods, including
#' when loss is constrained, has zero weight, or is evaluated after another
#' objective is optimized. Non-negative effects give a valid zero-loss objective.
#'
#' Action and feature subsets follow \code{add_objective_max_benefit()}: an
#' interaction is included only when all of its members belong to the scope.
#' An unselected unit contributes zero loss. Use targets or other objectives if
#' avoiding intervention altogether should not be an acceptable solution.
#'
#' @param x A \code{Problem} object.
#' @param actions Optional subset of actions to include in the objective. Values
#'   may match \code{x$data$actions$id} and, if present,
#'   \code{x$data$actions$action_set}. If \code{NULL}, all actions are included.
#' @param features Optional subset of features to include in the objective.
#'   Values may match \code{x$data$features$id} and, if present,
#'   \code{x$data$features$name}. If \code{NULL}, all features are included.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     example_data$actions,
#'     cost = example_data$action_costs
#'   ) |>
#'   add_effects(
#'     example_data$effect_assumptions
#'   )
#'
#' p1 <- add_objective_min_loss(p)
#' p1$data$model_args
#'
#' p2 <- add_objective_min_loss(
#'   p,
#'   actions = "restore"
#' )
#' p2$data$model_args
#'
#' p3 <- add_objective_min_loss(
#'   p,
#'   features = 1
#' )
#' p3$data$model_args
#'
#' @seealso
#' \code{\link{add_objective_max_benefit}},
#' \code{\link{add_effects}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_min_loss <- function(
    x,
    actions = NULL,
    features = NULL,
    alias = NULL
) {
  lifecycle::deprecate_warn("1.4.0", "add_objective_min_loss()",
                            details = paste("Use add_objective_min_effect() only when minimizing signed change is intended.",
                                            "It is not an equivalent replacement: this legacy function retains",
                                            "the negative-part criterion after aggregation within each unit and feature."),
                            user_env = parent.frame())
  stopifnot(inherits(x, "Problem"))

  action_subset <- NULL
  feature_subset <- NULL

  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(x, actions)
  }

  if (!is.null(features)) {
    feature_subset <- .pa_resolve_feature_subset(x, features)
  }

  args <- list(
    actions = if (is.null(action_subset)) NULL else as.integer(action_subset$internal_id),
    features = if (is.null(feature_subset)) NULL else as.integer(feature_subset$internal_id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeLosses",
    objective_id = "min_loss",
    objective_args = args,
    sense = "min",
    alias = alias
  )
}

#' @title Add objective: maximize profit
#'
#' @description
#' Define an objective that maximizes total profit from selected planning
#' unit--action decisions.
#'
#' @details
#' Use this function when the objective is to maximize gross economic return,
#' without subtracting planning-unit or action costs.
#'
#' Let \eqn{x_{ia} \in \{0,1\}} denote whether action \eqn{a} is selected in
#' planning unit \eqn{i}, and let \eqn{\pi_{ia}} denote the profit associated
#' with that decision, as taken from column \code{profit_col} in the stored
#' profit table.
#'
#' If all actions are included, the objective is:
#'
#' \deqn{
#' \max \sum_{(i,a) \in \mathcal{D}} \pi_{ia} x_{ia},
#' }
#'
#' where \eqn{\mathcal{D}} denotes the set of feasible planning unit--action
#' decisions.
#'
#' If \code{actions} is provided, only the selected subset contributes to the
#' objective. Letting \eqn{\mathcal{D}^{\star}} denote the feasible decisions
#' whose action belongs to the selected subset, the objective becomes:
#'
#' \deqn{
#' \max \sum_{(i,a) \in \mathcal{D}^{\star}} \pi_{ia} x_{ia}.
#' }
#'
#' This objective considers profit only. It does not subtract planning-unit
#' costs or action costs. For a net-profit formulation, use
#' \code{\link{add_objective_max_net_profit}}.
#'
#' @param x A \code{Problem} object.
#' @param profit_col Character string giving the profit column in the stored
#'   profit table.
#' @param actions Optional subset of actions to include. Values may match
#'   \code{x$data$actions$id} and, if present,
#'   \code{x$data$actions$action_set}. If \code{NULL}, all actions are included.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # EXAMPLE: Maximise gross economic return across the landscape
#' #
#' # Assign hypothetical profits that favour protection in the west
#' # and restoration in the east. All values are positive.
#' sim <- load_sim_multiaction()
#' returns <- sim$action_costs[, c("pu", "action")]
#' x_coord <- sim$planning_units$x[
#'   match(returns$pu, sim$planning_units$id)
#' ]
#' returns$profit <- ifelse(
#'   returns$action == "protect", 12 - x_coord, 4 + x_coord
#' )
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(sim$actions, cost = 9.5) |>
#'   add_profit(returns) |>
#'   add_objective_max_profit(alias = "profit")
#'
#' # Implementation costs are NOT deducted in this objective.
#' # With positive returns and at most one action per unit, the
#' # model chooses the more profitable action in each unit.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_actions(solutions, layout = "single"))
#' }
#'
#' @seealso
#' \code{\link{add_objective_min_cost}},
#' \code{\link{add_objective_max_net_profit}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_max_profit <- function(
    x,
    profit_col = "profit",
    actions = NULL,
    alias = NULL
) {
  stopifnot(inherits(x, "Problem"))

  action_subset <- NULL
  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(x, actions)
  }

  args <- list(
    profit_col = as.character(profit_col)[1],
    actions = if (is.null(action_subset)) NULL else as.character(action_subset$id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "maximizeProfit",
    objective_id = "max_profit",
    objective_args = args,
    sense = "max",
    alias = alias
  )
}

#' @title Add objective: maximize net profit
#'
#' @description
#' Define an objective that maximizes net profit by combining profits with
#' optional planning-unit and action-cost penalties.
#'
#' @details
#' Use this function when decisions generate returns and the objective should
#' optimize the resulting net balance after subtracting selected cost
#' components.
#'
#' Let:
#' \itemize{
#'   \item \eqn{x_{ia} \in \{0,1\}} denote whether action \eqn{a} is selected
#'   in planning unit \eqn{i},
#'   \item \eqn{w_i \in \{0,1\}} denote whether planning unit \eqn{i} is
#'   selected,
#'   \item \eqn{\pi_{ia}} denote the profit associated with decision
#'   \eqn{(i,a)},
#'   \item \eqn{c_i^{PU} \ge 0} denote the planning-unit cost,
#'   \item \eqn{c_{ia}^{A} \ge 0} denote the action cost.
#' }
#'
#' In its most general form, the objective is:
#'
#' \deqn{
#' \max \left(
#' \sum_{(i,a) \in \mathcal{D}^{\star}} \pi_{ia} x_{ia}
#' -
#' \sum_{i \in \mathcal{I}} c_i^{PU} w_i
#' -
#' \sum_{(i,a) \in \mathcal{D}^{\star}} c_{ia}^{A} x_{ia}
#' \right),
#' }
#'
#' where \eqn{\mathcal{D}^{\star}} denotes the subset of feasible
#' planning unit--action decisions included in the objective.
#'
#' If \code{actions = NULL}, all feasible actions contribute to both the profit
#' term and the action-cost term.
#'
#' If \code{actions} is provided, the profit term and the action-cost term are
#' restricted to that subset. The planning-unit cost term, if included, remains
#' global.
#'
#' If \code{include_pu_cost = FALSE}, the planning-unit cost term is omitted.
#'
#' If \code{include_action_cost = FALSE}, the action-cost term is omitted.
#'
#' @param x A \code{Problem} object.
#' @param profit_col Character string giving the profit column in the stored
#'   profit table.
#' @param include_pu_cost Logical. If \code{TRUE}, subtract planning-unit costs.
#' @param include_action_cost Logical. If \code{TRUE}, subtract action costs.
#' @param actions Optional subset of actions to include in the profit and
#'   action-cost terms. Values may match \code{x$data$actions$id} and, if
#'   present, \code{x$data$actions$action_set}.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # EXAMPLE: Maximise returns minus implementation costs
#' #
#' # Use the same west-to-east profit pattern as above, but now
#' # charge 9.5 monetary units for every selected action. Some
#' # locations may no longer generate a positive net return.
#' sim <- load_sim_multiaction()
#' returns <- sim$action_costs[, c("pu", "action")]
#' x_coord <- sim$planning_units$x[
#'   match(returns$pu, sim$planning_units$id)
#' ]
#' returns$profit <- ifelse(
#'   returns$action == "protect", 12 - x_coord, 4 + x_coord
#' )
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(sim$actions, cost = 9.5) |>
#'   add_profit(returns) |>
#'   add_objective_max_net_profit(include_pu_cost = FALSE, alias = "net_profit")
#'
#' # Unlike gross profit maximisation, leaving a unit unmanaged
#' # can now be optimal when its best return is below its cost.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_actions(solutions, layout = "single"))
#' }
#'
#' @seealso
#' \code{\link{add_objective_max_profit}},
#' \code{\link{add_objective_min_cost}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_max_net_profit <- function(
    x,
    profit_col = "profit",
    include_pu_cost = TRUE,
    include_action_cost = TRUE,
    actions = NULL,
    alias = NULL
) {
  stopifnot(inherits(x, "Problem"))

  action_subset <- NULL
  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(x, actions)
  }

  args <- list(
    profit_col = as.character(profit_col)[1],
    include_pu_cost = isTRUE(include_pu_cost),
    include_action_cost = isTRUE(include_action_cost),
    actions = if (is.null(action_subset)) NULL else as.character(action_subset$id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "maximizeNetProfit",
    objective_id = "max_net_profit",
    objective_args = args,
    sense = "max",
    alias = alias
  )
}

#' @title Add objective: minimise planning-unit fragmentation
#'
#' @description
#' Encourage cohesion of the selected planning units, regardless of
#' which action is implemented within each unit.
#'
#' @details
#' This objective uses planning-unit selection variables \eqn{w_i} and
#' a spatial relation registered with \code{add_spatial_relations()} or
#' \code{add_spatial_boundary()}. Relation weights \eqn{\omega_{ij}}
#' are scaled by \code{weight_multiplier}.
#'
#' The underlying model uses \eqn{y_{ij}=w_i \land w_j} to record
#' whether neighbouring units are both selected, encouraging spatially
#' consolidated selections. Action identities do not enter this spatial
#' criterion: adjacent units receiving different actions are part of the
#' same selected planning-unit set.
#'
#' Without another requirement, selecting no units can be optimal.
#' Combine this objective with a budget equality, an area requirement,
#' or an ecological target that ensures meaningful management activity.
#' For action-specific cohesion, see
#' \code{add_objective_min_fragmentation_action()}.
#'
#' @param x A \code{Problem} object.
#' @param relation_name Character string giving the name of the spatial relation
#'   to use. The relation must already exist in
#'   \code{x$data$spatial_relations}.
#' @param weight_multiplier Numeric scalar greater than or equal to zero. Global
#'   multiplier applied to the relation weights when the objective is built.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # EXAMPLE: Select a cohesive set of 12 planning units
#' #
#' # With one feasible action costing one unit, a budget equality
#' # forces exactly 12 selected units. Without this requirement,
#' # minimising fragmentation alone could select no units.
#' sim <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(data.frame(id = "restore"), cost = 1) |>
#'   add_spatial_boundary(name = "boundary", include_self = TRUE) |>
#'   add_constraint_budget(12, "equal", include_pu_cost = FALSE) |>
#'   add_objective_min_fragmentation_planning_units(
#'     relation_name = "boundary", alias = "pu_fragmentation"
#'   )
#'
#' # Cohesion is evaluated for the selected planning-unit pattern,
#' # irrespective of action identity. No additional objective is used.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_planning_units(solutions))
#' }
#'
#' @seealso
#' \code{\link{add_spatial_boundary}},
#' \code{\link{add_spatial_relations}},
#' \code{\link{add_objective_min_fragmentation_action}},
#' \code{\link{add_objective_min_fragmentation_pu}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_min_fragmentation_planning_units <- function(
    x,
    relation_name = "boundary",
    weight_multiplier = 1,
    alias = NULL
) {
  stopifnot(inherits(x, "Problem"))

  relation_name <- as.character(relation_name)[1]
  weight_multiplier <- as.numeric(weight_multiplier)[1]

  if (!is.finite(weight_multiplier) || weight_multiplier < 0) {
    stop("weight_multiplier must be a finite number >= 0.", call. = FALSE)
  }

  rels <- x$data$spatial_relations
  if (is.null(rels) || !is.list(rels) || is.null(rels[[relation_name]])) {
    stop(
      "Spatial relation '", relation_name, "' not found in x$data$spatial_relations. ",
      "Add it first.",
      call. = FALSE
    )
  }

  args <- list(
    relation_name = relation_name,
    weight_multiplier = weight_multiplier
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeFragmentation",
    objective_id = "min_fragmentation",
    objective_args = args,
    sense = "min",
    alias = alias
  )
}


#' @title Add objective: minimize planning-unit fragmentation
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' \code{add_objective_min_fragmentation_pu()} has been replaced by
#' \code{\link{add_objective_min_fragmentation_planning_units}}.
#'
#' @inheritParams add_objective_min_fragmentation_planning_units
#'
#' @return An updated \code{Problem} object.
#'
#' @seealso
#' \code{\link{add_objective_min_fragmentation_planning_units}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_min_fragmentation_pu <- function(
    x,
    relation_name = "boundary",
    weight_multiplier = 1,
    alias = NULL
) {
  lifecycle::deprecate_warn(
    "1.1.0",
    "add_objective_min_fragmentation_pu()",
    "add_objective_min_fragmentation_planning_units()"
  )

  add_objective_min_fragmentation_planning_units(
    x = x,
    relation_name = relation_name,
    weight_multiplier = weight_multiplier,
    alias = alias
  )
}

#' @title Add objective: minimise action fragmentation
#'
#' @description
#' Encourage spatial cohesion separately for each selected action,
#' rather than only for the union of managed planning units.
#'
#' @details
#' This objective uses the action-selection decisions \eqn{x_{ia}} and
#' a previously registered spatial relation. For neighbouring units
#' \eqn{i} and \eqn{j}, \eqn{b_{ija}=x_{ia} \land x_{ja}} represents
#' whether the same action \eqn{a} occurs in both units. Adjacency of
#' different actions does not form a continuous patch of either action.
#'
#' Use \code{actions} to select which action patterns contribute,
#' \code{action_weights} to adjust their relative importance, and
#' \code{weight_multiplier} to scale spatial relation weights.
#'
#' Unlike \code{add_objective_min_fragmentation_planning_units()},
#' this objective distinguishes action identities. Combine it with
#' coverage or allocation requirements so an empty plan is not optimal.
#'
#' @param x A \code{Problem} object.
#' @param relation_name Character string giving the name of the spatial relation
#'   to use. The relation must already exist in
#'   \code{x$data$spatial_relations}.
#' @param weight_multiplier Numeric scalar greater than or equal to zero. Global
#'   multiplier applied to the relation weights when the objective is built.
#' @param action_weights Optional action weights. Either a named numeric vector
#'   with names equal to action ids, or a \code{data.frame} with columns
#'   \code{action} and \code{weight}. These weights scale the contribution of
#'   each action to the final objective.
#' @param actions Optional subset of actions to include. Values may match
#'   \code{x$data$actions$id} and, if present,
#'   \code{x$data$actions$action_set}. If \code{NULL}, all actions are included.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # EXAMPLE: Form separate cohesive patches for two actions
#' #
#' # Each action costs one unit. Two action-specific budget equalities
#' # require exactly eight protection and eight restoration units.
#' # The default one-action-per-unit rule prevents overlapping actions.
#' sim <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(sim$actions, cost = 1) |>
#'   add_spatial_boundary(name = "boundary", include_self = TRUE) |>
#'   add_constraint_budget(
#'     8, "equal", actions = "protect", include_pu_cost = FALSE
#'   ) |>
#'   add_constraint_budget(
#'     8, "equal", actions = "restore", include_pu_cost = FALSE
#'   ) |>
#'   add_objective_min_fragmentation_action(relation_name = "boundary", alias = "action_fragmentation")
#'
#' # Unlike planning-unit fragmentation, this objective measures
#' # the cohesion of each action's selected units separately.
#' if (requireNamespace("rcbc", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
#'   get_objectives(solutions, format = "wide")
#'   print(plot_spatial_actions(solutions, layout = "single"))
#' }
#'
#' @seealso
#' \code{\link{add_objective_min_fragmentation_planning_units}},
#' \code{\link{add_spatial_boundary}},
#' \code{\link{add_spatial_relations}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_min_fragmentation_action <- function(
    x,
    relation_name = "boundary",
    weight_multiplier = 1,
    action_weights = NULL,
    actions = NULL,
    alias = NULL
) {
  stopifnot(inherits(x, "Problem"))

  action_subset <- NULL
  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(x, actions)
  }

  args <- list(
    relation_name = as.character(relation_name)[1],
    weight_multiplier = as.numeric(weight_multiplier)[1],
    action_weights = action_weights,
    actions = if (is.null(action_subset)) NULL else as.character(action_subset$id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeActionFragmentation",
    objective_id = "min_action_fragmentation",
    objective_args = args,
    sense = "min",
    alias = alias
  )
}

#' @title Add objective: minimize intervention impact
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' Deprecated; retained temporarily with its original behavior.
#'
#' Define an objective that minimizes the impact associated with selecting
#' planning units for intervention.
#'
#' This objective uses planning-unit selection variables rather than summing the
#' same impact repeatedly over multiple actions. As a result, each planning unit
#' contributes at most once to the objective, regardless of how many feasible
#' actions exist in that unit.
#'
#' @details
#' The legacy objective minimizes the reference amount in units where at least
#' one action in the selected scope is executed, counting each unit once. Its
#' original arguments, objective sense, and single/MO formulations remain
#' available during the transition.
#'
#' @section Migration:
#' This function will be removed in a future version of multiscape. New workflows
#' should express action consequences with \code{\link{add_effects}} and optimize
#' signed changes with \code{\link{add_objective_max_effect}}.
#'
#' This is not an automatic replacement. For deficit-based prioritization,
#' let \eqn{q_{if}} be the reference amount and \eqn{M_f} a common ceiling for
#' feature \eqn{f}. Supply \eqn{M_f-q_{if}} as the restoration effect, or
#' \eqn{M_f} as its outcome. If every plan restores exactly \eqn{K} units and
#' at most one scoped action is selected in each unit, then
#' \deqn{\sum_i(M_f-q_{if})r_i=K M_f-\sum_iq_{if}r_i.}
#' Maximizing this deficit is equivalent to minimizing the old baseline sum.
#' Equal area fixes \eqn{K} only when units have equal effective action areas.
#' With variable effort, varying ceilings, or concurrent scoped actions,
#' equivalence is not guaranteed. The common ceiling is a modelling assumption,
#' not an empirical estimate of restoration response.
#'
#' @param x A \code{Problem} object.
#' @param impact_col Character string giving the column in the
#'   feature-distribution table that contains the per-\code{(pu, feature)}
#'   impact amount. The default is \code{"amount"}.
#' @param features Optional subset of features to include. Values may match
#'   \code{x$data$features$id} and, if present, \code{x$data$features$name}.
#' @param actions Optional subset of actions used to define the intervention
#'   context. Values may match \code{x$data$actions$id} and, if present,
#'   \code{x$data$actions$action_set}.
#' @param alias Optional identifier used to register this objective for
#'   multi-objective workflows.
#'
#' @return An updated \code{Problem} object.
#'
#' @examples
#' # Equal-area units with a fixed restoration effort of two units.
#' p <- create_problem(
#'   data.frame(id = 1:3, cost = 1, area = 1),
#'   data.frame(id = 1, name = "service"),
#'   data.frame(pu = 1:3, feature = 1, amount = c(0.2, 0.6, 0.9))
#' ) |>
#'   add_actions(data.frame(id = "restore"), cost = 1) |>
#'   add_effects(data.frame(action = "restore", feature = "service", outcome = 1)) |>
#'   add_constraint_area(2, "equal", tolerance = 0, actions = "restore") |>
#'   add_objective_max_effect(features = "service", actions = "restore")
#' p$data$model_args
#'
#' @seealso
#' \code{\link{add_objective_max_effect}},
#' \code{\link{add_objective_min_loss}}
#'
#' @section Repeated calls:
#' With \code{alias = NULL}, one explicit single objective can be defined per
#' problem; a second unaliased definition raises an error. With an alias,
#' objectives accumulate under distinct names; a repeated alias raises an error.
#' Aliased definitions preserve an explicitly configured single objective.
#' To compare alternatives, start from the problem before its objective was added.
#'
#' @export
add_objective_min_intervention_impact <- function(
    x,
    impact_col = "amount",
    features = NULL,
    actions = NULL,
    alias = NULL
) {
  lifecycle::deprecate_warn(
    "1.4.0",
    "add_objective_min_intervention_impact()",
    details = paste(
      "This function will be removed in a future version of multiscape.",
      "Use add_effects() and add_objective_max_benefit() to express action consequences.",
      "Deficit-based migration requires explicit ceilings and fixed restoration effort;",
      "it is not an automatic replacement. Legacy calls retain their original behavior."
    ),
    user_env = parent.frame()
  )
  stopifnot(inherits(x, "Problem"))

  impact_col <- as.character(impact_col)[1]
  if (is.na(impact_col) || !nzchar(impact_col)) {
    stop("impact_col must be a non-empty string.", call. = FALSE)
  }

  if (is.null(x$data$dist_features) ||
      !inherits(x$data$dist_features, "data.frame") ||
      nrow(x$data$dist_features) == 0) {
    stop("x$data$dist_features is missing or empty.", call. = FALSE)
  }

  if (!(impact_col %in% names(x$data$dist_features))) {
    stop(
      "impact_col '", impact_col, "' was not found in x$data$dist_features.",
      call. = FALSE
    )
  }

  feat_subset <- .pa_resolve_feature_subset(x, features = features)
  act_subset  <- .pa_resolve_action_subset(x, subset = actions)

  args <- list(
    impact_col = impact_col,
    features = feat_subset$id,
    actions = act_subset$id
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeInterventionImpact",
    objective_id = "min_intervention_impact",
    objective_args = args,
    sense = "min",
    alias = alias
  )
}
