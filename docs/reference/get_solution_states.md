# Get planning-unit states from stored solutions

Convert stored planning-unit/action decisions into one canonical action
state per planning unit and solution.

## Usage

``` r
get_solution_states(x)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Value

A `data.frame` with columns `solution_id`, `pu`, `selected`, `state`,
`managed`, and `n_actions`. `solution_id` is returned as an integer.

## Details

Selected action names are sorted and joined with `"+"`. Planning units
without a selected action receive the state `"unmanaged"`. The
`selected` column retains the planning-unit selection indicator when it
is available in the stored planning-unit summary.

## See also

[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`get_planning_units`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md),
[`selection_consistency`](https://josesalgr.github.io/multiscape/reference/selection_consistency.md),
[`linkage_transition`](https://josesalgr.github.io/multiscape/reference/linkage_transition.md)

## Examples

``` r
# Load a complete simulated multi-action problem.
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
    example_data$effect_assumptions
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(
    alias = "cost",
    include_pu_cost = FALSE
  ) |>
  add_objective_max_benefit(
    alias = "benefit"
  ) |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(n = 5),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(problem, verbose = FALSE)
  solutions <- solve(problem)

  states <- get_solution_states(solutions)
  head(states)

  # Inspect one solution from the returned table.
  solution_ids <- unique(states$solution_id)
  states[states$solution_id == solution_ids[1L], ]

  # Or filter the complete SolutionSet first.
  one_solution <- solution_filter(
    solutions,
    solution_id = solution_ids[1L]
  )
  get_solution_states(one_solution)
}
#>    solution_id pu selected     state managed n_actions
#> 1            1  1        0 unmanaged   FALSE         0
#> 2            1 10        0 unmanaged   FALSE         0
#> 3            1 11        0 unmanaged   FALSE         0
#> 4            1 12        0 unmanaged   FALSE         0
#> 5            1 13        0 unmanaged   FALSE         0
#> 6            1 14        0 unmanaged   FALSE         0
#> 7            1 15        0 unmanaged   FALSE         0
#> 8            1 16        0 unmanaged   FALSE         0
#> 9            1 17        0 unmanaged   FALSE         0
#> 10           1 18        0 unmanaged   FALSE         0
#> 11           1 19        0 unmanaged   FALSE         0
#> 12           1  2        0 unmanaged   FALSE         0
#> 13           1 20        0 unmanaged   FALSE         0
#> 14           1 21        0 unmanaged   FALSE         0
#> 15           1 22        0 unmanaged   FALSE         0
#> 16           1 23        0 unmanaged   FALSE         0
#> 17           1 24        0 unmanaged   FALSE         0
#> 18           1 25        0 unmanaged   FALSE         0
#> 19           1 26        0 unmanaged   FALSE         0
#> 20           1 27        0 unmanaged   FALSE         0
#> 21           1 28        0 unmanaged   FALSE         0
#> 22           1 29        0 unmanaged   FALSE         0
#> 23           1  3        0 unmanaged   FALSE         0
#> 24           1 30        0 unmanaged   FALSE         0
#> 25           1 31        0 unmanaged   FALSE         0
#> 26           1 32        0 unmanaged   FALSE         0
#> 27           1 33        1   protect    TRUE         1
#> 28           1 34        0 unmanaged   FALSE         0
#> 29           1 35        0 unmanaged   FALSE         0
#> 30           1 36        0 unmanaged   FALSE         0
#> 31           1 37        0 unmanaged   FALSE         0
#> 32           1 38        0 unmanaged   FALSE         0
#> 33           1 39        0 unmanaged   FALSE         0
#> 34           1  4        0 unmanaged   FALSE         0
#> 35           1 40        0 unmanaged   FALSE         0
#> 36           1 41        0 unmanaged   FALSE         0
#> 37           1 42        0 unmanaged   FALSE         0
#> 38           1 43        0 unmanaged   FALSE         0
#> 39           1 44        0 unmanaged   FALSE         0
#> 40           1 45        0 unmanaged   FALSE         0
#> 41           1 46        0 unmanaged   FALSE         0
#> 42           1 47        0 unmanaged   FALSE         0
#> 43           1 48        0 unmanaged   FALSE         0
#> 44           1 49        0 unmanaged   FALSE         0
#> 45           1  5        0 unmanaged   FALSE         0
#> 46           1 50        0 unmanaged   FALSE         0
#> 47           1 51        0 unmanaged   FALSE         0
#> 48           1 52        0 unmanaged   FALSE         0
#> 49           1 53        0 unmanaged   FALSE         0
#> 50           1 54        0 unmanaged   FALSE         0
#> 51           1 55        0 unmanaged   FALSE         0
#> 52           1 56        0 unmanaged   FALSE         0
#> 53           1 57        0 unmanaged   FALSE         0
#> 54           1 58        0 unmanaged   FALSE         0
#> 55           1 59        0 unmanaged   FALSE         0
#> 56           1  6        0 unmanaged   FALSE         0
#> 57           1 60        0 unmanaged   FALSE         0
#> 58           1 61        0 unmanaged   FALSE         0
#> 59           1 62        0 unmanaged   FALSE         0
#> 60           1 63        0 unmanaged   FALSE         0
#> 61           1 64        0 unmanaged   FALSE         0
#> 62           1  7        0 unmanaged   FALSE         0
#> 63           1  8        0 unmanaged   FALSE         0
#> 64           1  9        1   protect    TRUE         1
```
