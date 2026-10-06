# Add objective: minimize intervention impact

**\[deprecated\]**

Deprecated; retained temporarily with its original behavior.

Define an objective that minimizes the impact associated with selecting
planning units for intervention.

This objective uses planning-unit selection variables rather than
summing the same impact repeatedly over multiple actions. As a result,
each planning unit contributes at most once to the objective, regardless
of how many feasible actions exist in that unit.

## Usage

``` r
add_objective_min_intervention_impact(
  x,
  impact_col = "amount",
  features = NULL,
  actions = NULL,
  alias = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- impact_col:

  Character string giving the column in the feature-distribution table
  that contains the per-`(pu, feature)` impact amount. The default is
  `"amount"`.

- features:

  Optional subset of features to include. Values may match
  `x$data$features$id` and, if present, `x$data$features$name`.

- actions:

  Optional subset of actions used to define the intervention context.
  Values may match `x$data$actions$id` and, if present,
  `x$data$actions$action_set`.

- alias:

  Optional identifier used to register this objective for
  multi-objective workflows.

## Value

An updated `Problem` object.

## Details

The legacy objective minimizes the reference amount in units where at
least one action in the selected scope is executed, counting each unit
once. Its original arguments, objective sense, and single/MO
formulations remain available during the transition.

## Migration

This function will be removed in a future version of multiscape. New
workflows should express action consequences with
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
and optimize signed changes with
[`add_objective_max_benefit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md).

This is not an automatic replacement. For deficit-based prioritization,
let \\q\_{if}\\ be the reference amount and \\M_f\\ a common ceiling for
feature \\f\\. Supply \\M_f-q\_{if}\\ as the restoration effect, or
\\M_f\\ as its outcome. If every plan restores exactly \\K\\ units and
at most one scoped action is selected in each unit, then
\$\$\sum_i(M_f-q\_{if})r_i=K M_f-\sum_iq\_{if}r_i.\$\$ Maximizing this
deficit is equivalent to minimizing the old baseline sum. Equal area
fixes \\K\\ only when units have equal effective action areas. With
variable effort, varying ceilings, or concurrent scoped actions,
equivalence is not guaranteed. The common ceiling is a modelling
assumption, not an empirical estimate of restoration response.

## Repeated calls

With `alias = NULL`, one explicit single objective can be defined per
problem; a second unaliased definition raises an error. With an alias,
objectives accumulate under distinct names; a repeated alias raises an
error. Aliased definitions preserve an explicitly configured single
objective. To compare alternatives, start from the problem before its
objective was added.

## See also

[`add_objective_max_benefit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md),
[`add_objective_min_loss`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)

## Examples

``` r
# Equal-area units with a fixed restoration effort of two units.
p <- create_problem(
  data.frame(id = 1:3, cost = 1, area = 1),
  data.frame(id = 1, name = "service"),
  data.frame(pu = 1:3, feature = 1, amount = c(0.2, 0.6, 0.9))
) |>
  add_actions(data.frame(id = "restore"), cost = 1) |>
  add_effects(data.frame(action = "restore", feature = "service", outcome = 1)) |>
  add_constraint_area(2, "equal", tolerance = 0, actions = "restore") |>
  add_objective_max_benefit(features = "service", actions = "restore")
#> Warning: `add_objective_max_benefit()` was deprecated in multiscape 1.4.0.
#> i Please use `add_objective_max_effect()` instead.
p$data$model_args
#> $model_type
#> [1] "maximizeBenefits"
#> 
#> $objective_id
#> [1] "max_effect"
#> 
#> $objective_args
#> $objective_args$effect_sense
#> [1] "max"
#> 
#> $objective_args$actions
#> [1] 1
#> 
#> $objective_args$features
#> [1] 1
#> 
#> 
```
