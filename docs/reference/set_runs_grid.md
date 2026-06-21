# Define an automatic multi-objective run grid

Create an automatic run-design specification for generating multiple
optimization runs in a multi-objective workflow.

`set_runs_grid()` provides a common interface for controlling the
resolution of weighted-sum, epsilon-constraint, and AUGMECON run
designs. The returned object does not contain the final run table.
Instead, it stores the requested grid resolution, which is resolved
later by the corresponding `set_method_*()` function using the
registered objectives and their optimization senses.

## Usage

``` r
set_runs_grid(n)
```

## Arguments

- n:

  Integer. Resolution of the automatically generated run design. Must be
  at least `2`. The final number of optimization runs may differ from
  `n`, depending on the selected method and the number of objectives.

## Value

An object of class `RunGrid` and `RunDesign`. The object stores the
requested grid resolution and is intended to be supplied to the `runs`
argument of a multi-objective method function.

## Details

Multi-objective methods generally require several optimization runs to
explore different regions of objective space. `set_runs_grid()` asks
multiscape to generate those runs automatically from a grid.

The interpretation of the grid depends on the selected method:

- In
  [`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
  the grid defines combinations of objective weights. For two
  objectives, `n` gives the number of weight combinations between the
  two pure-objective extremes. For three or more objectives, `n`
  controls the resolution of the generated simplex grid. The generated
  weights are normalized according to the method settings and represent
  alternative preferences among the registered objectives.

- In
  [`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
  the grid defines epsilon levels for the constrained objective. The
  primary objective is optimized directly, while the remaining objective
  is progressively restricted across the generated runs.

- In
  [`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
  the grid defines epsilon levels for the secondary objectives, which
  are then used in the augmented epsilon-constraint formulation. When
  several secondary objectives are used, the final run design is
  obtained by combining the generated epsilon levels across objectives.

The argument `n` controls the resolution of the automatically generated
design. It should not always be interpreted as the final number of runs.
For example, when several secondary objectives are present, epsilon
levels may be combined across objectives and generate more runs than the
value supplied to `n`. Likewise, the number of valid weighted
combinations depends on the number of objectives and on how the weight
grid is constructed.

Boundary levels are always included. For weighted-sum methods, this
means that pure-objective weight vectors are included, where all weight
is assigned to one objective. For epsilon-constraint and AUGMECON
methods, this means that the lower and upper bounds of the automatically
derived epsilon ranges are included.

Including boundary levels helps recover the best observed value of each
objective and provides reference points for subsequent frontier
analyses.

The resolved design is stored in the resulting
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object and can be inspected after solving through
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md).

Use
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
instead when exact weights or epsilon levels must be supplied
explicitly.

## See also

[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md),
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md)

## Examples

``` r
# Create an automatic run-grid specification
grid <- set_runs_grid(n = 5)

grid
#> $type
#> [1] "grid"
#> 
#> $n
#> [1] 5
#> 
#> $include_extremes
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunGrid"   "RunDesign"

# Use the automatic grid in a weighted-sum workflow
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
    runs = set_runs_grid(n = 5),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # Inspect the resolved run design and objective values
  get_runs(solutions)
  get_objectives(
    solutions,
    format = "wide"
  )
}
#>   solution_id cost benefit
#> 1           1    2     0.0
#> 2           2    3     3.5
#> 3           3    3     3.5
#> 4           4   12     7.0
#> 5           5   18     7.5
```
