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

## See also

[`add_objective_min_cost`](https://josesalgr.github.io/multiscape/reference/add_objective_min_cost.md),
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

profit <- example_data$action_costs
profit$profit <- 10 - profit$cost
profit$cost <- NULL

p <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
) |>
  add_actions(
    example_data$actions,
    cost = example_data$action_costs
  ) |>
  add_profit(profit)

p1 <- add_objective_max_profit(p)
p1$data$model_args
#> $model_type
#> [1] "maximizeProfit"
#> 
#> $objective_id
#> [1] "max_profit"
#> 
#> $objective_args
#> $objective_args$profit_col
#> [1] "profit"
#> 
#> $objective_args$actions
#> NULL
#> 
#> 

p2 <- add_objective_max_profit(
  p,
  actions = "restore"
)
p2$data$model_args
#> $model_type
#> [1] "maximizeProfit"
#> 
#> $objective_id
#> [1] "max_profit"
#> 
#> $objective_args
#> $objective_args$profit_col
#> [1] "profit"
#> 
#> $objective_args$actions
#> [1] "restore"
#> 
#> 
```
