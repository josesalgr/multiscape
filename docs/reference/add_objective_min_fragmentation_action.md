# Add objective: minimise action fragmentation

Encourage spatial cohesion separately for each selected action, rather
than only for the union of managed planning units.

## Usage

``` r
add_objective_min_fragmentation_action(
  x,
  relation_name = "boundary",
  weight_multiplier = 1,
  action_weights = NULL,
  actions = NULL,
  alias = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- relation_name:

  Character string giving the name of the spatial relation to use. The
  relation must already exist in `x$data$spatial_relations`.

- weight_multiplier:

  Numeric scalar greater than or equal to zero. Global multiplier
  applied to the relation weights when the objective is built.

- action_weights:

  Optional action weights. Either a named numeric vector with names
  equal to action ids, or a `data.frame` with columns `action` and
  `weight`. These weights scale the contribution of each action to the
  final objective.

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

This objective uses the action-selection decisions \\x\_{ia}\\ and a
previously registered spatial relation. For neighbouring units \\i\\ and
\\j\\, \\b\_{ija}=x\_{ia} \land x\_{ja}\\ represents whether the same
action \\a\\ occurs in both units. Adjacency of different actions does
not form a continuous patch of either action.

Use `actions` to select which action patterns contribute,
`action_weights` to adjust their relative importance, and
`weight_multiplier` to scale spatial relation weights.

Unlike
[`add_objective_min_fragmentation_planning_units()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_planning_units.md),
this objective distinguishes action identities. Combine it with coverage
or allocation requirements so an empty plan is not optimal.

## Repeated calls

With `alias = NULL`, one explicit single objective can be defined per
problem; a second unaliased definition raises an error. With an alias,
objectives accumulate under distinct names; a repeated alias raises an
error. Aliased definitions preserve an explicitly configured single
objective. To compare alternatives, start from the problem before its
objective was added.

## See also

[`add_objective_min_fragmentation_planning_units`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_planning_units.md),
[`add_spatial_boundary`](https://josesalgr.github.io/multiscape/reference/add_spatial_boundary.md),
[`add_spatial_relations`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md)

## Examples

``` r
# EXAMPLE: Form separate cohesive patches for two actions
#
# Each action costs one unit. Two action-specific budget equalities
# require exactly eight protection and eight restoration units.
# The default one-action-per-unit rule prevents overlapping actions.
sim <- load_sim_multiaction()

p <- create_problem(
  pu = sim$planning_units,
  features = sim$features,
  dist_features = sim$dist_features,
  cost = "cost"
) |>
  add_actions(sim$actions, cost = 1) |>
  add_spatial_boundary(name = "boundary", include_self = TRUE) |>
  add_constraint_budget(
    8, "equal", actions = "protect", include_pu_cost = FALSE
  ) |>
  add_constraint_budget(
    8, "equal", actions = "restore", include_pu_cost = FALSE
  ) |>
  add_objective_min_fragmentation_action(relation_name = "boundary", alias = "action_fragmentation")

# Unlike planning-unit fragmentation, this objective measures
# the cohesion of each action's selected units separately.
if (requireNamespace("rcbc", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
  get_objectives(solutions, format = "wide")
  print(plot_spatial_actions(solutions, layout = "single"))
}


```
