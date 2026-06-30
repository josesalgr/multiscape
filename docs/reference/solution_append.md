# Append solutions from another solution set

Append the runs and stored solutions from one
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object to another.

This function combines two `SolutionSet` objects generated from the same
planning problem. It is intended for combining results obtained with
different multiscape solving workflows, such as weighted-sum,
epsilon-constraint, or AUGMECON methods, while keeping a single coherent
result object for downstream extraction, plotting, and analysis.

## Usage

``` r
solution_append(x, y)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- y:

  A second
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)
  and generated from the same planning problem as `x`.

## Value

A new
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object containing the runs and stored solutions from both input objects.

## Details

`solution_append()` is a solution-set management function. It does not
modify the original input objects. Instead, it returns a new
`SolutionSet` containing the runs and solutions from both inputs.

Both input objects must be generated from the same planning problem.
This is checked conservatively before appending. In particular, the two
objects must have compatible:

- planning units;

- features and feature distributions;

- actions, feasible action pairs, and effects;

- profit data, when present;

- targets;

- locks and constraints;

- spatial relations;

- objective specifications.

Differences in method settings, run design, solver settings, solver
status, runtime, gaps, and other solve diagnostics are allowed.

The appended runs and solutions are assigned new `run_id` and
`solution_id` values to keep identifiers unique in the combined object.
Identifiers are not required to match between the two inputs.

This function is not intended to combine results from different planning
problems, scenarios, target sets, or objective definitions. Such
workflows should be handled by a future comparison/binding function
rather than by `solution_append()`.

## See also

[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md),
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`plot_tradeoff`](https://josesalgr.github.io/multiscape/reference/plot_tradeoff.md)

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

make_problem <- function() {
  create_problem(
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
    add_objective_max_benefit(alias = "benefit")
}

weighted_problem <- make_problem() |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(
      n = 4
    ),
    normalize_weights = TRUE
  )

epsilon_problem <- make_problem() |>
  set_method_epsilon_constraint(
    primary = "cost",
    runs = set_runs_grid(
      n = 4
    )
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  weighted_problem <- set_solver_cbc(
    weighted_problem,
    verbose = FALSE
  )

  epsilon_problem <- set_solver_cbc(
    epsilon_problem,
    verbose = FALSE
  )

  weighted_solutions <- solve(weighted_problem)
  epsilon_solutions <- solve(epsilon_problem)

  combined_solutions <- solution_append(
    weighted_solutions,
    epsilon_solutions
  )

  # Inspect the combined run history
  get_runs(combined_solutions)

  # Inspect objective values from both methods
  get_objectives(
    combined_solutions,
    format = "wide"
  )

  # The original objects remain unchanged
  get_runs(weighted_solutions)
  get_runs(epsilon_solutions)
}
#>   run_id solution_id  status runtime gap
#> 1      1           1 optimal    0.00   0
#> 2      2           2 optimal    0.02   0
#> 3      3           3 optimal    0.00   0
#> 4      4           4 optimal    0.01   0
```
