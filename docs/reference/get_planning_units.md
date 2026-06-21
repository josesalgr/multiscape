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

problem <- create_problem(
  pu = pu,
  features = features,
  dist_features = dist_features,
  cost = "cost"
) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost")

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
#>   solution_id id cost locked_in locked_out internal_id selected
#> 1           1  1    1     FALSE      FALSE           1        1
#> 2           1  2    2     FALSE      FALSE           2        0
#> 3           1  3    3     FALSE      FALSE           3        0
#> 4           1  4    4     FALSE      FALSE           4        0
```
