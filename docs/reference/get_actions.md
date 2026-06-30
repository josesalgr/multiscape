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
  add_objective_min_cost(alias = "cost")

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
#>   solution_id pu       action cost status selected
#> 1           1  1 conservation    1      0        1
#> 2           1  1  restoration    2      0        0
#> 3           1  2 conservation    1      0        0
#> 4           1  2  restoration    2      0        0
#> 5           1  3 conservation    1      0        0
#> 6           1  3  restoration    2      0        0
#> 7           1  4 conservation    1      0        0
#> 8           1  4  restoration    2      0        0
```
