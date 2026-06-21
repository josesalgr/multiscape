# Filter solutions in a solution set

Return a reduced
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object containing only the runs or solutions that match the requested
filters.

This function is intended to curate `SolutionSet` objects before
downstream analysis, plotting, frontier analysis, or post-hoc
evaluation. It filters all relevant components of the object
consistently, including the run table, design table, stored run-level
solutions, and available summary tables.

## Usage

``` r
solution_filter(
  x,
  run_id = NULL,
  solution_id = NULL,
  status = NULL,
  feasible_only = FALSE,
  nondominated = FALSE,
  objectives = NULL
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- run_id:

  Optional integer vector of run ids to keep.

- solution_id:

  Optional character vector of solution ids to keep. Runs without a
  stored solution are never matched by this filter.

- status:

  Optional character vector of run statuses to keep. Matching is
  case-insensitive.

- feasible_only:

  Logical. If `TRUE`, keep only runs whose status is interpreted as
  having produced a usable solution. The current accepted statuses are
  `"optimal"`, `"feasible"`, `"suboptimal"`, `"time_limit"`, and
  `"gap_limit"`.

- nondominated:

  Logical. If `TRUE`, keep only non-dominated solutions among the runs
  retained by the other filters. This uses moocore internally.

- objectives:

  Optional character vector of objective names to use when
  `nondominated = TRUE`. If `NULL`, all available objective-value
  columns are used.

## Value

A filtered
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Details

A `SolutionSet` distinguishes between runs and stored solutions.

- `run_id` identifies a run or attempted solve. Runs may be feasible,
  optimal, infeasible, failed, or otherwise incomplete.

- `solution_id` identifies a stored solution. Runs that did not produce
  a solution have `solution_id = NA`.

Therefore, filtering by `run_id` and filtering by `solution_id` are not
always equivalent. For example, an infeasible run may have a `run_id`
but no `solution_id`.

The function filters:

- `x$solution$runs`, using the selected `run_id`s;

- `x$solution$design`, when it contains a `run_id` column;

- `x$solution$solutions`, using the selected `solution_id`s;

- all tables in `x$summary` that contain a `run_id` column.

The function does not renumber `run_id` or `solution_id`. This preserves
traceability to the original run design.

If more than one filter is supplied, filters are combined using logical
*and*. For example, setting both `status = "optimal"` and
`solution_id = c("s1", "s3")` keeps only optimal runs whose
`solution_id` is either `"s1"` or `"s3"`.

If `nondominated = TRUE`, the function further keeps only non-dominated
solutions among the runs retained by the previous filters. Dominance is
evaluated in objective space using the objective values stored in the
run table. Objective senses are read from `get_objective_specs`; any
maximization objective is internally multiplied by \\-1\\ so that
dominance can be evaluated in minimization space.

Non-dominated filtering requires the moocore package.

## See also

[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md),
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`get_planning_units`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md),
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md)

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
  runs <- get_runs(solutions)

  # Keep only runs with a usable solver status
  feasible_solutions <- solution_filter(
    solutions,
    feasible_only = TRUE
  )

  # Keep selected runs
  selected_runs <- solution_filter(
    solutions,
    run_id = runs$run_id[1:2]
  )

  # Keep one stored solution
  solution_ids <- runs$solution_id[
    !is.na(runs$solution_id)
  ]

  if (length(solution_ids) > 0L) {
    selected_solution <- solution_filter(
      solutions,
      solution_id = solution_ids[1]
    )
  }

  # Keep only optimal runs
  if ("optimal" %in% tolower(runs$status)) {
    optimal_solutions <- solution_filter(
      solutions,
      status = "optimal"
    )
  }

  # Keep only non-dominated solutions
  if (requireNamespace("moocore", quietly = TRUE)) {
    nondominated_solutions <- solution_filter(
      solutions,
      feasible_only = TRUE,
      nondominated = TRUE
    )

    # Evaluate dominance using selected objectives
    nondominated_subset <- solution_filter(
      solutions,
      feasible_only = TRUE,
      nondominated = TRUE,
      objectives = c("cost", "benefit")
    )
  }
}
```
