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
#'   )
#'
#' p1 <- add_objective_min_cost(p)
#' p1$data$model_args
#'
#' p2 <- add_objective_min_cost(
#'   p,
#'   include_pu_cost = FALSE,
#'   include_action_cost = TRUE
#' )
#' p2$data$model_args
#'
#' p3 <- add_objective_min_cost(
#'   p,
#'   actions = "restore"
#' )
#' p3$data$model_args
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

#' @title Add objective: maximize benefit
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
#' function name and arguments are unchanged; no separate net-benefit function
#' is required. \code{get_features()} still reports positive gains separately in
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
#' p1 <- add_objective_max_benefit(p)
#' p1$data$model_args
#'
#' p2 <- add_objective_max_benefit(
#'   p,
#'   actions = "restore"
#' )
#' p2$data$model_args
#'
#' p3 <- add_objective_max_benefit(
#'   p,
#'   features = 1
#' )
#' p3$data$model_args
#'
#' @seealso
#' \code{\link{add_objective_min_loss}},
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
add_objective_max_benefit <- function(
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
    actions = if (is.null(action_subset)) NULL else as.integer(action_subset$internal_id),
    features = if (is.null(feature_subset)) NULL else as.integer(feature_subset$internal_id)
  )

  .pa_set_active_and_register_objective(
    x = x,
    model_type = "maximizeBenefits",
    objective_id = "max_benefit",
    objective_args = args,
    sense = "max",
    alias = alias
  )
}

#' @title Add objective: minimize loss
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
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' profit <- example_data$action_costs
#' profit$profit <- 10 - profit$cost
#' profit$cost <- NULL
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
#'   add_profit(profit)
#'
#' p1 <- add_objective_max_profit(p)
#' p1$data$model_args
#'
#' p2 <- add_objective_max_profit(
#'   p,
#'   actions = "restore"
#' )
#' p2$data$model_args
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
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' profit <- example_data$action_costs
#' profit$profit <- 10 - profit$cost
#' profit$cost <- NULL
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
#'   add_profit(profit)
#'
#' p1 <- add_objective_max_net_profit(p)
#' p1$data$model_args
#'
#' p2 <- add_objective_max_net_profit(
#'   p,
#'   include_pu_cost = FALSE,
#'   include_action_cost = TRUE
#' )
#' p2$data$model_args
#'
#' p3 <- add_objective_max_net_profit(
#'   p,
#'   actions = "restore"
#' )
#' p3$data$model_args
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

#' @title Add objective: minimize planning-unit fragmentation
#'
#' @description
#' Define an objective that minimizes planning-unit fragmentation over a stored
#' spatial relation.
#'
#' This objective acts on the planning-unit selection pattern through the binary
#' planning-unit variables \eqn{w_i}. It is therefore appropriate when spatial
#' cohesion is to be encouraged at the level of the selected planning-unit set
#' as a whole.
#'
#' @details
#' Use this function when spatial cohesion should be encouraged at the level of
#' the selected planning-unit set as a whole.
#'
#' Let \eqn{\mathcal{I}} denote the set of planning units and let
#' \eqn{w_i \in \{0,1\}} indicate whether planning unit \eqn{i \in \mathcal{I}}
#' is selected.
#'
#' Let the chosen spatial relation define a set of weighted pairs with weights
#' \eqn{\omega_{ij} \ge 0}. These relation weights are interpreted by the model
#' builder after scaling by \eqn{\lambda =} \code{weight_multiplier}.
#'
#' The internal preparation step constructs one auxiliary variable
#' \eqn{y_{ij} \in [0,1]} for each unique non-diagonal undirected edge
#' \eqn{(i,j)} with \eqn{i < j}. The intended semantics is:
#' \deqn{
#' y_{ij} = w_i \land w_j.
#' }
#'
#' This is enforced by the standard linearization:
#' \deqn{
#' y_{ij} \le w_i,
#' }
#' \deqn{
#' y_{ij} \le w_j,
#' }
#' \deqn{
#' y_{ij} \ge w_i + w_j - 1.
#' }
#'
#' Thus, \eqn{y_{ij}=1} if and only if both planning units \eqn{i} and
#' \eqn{j} are selected, and \eqn{y_{ij}=0} otherwise.
#'
#' The exact objective coefficients are assembled later by the model builder
#' from:
#' \itemize{
#'   \item the planning-unit variables \eqn{w_i},
#'   \item the edge-conjunction variables \eqn{y_{ij}},
#'   \item the stored relation weights \eqn{\omega_{ij}},
#'   \item and the multiplier \eqn{\lambda}.
#' }
#'
#' Conceptually, the resulting objective is a boundary- or relation-based
#' compactness functional that penalizes exposed or weakly connected selected
#' patterns while rewarding adjacency among selected planning units.
#'
#' In the common case where \code{relation_name = "boundary"} and the relation
#' was built with \code{\link{add_spatial_boundary}}, the objective corresponds
#' to a boundary-length-style fragmentation penalty.
#'
#' Setting \code{weight_multiplier = 0} removes the contribution of the spatial
#' relation from the objective after scaling.
#'
#' This objective does not distinguish between different actions within the same
#' planning unit. If action-specific spatial cohesion is required, use
#' \code{\link{add_objective_min_fragmentation_action}} instead.
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
#'   )
#'
#' p <- add_spatial_boundary(
#'   x = p,
#'   name = "boundary",
#'   include_self = TRUE,
#'   edge_factor = 1
#' )
#'
#' p <- add_objective_min_fragmentation_planning_units(
#'   p,
#'   relation_name = "boundary"
#' )
#'
#' p$data$model_args
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

#' @title Add objective: minimize action fragmentation
#'
#' @description
#' Define an objective that minimizes fragmentation at the action level over a
#' stored spatial relation.
#'
#' Unlike \code{\link{add_objective_min_fragmentation_pu}}, which acts on the
#' selected planning-unit set through \eqn{w_i}, this objective acts on the
#' spatial arrangement of individual action decisions through the action
#' variables \eqn{x_{ia}}.
#'
#' @details
#' Use this function when spatial cohesion should be encouraged separately for
#' each selected action pattern.
#'
#' Let \eqn{\mathcal{I}} denote the set of planning units and let
#' \eqn{\mathcal{A}} denote the set of actions.
#'
#' Let \eqn{x_{ia} \in \{0,1\}} indicate whether action \eqn{a \in \mathcal{A}}
#' is selected in planning unit \eqn{i \in \mathcal{I}}.
#'
#' Let the chosen spatial relation define weighted pairs with
#' weights \eqn{\omega_{ij} \ge 0}, and let
#' \eqn{\lambda =} \code{weight_multiplier} be the global scaling factor applied
#' to these weights.
#'
#' If \code{actions} is supplied, only the selected subset
#' \eqn{\mathcal{A}^{\star} \subseteq \mathcal{A}} contributes to the final
#' objective. If \code{actions = NULL}, all actions are included.
#'
#' The internal preparation step constructs one auxiliary variable
#' \eqn{b_{ija} \in [0,1]} for each unique non-diagonal undirected edge
#' \eqn{(i,j)} with \eqn{i < j} and for each action \eqn{a}. The intended
#' semantics is:
#' \deqn{
#' b_{ija} = x_{ia} \land x_{ja}.
#' }
#'
#' Whenever both decision variables \eqn{x_{ia}} and \eqn{x_{ja}} exist in the
#' model, this conjunction is enforced by the linearization:
#' \deqn{
#' b_{ija} \le x_{ia},
#' }
#' \deqn{
#' b_{ija} \le x_{ja},
#' }
#' \deqn{
#' b_{ija} \ge x_{ia} + x_{ja} - 1.
#' }
#'
#' If one of the two action variables does not exist because the corresponding
#' \code{(pu, action)} pair is not feasible, the auxiliary variable is forced to
#' zero.
#'
#' Therefore, \eqn{b_{ija}=1} if and only if action \eqn{a} is selected in both
#' adjacent planning units \eqn{i} and \eqn{j}; otherwise \eqn{b_{ija}=0}.
#'
#' The exact objective coefficients are assembled later by the model builder
#' from:
#' \itemize{
#'   \item the action decision variables \eqn{x_{ia}},
#'   \item the edge-conjunction variables \eqn{b_{ija}},
#'   \item the relation weights \eqn{\omega_{ij}},
#'   \item the multiplier \eqn{\lambda},
#'   \item and, if supplied, the action-specific weights.
#' }
#'
#' If action-specific weights are provided, let \eqn{\alpha_a \ge 0} denote the
#' weight associated with action \eqn{a}. Then the resulting objective can be
#' interpreted as an action-wise compactness or fragmentation functional of the
#' form:
#' \deqn{
#' \min \sum_{a \in \mathcal{A}^{\star}} \alpha_a \,
#' F_a(x_{\cdot a}, b_{\cdot\cdot a}; \lambda \omega),
#' }
#' where \eqn{F_a} is the fragmentation expression induced by the selected
#' relation and the internal coefficient construction for action \eqn{a}.
#'
#' In practical terms, this objective penalizes solutions in which the same
#' action is spatially scattered or broken into separate patches, while allowing
#' different actions to form different spatial patterns.
#'
#' This differs from planning-unit fragmentation:
#' \itemize{
#'   \item \code{add_objective_min_fragmentation_pu()} encourages cohesion of the
#'   union of selected planning units,
#'   \item \code{add_objective_min_fragmentation_action()} encourages cohesion of
#'   each selected action pattern separately.
#' }
#'
#' Setting \code{weight_multiplier = 0} removes the contribution of the spatial
#' relation from the objective after scaling.
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
#'   )
#'
#' p <- add_spatial_boundary(
#'   x = p,
#'   name = "boundary",
#'   include_self = TRUE,
#'   edge_factor = 1
#' )
#'
#' p <- add_objective_min_fragmentation_action(
#'   p,
#'   relation_name = "boundary",
#'   actions = "restore",
#'   weight_multiplier = 1
#' )
#'
#' p$data$model_args
#'
#' @seealso
#' \code{\link{add_objective_min_fragmentation_pu}},
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
#' signed changes with \code{\link{add_objective_max_benefit}}.
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
#'   add_objective_max_benefit(features = "service", actions = "restore")
#' p$data$model_args
#'
#' @seealso
#' \code{\link{add_objective_max_benefit}},
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
    "1.3.0",
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
