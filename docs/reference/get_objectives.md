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
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

problem <- create_problem(
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
    example_data$effects,
    effect_type = "delta"
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
  add_objective_max_benefit(alias = "benefit") |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(n = 3),
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
#>   solution_id   cost    benefit
#> 1           1   2.10  0.7616224
#> 2           2   2.73  2.2973781
#> 3           3 101.28 29.7962175
```
