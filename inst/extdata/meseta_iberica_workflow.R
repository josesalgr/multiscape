# Four-action formulation used by the introductory tutorial.
build_meseta_problem <- function(meseta, spatial_weights = 0.5) {
  pu <- meseta$planning_units
  pu$cost <- 0
  
  problem <- create_problem(
    pu = pu,
    features = meseta$features,
    dist_features = meseta$dist_features,
    cost = "cost"
  )
  strategy_names <- setNames(meseta$actions$name, meseta$actions$id)
  actions <- data.frame(id = meseta$actions$name)
  
  costs <- meseta$action_costs
  costs$action <- unname(strategy_names[as.character(costs$action)])
  
  problem <- add_actions(problem, actions = actions, cost = costs)
  outcomes <- meseta$outcomes
  outcomes$action <- unname(strategy_names[as.character(outcomes$action)])
  
  problem <- add_effects(problem, effects = outcomes)
  problem <- problem |>
    add_constraint_action_cardinality(
      count = 1, sense = "max", name = "one_strategy_per_cell"
    ) |>
    add_constraint_targets_absolute(meseta$targets)
  problem <- problem |>
    add_spatial_relations(meseta$boundary, name = "boundary") |>
    add_objective_min_cost(include_pu_cost = FALSE, alias = "cost") |>
    add_objective_min_fragmentation_action(
      relation_name = "boundary", alias = "spatial"
    )
  problem <- set_method_weighted_sum(
    problem,
    aliases = c("cost", "spatial"),
    runs = set_runs_manual(data.frame(weight_cost = rep(1, length(spatial_weights)), weight_spatial = spatial_weights)),
    normalize_weights = FALSE,
    objective_scaling = FALSE
  )
  problem <- set_solver_gurobi(
    problem,
    gap_limit = 0.02, time_limit = 300, cores = 2,
    solver_params = list(Method = 2, NodefileStart = 0.5),
    verbose = TRUE
  )
  problem
}
