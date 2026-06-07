# Define a manual multi-objective run design

Create an explicit run-design specification in which each row defines
one multi-objective optimization run.

`run_manual()` is used when the exact objective weights or epsilon
levels should be controlled by the user instead of being generated
automatically with
[`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md).

## Usage

``` r
run_manual(x)
```

## Arguments

- x:

  A non-empty `data.frame` with one row per optimization run. Columns
  must use the naming conventions required by the selected
  multi-objective method, such as `weight_<alias>` or `eps_<alias>`.

## Value

An object of class `RunManual` and `RunDesign`. The object stores the
supplied run table and is intended to be passed to the `runs` argument
of a multi-objective method function.

## Details

The input must be a `data.frame` with one row per requested optimization
run. The required columns depend on the multi-objective method in which
the design is used.

**Weighted-sum designs**

For
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
weight columns must follow the convention:


    weight_<alias>

where `<alias>` is the alias of a registered objective.

For example, objectives with aliases `"cost"` and `"benefit"` require:


    weight_cost
    weight_benefit

Each row defines the weights used in one weighted-sum run. Whether
weights must already sum to one depends on the normalization settings
supplied to
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md).

**Epsilon-constraint and AUGMECON designs**

For
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md)
and
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
epsilon columns must follow the convention:


    eps_<alias>

where `<alias>` identifies a constrained secondary objective.

The primary objective is optimized directly and therefore normally does
not require an epsilon column. Each row defines one combination of
epsilon bounds for the secondary objectives.

Column names are matched against the registered objective aliases when
the run design is resolved by the corresponding `set_method_*()`
function. Therefore, aliases containing spaces or other non-syntactic
characters should be avoided when manual run tables are expected to be
used.

`run_manual()` performs only structural validation of the supplied
object. Method-specific validation—including required columns, unknown
aliases, missing values, weight validity, and epsilon compatibility—is
performed when the design is attached to a multi-objective method or
resolved before solving.

Additional columns should not be used unless they are explicitly
supported by the selected method. The order of rows is preserved and
corresponds to the requested run order.

Manual designs are useful when:

- exact preference weights are known;

- policy-relevant epsilon thresholds must be evaluated;

- irregular regions of the frontier require denser sampling;

- runs must reproduce a previously published experimental design;

- a small number of selected trade-off scenarios is preferred over a
  regular automatic grid.

## See also

[`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md),
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md)

## Examples

``` r
# Create an explicit weighted-sum design
weighted_runs <- run_manual(
  data.frame(
    weight_cost = c(1.0, 0.75, 0.50, 0.25, 0.0),
    weight_benefit = c(0.0, 0.25, 0.50, 0.75, 1.0)
  )
)

weighted_runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   weight_cost weight_benefit
#> 1        1.00           0.00
#> 2        0.75           0.25
#> 3        0.50           0.50
#> 4        0.25           0.75
#> 5        0.00           1.00
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"

# Create an explicit epsilon-constraint design
epsilon_runs <- run_manual(
  data.frame(
    eps_benefit = c(2, 4, 6, 8)
  )
)

epsilon_runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   eps_benefit
#> 1           2
#> 2           4
#> 3           6
#> 4           8
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"

# Use a manual design in a weighted-sum workflow
pu <- data.frame(
  id = 1:4,
  cost = c(1, 2, 3, 4)
)

features <- data.frame(
  id = 1:2,
  name = c("sp1", "sp2")
)

dist_features <- data.frame(
  pu = c(1, 1, 2, 3, 4),
  feature = c(1, 2, 2, 1, 2),
  amount = c(5, 2, 3, 4, 1)
)

actions <- data.frame(
  id = c("conservation", "restoration")
)

effects <- data.frame(
  action = rep(actions$id, each = 2),
  feature = rep(features$id, times = 2),
  multiplier = c(
    1.0, 1.0,
    1.5, 1.5
  )
)

problem <- create_problem(
  pu = pu,
  features = features,
  dist_features = dist_features,
  cost = "cost"
) |>
  add_actions(
    actions = actions,
    cost = c(
      conservation = 1,
      restoration = 2
    )
  ) |>
  add_effects(
    effects = effects,
    effect_type = "after"
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_max_benefit(alias = "benefit") |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = run_manual(
      data.frame(
        weight_cost = c(1.0, 0.5, 0.0),
        weight_benefit = c(0.0, 0.5, 1.0)
      )
    ),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # Inspect the requested manual design and resulting objective values
  get_runs(solutions)
  get_objectives(
    solutions,
    format = "wide"
  )
}
#>   run_id solution_id cost benefit
#> 1      1          s1    2     0.0
#> 2      2          s2    3     3.5
#> 3      3          s3   18     7.5
```
