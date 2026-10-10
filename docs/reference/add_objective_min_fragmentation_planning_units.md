# Add objective: minimise planning-unit fragmentation

Encourage cohesion of the selected planning units, regardless of which
action is implemented within each unit.

## Usage

``` r
add_objective_min_fragmentation_planning_units(
  x,
  relation_name = "boundary",
  weight_multiplier = 1,
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

- alias:

  Optional identifier used to register this objective for
  multi-objective workflows.

## Value

An updated `Problem` object.

## Details

This objective uses planning-unit selection variables \\w_i\\ and a
spatial relation registered with
[`add_spatial_relations()`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md)
or
[`add_spatial_boundary()`](https://josesalgr.github.io/multiscape/reference/add_spatial_boundary.md).
Relation weights \\\omega\_{ij}\\ are scaled by `weight_multiplier`.

The underlying model uses \\y\_{ij}=w_i \land w_j\\ to record whether
neighbouring units are both selected, encouraging spatially consolidated
selections. Action identities do not enter this spatial criterion:
adjacent units receiving different actions are part of the same selected
planning-unit set.

Without another requirement, selecting no units can be optimal. Combine
this objective with a budget equality, an area requirement, or an
ecological target that ensures meaningful management activity. For
action-specific cohesion, see
[`add_objective_min_fragmentation_action()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_action.md).

## Repeated calls

With `alias = NULL`, one explicit single objective can be defined per
problem; a second unaliased definition raises an error. With an alias,
objectives accumulate under distinct names; a repeated alias raises an
error. Aliased definitions preserve an explicitly configured single
objective. To compare alternatives, start from the problem before its
objective was added.

## See also

[`add_spatial_boundary`](https://josesalgr.github.io/multiscape/reference/add_spatial_boundary.md),
[`add_spatial_relations`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md),
[`add_objective_min_fragmentation_action`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_action.md),
[`add_objective_min_fragmentation_pu`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_pu.md)

## Examples

``` r
# EXAMPLE: Select a cohesive set of 12 planning units
#
# With one feasible action costing one unit, a budget equality
# forces exactly 12 selected units. Without this requirement,
# minimising fragmentation alone could select no units.
sim <- load_sim_multiaction()

p <- create_problem(
  pu = sim$planning_units,
  features = sim$features,
  dist_features = sim$dist_features,
  cost = "cost"
) |>
  add_actions(data.frame(id = "restore"), cost = 1) |>
  add_spatial_boundary(name = "boundary", include_self = TRUE) |>
  add_constraint_budget(12, "equal", include_pu_cost = FALSE) |>
  add_objective_min_fragmentation_planning_units(
    relation_name = "boundary", alias = "pu_fragmentation"
  )

# Cohesion is evaluated for the selected planning-unit pattern,
# irrespective of action identity. No additional objective is used.
if (requireNamespace("rcbc", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
  get_objectives(solutions, format = "wide")
  print(plot_spatial_planning_units(solutions))
}


```
