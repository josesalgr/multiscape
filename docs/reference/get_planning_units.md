# Get planning-unit results from a solution set

Extract the planning-unit summary table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

The returned table summarizes solution values at the planning-unit level
and typically includes a `selected` indicator showing whether each
planning unit is selected in a solution.

## Usage

``` r
get_planning_units(x, solution = NULL, ...)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- solution:

  Optional positive integer giving the solution index to extract. If
  `NULL`, all solutions are returned when available.

- ...:

  Deprecated arguments kept for backwards compatibility. Currently
  supports `run` and `solution_id`, which are redirected to `solution`.

## Value

A `data.frame` containing the stored planning-unit summary. Typical
columns include planning-unit identifiers, optional labels, and a
`selected` indicator.

## Details

This function reads the planning-unit summary stored in `x$summary$pu`.
It does not reconstruct the table from the raw decision vector; it
simply returns the stored summary after optional run filtering.

Let \\w_i\\ denote the planning-unit selection variable for planning
unit \\i\\. In standard multiscape workflows, the `selected` column is
the user-facing representation of that planning-unit decision, typically
coded as `0` or `1`.

If `solution` is provided, only rows belonging to that solution are
returned. This requires the summary table to contain a `solution_id`
column.

To return only selected planning units, filter the returned table using
`selected == 1`.

## See also

[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`get_features`](https://josesalgr.github.io/multiscape/reference/get_features.md),
[`get_targets`](https://josesalgr.github.io/multiscape/reference/get_targets.md)

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

  # Planning-unit results for all stored runs
  get_planning_units(solutions)

  # Return only selected planning units
  selected_pu <- get_planning_units(solutions)
  selected_pu <- selected_pu[selected_pu$selected == 1L, , drop = FALSE]
  selected_pu

  # Extract one run using its solution_id
  solution_ids <- get_runs(solutions)$solution_id

  get_planning_units(
    solutions,
    solution = solution_ids[1]
  )
}
#>    solution_id id cost locked_in locked_out selected
#> 1            1  1    0     FALSE      FALSE        0
#> 2            1  2    0     FALSE      FALSE        0
#> 3            1  3    0     FALSE      FALSE        0
#> 4            1  4    0     FALSE      FALSE        0
#> 5            1  5    0     FALSE      FALSE        0
#> 6            1  6    0     FALSE      FALSE        0
#> 7            1  7    0     FALSE      FALSE        0
#> 8            1  8    0     FALSE      FALSE        0
#> 9            1  9    0     FALSE      FALSE        1
#> 10           1 10    0     FALSE      FALSE        0
#> 11           1 11    0     FALSE      FALSE        0
#> 12           1 12    0     FALSE      FALSE        0
#> 13           1 13    0     FALSE      FALSE        0
#> 14           1 14    0     FALSE      FALSE        0
#> 15           1 15    0     FALSE      FALSE        0
#> 16           1 16    0     FALSE      FALSE        0
#> 17           1 17    0     FALSE      FALSE        0
#> 18           1 18    0     FALSE      FALSE        0
#> 19           1 19    0     FALSE      FALSE        0
#> 20           1 20    0     FALSE      FALSE        0
#> 21           1 21    0     FALSE      FALSE        0
#> 22           1 22    0     FALSE      FALSE        0
#> 23           1 23    0     FALSE      FALSE        0
#> 24           1 24    0     FALSE      FALSE        0
#> 25           1 25    0     FALSE      FALSE        0
#> 26           1 26    0     FALSE      FALSE        0
#> 27           1 27    0     FALSE      FALSE        0
#> 28           1 28    0     FALSE      FALSE        0
#> 29           1 29    0     FALSE      FALSE        0
#> 30           1 30    0     FALSE      FALSE        0
#> 31           1 31    0     FALSE      FALSE        0
#> 32           1 32    0     FALSE      FALSE        0
#> 33           1 33    0     FALSE      FALSE        1
#> 34           1 34    0     FALSE      FALSE        0
#> 35           1 35    0     FALSE      FALSE        0
#> 36           1 36    0     FALSE      FALSE        0
#> 37           1 37    0     FALSE      FALSE        0
#> 38           1 38    0     FALSE      FALSE        0
#> 39           1 39    0     FALSE      FALSE        0
#> 40           1 40    0     FALSE      FALSE        0
#> 41           1 41    0     FALSE      FALSE        0
#> 42           1 42    0     FALSE      FALSE        0
#> 43           1 43    0     FALSE      FALSE        0
#> 44           1 44    0     FALSE      FALSE        0
#> 45           1 45    0     FALSE      FALSE        0
#> 46           1 46    0     FALSE      FALSE        0
#> 47           1 47    0     FALSE      FALSE        0
#> 48           1 48    0     FALSE      FALSE        0
#> 49           1 49    0     FALSE      FALSE        0
#> 50           1 50    0     FALSE      FALSE        0
#> 51           1 51    0     FALSE      FALSE        0
#> 52           1 52    0     FALSE      FALSE        0
#> 53           1 53    0     FALSE      FALSE        0
#> 54           1 54    0     FALSE      FALSE        0
#> 55           1 55    0     FALSE      FALSE        0
#> 56           1 56    0     FALSE      FALSE        0
#> 57           1 57    0     FALSE      FALSE        0
#> 58           1 58    0     FALSE      FALSE        0
#> 59           1 59    0     FALSE      FALSE        0
#> 60           1 60    0     FALSE      FALSE        0
#> 61           1 61    0     FALSE      FALSE        0
#> 62           1 62    0     FALSE      FALSE        0
#> 63           1 63    0     FALSE      FALSE        0
#> 64           1 64    0     FALSE      FALSE        0
```
