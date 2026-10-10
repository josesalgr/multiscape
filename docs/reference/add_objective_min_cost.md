# Add objective: minimize cost

Define an objective that minimizes the total cost of the solution.

Depending on the function arguments, the objective may include
planning-unit costs, action costs, or both. Action costs can optionally
be restricted to a subset of actions.

## Usage

``` r
add_objective_min_cost(
  x,
  include_pu_cost = TRUE,
  include_action_cost = TRUE,
  actions = NULL,
  alias = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- include_pu_cost:

  Logical. If `TRUE`, include planning-unit costs in the objective.

- include_action_cost:

  Logical. If `TRUE`, include action costs in the objective.

- actions:

  Optional subset of actions to include in the action-cost component.
  Values may match `x$data$actions$id` and, if present,
  `x$data$actions$action_set`. If `NULL`, all feasible actions are
  included in the action-cost term.

- alias:

  Optional identifier used to register this objective for
  multi-objective workflows.

## Value

An updated `Problem` object.

## Details

Use this function when the planning problem is framed primarily as a
cost-minimization problem, with costs arising from planning-unit
selection, action implementation, or both.

Let \\\mathcal{I}\\ be the set of planning units and let \\\mathcal{D}
\subseteq \mathcal{I} \times \mathcal{A}\\ denote the set of feasible
planning unit–action decisions.

Let:

- \\w_i \in \\0,1\\\\ denote whether planning unit \\i\\ is selected,

- \\x\_{ia} \in \\0,1\\\\ denote whether action \\a\\ is selected in
  planning unit \\i\\,

- \\c_i^{PU} \ge 0\\ denote the planning-unit cost of unit \\i\\,

- \\c\_{ia}^{A} \ge 0\\ denote the cost of selecting action \\a\\ in
  planning unit \\i\\.

The most general form of this objective is:

\$\$ \min \left( \sum\_{i \in \mathcal{I}} c_i^{PU} w_i + \sum\_{(i,a)
\in \mathcal{D}^{\star}} c\_{ia}^{A} x\_{ia} \right), \$\$

where \\\mathcal{D}^{\star}\\ denotes the subset of feasible decisions
whose action contributes to the action-cost term.

If `include_pu_cost = FALSE`, the planning-unit cost term is omitted.

If `include_action_cost = FALSE`, the action-cost term is omitted.

If `actions = NULL`, all feasible actions contribute to the action-cost
term. If `actions` is supplied, only the selected subset contributes to
that term. Planning-unit costs are never subset by `actions`; they are
always global whenever `include_pu_cost = TRUE`.

## Repeated calls

With `alias = NULL`, one explicit single objective can be defined per
problem; a second unaliased definition raises an error. With an alias,
objectives accumulate under distinct names; a repeated alias raises an
error. Aliased definitions preserve an explicitly configured single
objective. To compare alternatives, start from the problem before its
objective was added.

## See also

[`add_objective_max_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_profit.md),
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md)

## Examples

``` r
# EXAMPLE: Minimum-cost management with a woodland target
#
# Use the 64 planning-unit landscape. The hypothetical outcome of 1
# credits one unit of woodland for either action in each selected unit.
# A target of 12 therefore requires at least 12 interventions.
sim <- load_sim_multiaction()

p <- create_problem(
  pu = sim$planning_units,
  features = sim$features,
  dist_features = sim$dist_features,
  cost = "cost"
) |>
  add_actions(sim$actions, cost = sim$action_costs) |>
  add_effects(data.frame(
    action = c("protect", "restore"),
    feature = "woodland", outcome = 1
  )) |>
  add_constraint_targets_absolute(12, features = "woodland") |>
  add_objective_min_cost(include_pu_cost = FALSE, alias = "cost")

# The solver selects the least costly set of actions that meets the target.
# This is a single-objective model: no set_method_*() call is needed.
if (requireNamespace("rcbc", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
  get_objectives(solutions, format = "wide")
  print(plot_spatial_actions(solutions, layout = "single"))
}


```
