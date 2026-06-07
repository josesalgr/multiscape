# Get run-level results from a solution set

Extract the run table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Usage

``` r
get_runs(x, feasible_only = FALSE)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- feasible_only:

  Logical. If `TRUE`, return only runs whose status indicates that a
  usable solution may be available. Defaults to `FALSE`.

## Value

A `data.frame` with one row per attempted optimization run.

## Details

A run represents an attempted optimization solve. Each run has a unique
`run_id`, but only runs that produce a stored solution receive a
`solution_id`.

Consequently, the number of runs may exceed the number of stored
solutions. This commonly occurs when a multi-objective design contains
infeasible, failed, or interrupted runs.

The run table combines:

- run and solution identifiers;

- solver status, runtime, gap, and messages;

- multi-objective design parameters such as weights or epsilon levels;

- objective values stored in columns named `value_<objective>`.

If `feasible_only = TRUE`, runs with statuses `"optimal"`, `"feasible"`,
`"suboptimal"`, `"time_limit"`, or `"gap_limit"` are retained.

## See also

[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md),
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md),
[`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md),
[`run_manual`](https://josesalgr.github.io/multiscape/reference/run_manual.md)

## Examples

``` r
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
    runs = run_grid(
      n = 5,
      include_extremes = TRUE
    ),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # All attempted runs
  get_runs(solutions)

  # Only runs with a usable solver status
  get_runs(
    solutions,
    feasible_only = TRUE
  )
}
#>   run_id solution_id  status runtime gap value_cost value_benefit
#> 1      1          s1 optimal    0.00   0          2           0.0
#> 2      2          s2 optimal    0.00   0          3           3.5
#> 3      3          s3 optimal    0.02   0          3           3.5
#> 4      4          s4 optimal    0.00   0         12           7.0
#> 5      5          s5 optimal    0.00   0         18           7.5
```
