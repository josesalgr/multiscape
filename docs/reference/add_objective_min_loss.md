# Deprecated objective: minimize loss

Minimize deterioration relative to the reference scenario. Positive
changes in other planning units or features do not offset these losses.

## Usage

``` r
add_objective_min_loss(x, actions = NULL, features = NULL, alias = NULL)
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

An updated `Problem` object.

## Details

Let \\\Delta\_{if}(x)\\ be the signed change for planning unit \\i\\ and
feature \\f\\, after combining selected individual actions and their
interaction corrections. The objective is \$\$\min \sum\_{i,f}
\max(-\Delta\_{if}(x), 0).\$\$ The positive/negative split is applied
after joint aggregation within each unit and feature, before summing
across units or features. A negative interaction correction does not
itself represent a loss if the final change remains positive.
Conversely, gains elsewhere cannot cancel deterioration.

With one action per unit this retains the existing loss-only criterion.
With concurrent actions, an exact MILP linearization represents
mixed-sign final losses in single-objective and all multi-objective
methods, including when loss is constrained, has zero weight, or is
evaluated after another objective is optimized. Non-negative effects
give a valid zero-loss objective.

Action and feature subsets follow
[`add_objective_max_benefit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md):
an interaction is included only when all of its members belong to the
scope. An unselected unit contributes zero loss. Use targets or other
objectives if avoiding intervention altogether should not be an
acceptable solution.

## Lifecycle

Deprecated since 1.4.0. Legacy calls retain the negative-part criterion.
add_objective_min_effect() is not a mathematically equivalent
replacement.

## Repeated calls

With `alias = NULL`, one explicit single objective can be defined per
problem; a second unaliased definition raises an error. With an alias,
objectives accumulate under distinct names; a repeated alias raises an
error. Aliased definitions preserve an explicitly configured single
objective. To compare alternatives, start from the problem before its
objective was added.

## See also

[`add_objective_max_benefit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md),
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

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
  add_effects(
    example_data$effect_assumptions
  )

p1 <- add_objective_min_loss(p)
#> Warning: `add_objective_min_loss()` was deprecated in multiscape 1.4.0.
#> i Use add_objective_min_effect() only when minimizing signed change is
#>   intended. It is not an equivalent replacement: this legacy function retains
#>   the negative-part criterion after aggregation within each unit and feature.
p1$data$model_args
#> $model_type
#> [1] "minimizeLosses"
#> 
#> $objective_id
#> [1] "min_loss"
#> 
#> $objective_args
#> $objective_args$actions
#> NULL
#> 
#> $objective_args$features
#> NULL
#> 
#> 

p2 <- add_objective_min_loss(
  p,
  actions = "restore"
)
p2$data$model_args
#> $model_type
#> [1] "minimizeLosses"
#> 
#> $objective_id
#> [1] "min_loss"
#> 
#> $objective_args
#> $objective_args$actions
#> [1] 2
#> 
#> $objective_args$features
#> NULL
#> 
#> 

p3 <- add_objective_min_loss(
  p,
  features = 1
)
p3$data$model_args
#> $model_type
#> [1] "minimizeLosses"
#> 
#> $objective_id
#> [1] "min_loss"
#> 
#> $objective_args
#> $objective_args$actions
#> NULL
#> 
#> $objective_args$features
#> [1] 1
#> 
#> 
```
