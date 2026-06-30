# Get objective values from a solution set

Extract objective values from the runs stored in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Usage

``` r
get_objectives(x, format = c("wide", "long"))
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- format:

  Character. Output representation, either `"long"` or `"wide"`.
  Defaults to `"long"`.

## Value

If `format = "long"`, a `data.frame` with columns `run_id`,
`solution_id`, `objective`, and `value`.

If `format = "wide"`, a `data.frame` with `run_id`, `solution_id`, and
one column per objective.

## Details

Objective values are read from run-table columns named
`value_<objective>`, where `<objective>` is the registered objective
alias.

Runs without a stored solution may contain missing objective values. Use
`feasible_only = TRUE`, or filter the `SolutionSet` beforehand, when
only solved runs should be included.

In long format, every run-objective combination occupies one row. In
wide format, every run occupies one row and every objective occupies one
column.

## See also

[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`frontier_extremes`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md),
[`frontier_distances`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md)

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
    runs = set_runs_grid(
      n = 5
    ),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # Long format
  get_objectives(solutions)

  # Wide format
  get_objectives(
    solutions,
    format = "wide"
  )

  # Objective values from usable runs only
  get_objectives(
    solutions
  )
}
#>   solution_id cost benefit
#> 1           1    2     0.0
#> 2           2    3     3.5
#> 3           3    3     3.5
#> 4           4   12     7.0
#> 5           5   18     7.5
```
