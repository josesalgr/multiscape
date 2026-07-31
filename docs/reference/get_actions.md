# Get action results from a solution set

Extract the action-allocation summary table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

The returned table summarizes solution values at the planning
unit–action level and typically includes a `selected` indicator showing
whether each feasible `(pu, action)` pair is selected in a solution.

## Usage

``` r
get_actions(x, solution = NULL, ...)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- solution:

  Optional positive integer giving the solution index to extract. If
  `NULL`, all runs are returned when available.

- ...:

  Deprecated arguments kept for backwards compatibility. Currently
  supports `run` and `solution_id`, which are redirected to `solution`.

## Value

A `data.frame` containing the stored action-allocation summary. Typical
columns include planning-unit ids, action ids, optional labels, and a
`selected` indicator.

## Details

This function reads the action summary stored in `x$summary$actions`. It
does not reconstruct the table from the raw decision vector; it simply
returns the stored summary after optional run filtering.

Let \\x\_{ia}\\ denote the decision variable associated with selecting
action \\a\\ in planning unit \\i\\. In standard multiscape workflows,
the `selected` column is the user-facing representation of that
decision, typically coded as `0` or `1`.

If `solution` is provided, only rows belonging to that solution are
returned. This requires the summary table to contain a `solution_id`
column.

To return only selected action allocations, filter the returned table
using `selected == 1`.

## See also

[`get_planning_units`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md),
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

  # All feasible planning-unit/action assignments
  get_actions(solutions)

  # Only selected action assignments
  selected_actions <- get_actions(solutions)
  selected_actions <- selected_actions[
    selected_actions$selected == 1L,
    ,
    drop = FALSE
  ]
  selected_actions

  # Action allocations for one solution
  solution_ids <- get_runs(solutions)$solution_id

  get_actions(
    solutions,
    solution = solution_ids[1]
  )
}
#>     solution_id pu  action cost status action_area selected
#> 1             1  1 protect 1.05      0           1        0
#> 2             1  1 restore 2.30      0           1        0
#> 3             1  2 protect 1.15      0           1        0
#> 4             1  2 restore 2.18      0           1        0
#> 5             1  3 protect 1.25      0           1        0
#> 6             1  3 restore 2.06      0           1        0
#> 7             1  4 protect 1.35      0           1        0
#> 8             1  4 restore 1.94      0           1        0
#> 9             1  5 protect 1.45      0           1        0
#> 10            1  5 restore 1.82      0           1        0
#> 11            1  6 protect 1.55      0           1        0
#> 12            1  6 restore 1.70      0           1        0
#> 13            1  7 protect 1.65      0           1        0
#> 14            1  7 restore 1.58      0           1        0
#> 15            1  8 protect 1.75      0           1        0
#> 16            1  8 restore 1.46      0           1        0
#> 17            1  9 protect 1.05      0           1        1
#> 18            1  9 restore 2.30      0           1        0
#> 19            1 10 protect 1.15      0           1        0
#> 20            1 10 restore 2.18      0           1        0
#> 21            1 11 protect 1.25      0           1        0
#> 22            1 11 restore 2.06      0           1        0
#> 23            1 12 protect 1.35      0           1        0
#> 24            1 12 restore 1.94      0           1        0
#> 25            1 13 protect 1.45      0           1        0
#> 26            1 13 restore 1.82      0           1        0
#> 27            1 14 protect 1.55      0           1        0
#> 28            1 14 restore 1.70      0           1        0
#> 29            1 15 protect 1.65      0           1        0
#> 30            1 15 restore 1.58      0           1        0
#> 31            1 16 protect 1.75      0           1        0
#> 32            1 16 restore 1.46      0           1        0
#> 33            1 17 protect 1.05      0           1        0
#> 34            1 17 restore 2.30      0           1        0
#> 35            1 18 protect 1.15      0           1        0
#> 36            1 18 restore 2.18      0           1        0
#> 37            1 19 protect 1.25      0           1        0
#> 38            1 19 restore 2.06      0           1        0
#> 39            1 20 protect 1.35      0           1        0
#> 40            1 20 restore 1.94      0           1        0
#> 41            1 21 protect 1.45      0           1        0
#> 42            1 21 restore 1.82      0           1        0
#> 43            1 22 protect 1.55      0           1        0
#> 44            1 22 restore 1.70      0           1        0
#> 45            1 23 protect 1.65      0           1        0
#> 46            1 23 restore 1.58      0           1        0
#> 47            1 24 protect 1.75      0           1        0
#> 48            1 24 restore 1.46      0           1        0
#> 49            1 25 protect 1.05      0           1        0
#> 50            1 25 restore 2.30      0           1        0
#> 51            1 26 protect 1.15      0           1        0
#> 52            1 26 restore 2.18      0           1        0
#> 53            1 27 protect 1.25      0           1        0
#> 54            1 27 restore 2.06      0           1        0
#> 55            1 28 protect 1.35      0           1        0
#> 56            1 28 restore 1.94      0           1        0
#> 57            1 29 protect 1.45      0           1        0
#> 58            1 29 restore 1.82      0           1        0
#> 59            1 30 protect 1.55      0           1        0
#> 60            1 30 restore 1.70      0           1        0
#> 61            1 31 protect 1.65      0           1        0
#> 62            1 31 restore 1.58      0           1        0
#> 63            1 32 protect 1.75      0           1        0
#> 64            1 32 restore 1.46      0           1        0
#> 65            1 33 protect 1.05      0           1        1
#> 66            1 33 restore 2.30      0           1        0
#> 67            1 34 protect 1.15      0           1        0
#> 68            1 34 restore 2.18      0           1        0
#> 69            1 35 protect 1.25      0           1        0
#> 70            1 35 restore 2.06      0           1        0
#> 71            1 36 protect 1.35      0           1        0
#> 72            1 36 restore 1.94      0           1        0
#> 73            1 37 protect 1.45      0           1        0
#> 74            1 37 restore 1.82      0           1        0
#> 75            1 38 protect 1.55      0           1        0
#> 76            1 38 restore 1.70      0           1        0
#> 77            1 39 protect 1.65      0           1        0
#> 78            1 39 restore 1.58      0           1        0
#> 79            1 40 protect 1.75      0           1        0
#> 80            1 40 restore 1.46      0           1        0
#> 81            1 41 protect 1.05      0           1        0
#> 82            1 41 restore 2.30      0           1        0
#> 83            1 42 protect 1.15      0           1        0
#> 84            1 42 restore 2.18      0           1        0
#> 85            1 43 protect 1.25      0           1        0
#> 86            1 43 restore 2.06      0           1        0
#> 87            1 44 protect 1.35      0           1        0
#> 88            1 44 restore 1.94      0           1        0
#> 89            1 45 protect 1.45      0           1        0
#> 90            1 45 restore 1.82      0           1        0
#> 91            1 46 protect 1.55      0           1        0
#> 92            1 46 restore 1.70      0           1        0
#> 93            1 47 protect 1.65      0           1        0
#> 94            1 47 restore 1.58      0           1        0
#> 95            1 48 protect 1.75      0           1        0
#> 96            1 48 restore 1.46      0           1        0
#> 97            1 49 protect 1.05      0           1        0
#> 98            1 49 restore 2.30      0           1        0
#> 99            1 50 protect 1.15      0           1        0
#> 100           1 50 restore 2.18      0           1        0
#> 101           1 51 protect 1.25      0           1        0
#> 102           1 51 restore 2.06      0           1        0
#> 103           1 52 protect 1.35      0           1        0
#> 104           1 52 restore 1.94      0           1        0
#> 105           1 53 protect 1.45      0           1        0
#> 106           1 53 restore 1.82      0           1        0
#> 107           1 54 protect 1.55      0           1        0
#> 108           1 54 restore 1.70      0           1        0
#> 109           1 55 protect 1.65      0           1        0
#> 110           1 55 restore 1.58      0           1        0
#> 111           1 56 protect 1.75      0           1        0
#> 112           1 56 restore 1.46      0           1        0
#> 113           1 57 protect 1.05      0           1        0
#> 114           1 57 restore 2.30      0           1        0
#> 115           1 58 protect 1.15      0           1        0
#> 116           1 58 restore 2.18      0           1        0
#> 117           1 59 protect 1.25      0           1        0
#> 118           1 59 restore 2.06      0           1        0
#> 119           1 60 protect 1.35      0           1        0
#> 120           1 60 restore 1.94      0           1        0
#> 121           1 61 protect 1.45      0           1        0
#> 122           1 61 restore 1.82      0           1        0
#> 123           1 62 protect 1.55      0           1        0
#> 124           1 62 restore 1.70      0           1        0
#> 125           1 63 protect 1.65      0           1        0
#> 126           1 63 restore 1.58      0           1        0
#> 127           1 64 protect 1.75      0           1        0
#> 128           1 64 restore 1.46      0           1        0
```
