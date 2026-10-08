# Meseta Iberica: formulation, trade-offs and spatial comparison

# install-cran
install.packages("multiscape")

# install-github
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("josesalgr/multiscape")

# meseta-inputs
library(multiscape)

meseta <- load_meseta()

data.frame(
  planning_units = nrow(meseta$planning_units),
  features = nrow(meseta$features),
  actions = nrow(meseta$actions)
)

meseta$actions

# meseta-map
plot(
  sf::st_geometry(meseta$planning_units),
  border = "grey75",
  col = "grey95",
  lwd = 0.15,
  axes = FALSE
)

# meseta-inspect
head(meseta$action_costs)
head(meseta$outcomes)
head(meseta$targets)

# meseta-stage-1
pu <- meseta$planning_units
pu$cost <- 0

problem <- create_problem(
  pu = pu,
  features = meseta$features,
  dist_features = meseta$dist_features,
  cost = "cost"
)

# meseta-stage-2-actions
strategy_names <- setNames(meseta$actions$name, meseta$actions$id)
actions <- data.frame(id = meseta$actions$name)

costs <- meseta$action_costs
costs$action <- unname(strategy_names[as.character(costs$action)])

problem <- add_actions(problem, actions = actions, cost = costs)

# effect-input-examples
# Three alternative ways to describe the SAME result; use one of them.
data.frame(pu = 1, action = "restore", feature = "habitat", outcome = 130)
data.frame(pu = 1, action = "restore", feature = "habitat", effect = 30)
data.frame(pu = 1, action = "restore", feature = "habitat", relative_change = 0.30)

# meseta-stage-2-effects
outcomes <- meseta$outcomes
outcomes$action <- unname(strategy_names[as.character(outcomes$action)])

problem <- add_effects(problem, effects = outcomes)

# meseta-stage-3
problem <- problem |>
  add_constraint_action_cardinality(
    count = 1, sense = "max", name = "one_strategy_per_cell"
  ) |>
  add_constraint_targets_absolute(meseta$targets)

# meseta-stage-4
problem <- problem |>
  add_spatial_relations(meseta$boundary, name = "boundary") |>
  add_objective_min_cost(include_pu_cost = FALSE, alias = "cost") |>
  add_objective_min_fragmentation_action(
    relation_name = "boundary", alias = "spatial"
  )

# meseta-method
# Keep the formulation before choosing an optimisation method.
action_problem <- problem
problem <- set_method_weighted_sum(
  problem,
  aliases = c("cost", "spatial"),
  runs = set_runs_manual(data.frame(weight_cost = 1, weight_spatial = 0.5)),
  normalize_weights = FALSE,
  objective_scaling = FALSE
)

# meseta-solve
problem <- set_solver_gurobi(
  problem,
  gap_limit = 0.02, time_limit = 300, cores = 2,
  solver_params = list(Method = 2, NodefileStart = 0.5),
  verbose = TRUE
)
solutions <- solve(problem)

# meseta-results
get_runs(solutions)
performance <- get_objectives(solutions, format = "wide")
performance$scalar_objective <- performance$cost + 0.5 * performance$spatial
performance

# meseta-targets
target_achievement <- get_targets(solutions)
head(target_achievement)
all(target_achievement$met)

# meseta-maps
plot_spatial_actions(
  solutions, solutions = 1, actions = actions$id, layout = "facet", ncol = 2
)

# meseta-sensitivity
spatial_exploration <- set_method_weighted_sum(
  action_problem,
  aliases = c("cost", "spatial"),
  runs = set_runs_manual(data.frame(
    weight_cost = rep(1, 6),
    weight_spatial = c(0, 0.1, 0.25, 0.5, 1, 2)
  )),
  normalize_weights = FALSE,
  objective_scaling = FALSE
)
spatial_exploration <- set_solver_gurobi(
  spatial_exploration, gap_limit = 0.02, time_limit = 300, cores = 2,
  solver_params = list(Method = 2, NodefileStart = 0.5), verbose = TRUE
)
alternatives <- solve(spatial_exploration)
get_runs(alternatives)
plot_tradeoff(
  alternatives, objectives = c("cost", "spatial"),
  connect = FALSE, label_runs = TRUE
)

# meseta-alternative-decisions
selection_similarity(alternatives, metric = "jaccard", format = "matrix")
action_frequency <- selection_frequency(alternatives)
head(action_frequency[order(-action_frequency$frequency), ], 10)

# meseta-frontier-diagnostics
knee <- frontier_knee(alternatives, objectives = c("cost", "spatial"))
knee
frontier_extremes(alternatives, objectives = c("cost", "spatial"))
frontier_distances(alternatives, objectives = c("cost", "spatial"))

# meseta-linkage
neighbors <- frontier_neighbors(alternatives, objectives = c("cost", "spatial"))
linkage <- linkage_distances(
  alternatives, objectives = c("cost", "spatial"),
  pairs = neighbors, decision_metric = "jaccard"
)
linkage
turnover <- linkage_turnover(
  alternatives, objectives = c("cost", "spatial"),
  pairs = neighbors, decision_metric = "jaccard"
)
turnover

# meseta-transition-and-consistency
linkage_contrasts(turnover, type = "high_reconfiguration", n = 2)
linkage_transition(
  alternatives, from = 1, to = 2, objectives = c("cost", "spatial")
)
head(selection_consistency(alternatives))
