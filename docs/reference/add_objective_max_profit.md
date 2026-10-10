# Add objective: maximize profit

Define an objective that maximizes total profit from selected planning
unit–action decisions.

## Usage

``` r
add_objective_max_profit(
  x,
  profit_col = "profit",
  actions = NULL,
  alias = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- profit_col:

  Character string giving the profit column in the stored profit table.

- actions:

  Optional subset of actions to include. Values may match
  `x$data$actions$id` and, if present, `x$data$actions$action_set`. If
  `NULL`, all actions are included.

- alias:

  Optional identifier used to register this objective for
  multi-objective workflows.

## Value

An updated `Problem` object.

## Details

Use this function when the objective is to maximize gross economic
return, without subtracting planning-unit or action costs.

Let \\x\_{ia} \in \\0,1\\\\ denote whether action \\a\\ is selected in
planning unit \\i\\, and let \\\pi\_{ia}\\ denote the profit associated
with that decision, as taken from column `profit_col` in the stored
profit table.

If all actions are included, the objective is:

\$\$ \max \sum\_{(i,a) \in \mathcal{D}} \pi\_{ia} x\_{ia}, \$\$

where \\\mathcal{D}\\ denotes the set of feasible planning unit–action
decisions.

If `actions` is provided, only the selected subset contributes to the
objective. Letting \\\mathcal{D}^{\star}\\ denote the feasible decisions
whose action belongs to the selected subset, the objective becomes:

\$\$ \max \sum\_{(i,a) \in \mathcal{D}^{\star}} \pi\_{ia} x\_{ia}. \$\$

This objective considers profit only. It does not subtract planning-unit
costs or action costs. For a net-profit formulation, use
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md).

## Repeated calls

With `alias = NULL`, one explicit single objective can be defined per
problem; a second unaliased definition raises an error. With an alias,
objectives accumulate under distinct names; a repeated alias raises an
error. Aliased definitions preserve an explicitly configured single
objective. To compare alternatives, start from the problem before its
objective was added.

## See also

[`add_objective_min_cost`](https://josesalgr.github.io/multiscape/reference/add_objective_min_cost.md),
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md)

## Examples

``` r
# EXAMPLE: Maximise gross economic return across the landscape
#
# Assign hypothetical profits that favour protection in the west
# and restoration in the east. All values are positive.
sim <- load_sim_multiaction()
returns <- sim$action_costs[, c("pu", "action")]
x_coord <- sim$planning_units$x[
  match(returns$pu, sim$planning_units$id)
]
returns$profit <- ifelse(
  returns$action == "protect", 12 - x_coord, 4 + x_coord
)

p <- create_problem(
  pu = sim$planning_units,
  features = sim$features,
  dist_features = sim$dist_features,
  cost = "cost"
) |>
  add_actions(sim$actions, cost = 9.5) |>
  add_profit(returns) |>
  add_objective_max_profit(alias = "profit")

# Implementation costs are NOT deducted in this objective.
# With positive returns and at most one action per unit, the
# model chooses the more profitable action in each unit.
if (requireNamespace("rcbc", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
  get_objectives(solutions, format = "wide")
  print(plot_spatial_actions(solutions, layout = "single"))
}


```
