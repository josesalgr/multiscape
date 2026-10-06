# Minimize signed effects relative to the reference

Minimize the sum of signed effects, including joint interaction
corrections. Increases and decreases can compensate across units and
features.

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

This is not the loss-only criterion. Effects are summed in their
original units; aggregate only commensurate features or deliberate sums.
An unselected unit contributes zero effect. Action subsets include joint
corrections only when every member belongs to the subset.

## See also

[`add_objective_max_effect()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_effect.md),
[`add_objective_min_loss()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)
