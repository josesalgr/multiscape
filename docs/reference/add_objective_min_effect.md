# Add objective: minimise signed effect

Minimise total signed changes relative to the reference. Whether a
decrease is desirable depends on the feature being optimised.

## Usage

``` r
add_objective_min_effect(x, actions = NULL, features = NULL, alias = NULL)
```

## Arguments

- x:

  A `Problem` object.

- actions:

  Optional subset of actions to include in the objective. Values may
  match `x$data$actions$id` and, if present,
  `x$data$actions$action_set`. If `NULL`, all actions are included.

- features:

  Optional subset of features to include in the objective. Values may
  match `x$data$features$id` and, if present, `x$data$features$name`. If
  `NULL`, all features are included.

- alias:

  Optional identifier used to register this objective for
  multi-objective workflows.

## Value

An updated Problem object.

## Details

For the selected actions and features, this objective minimises
\\\sum\_{i,f} \Delta\_{if}(x)\\, where \\\Delta\_{if}(x)\\ is the signed
change after accounting for joint effects. Increases and decreases can
offset one another across units or features.

For instance, minimising signed fuel-load change favours reductions in
fuel load. Specify a feature subset when features are measured in
incompatible units. Unselected units contribute zero change, and
implementation costs are not subtracted.

This differs from the deprecated
[`add_objective_min_loss()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md),
which penalises only the negative part of aggregated changes.

## See also

[`add_objective_max_effect()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_effect.md),
[`add_objective_min_loss()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)

## Examples

``` r
# EXAMPLE: Minimise the signed change in fuel load
#
# Use the geometry from the bundled 64-unit landscape, with a simple
# hypothetical fuel-load feature that increases from west to east.
# A 25% reduction has a NEGATIVE signed effect, so minimising the
# effect favours the units with the greatest fuel-load reduction.
sim <- load_sim_multiaction()

p <- create_problem(
  pu = sim$planning_units,
  features = data.frame(id = 1L, name = "fuel_load"),
  dist_features = data.frame(
    pu = sim$planning_units$id, feature = 1L,
    amount = 10 + sim$planning_units$x
  ),
  cost = "cost"
) |>
  add_actions(data.frame(id = "thin"), cost = 1) |>
  add_effects(data.frame(
    action = "thin", feature = "fuel_load", relative_change = -0.25
  )) |>
  add_constraint_budget(12, "equal", include_pu_cost = FALSE) |>
  add_objective_min_effect(features = "fuel_load", alias = "fuel_reduction")

# With one monetary unit per action, the budget equality selects
# exactly 12 units. Without it, this negative-effect objective
# could favour implementing the action everywhere.
if (requireNamespace("rcbc", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  solutions <- solve(set_solver_cbc(p, time_limit = 30, verbose = FALSE))
  get_objectives(solutions, format = "wide")
  print(plot_spatial_actions(solutions, layout = "single"))
}


```
