# Control multi-objective method behavior

Create a control object that determines how multi-objective workflows
respond to infeasible runs, missing solution vectors, unexpected errors,
and AUGMECON slack-variable bounds.

The resulting object is supplied to the `control` argument of
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md)
or
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md).

## Usage

``` r
mo_control(
  stop_on_infeasible = FALSE,
  stop_on_no_solution = FALSE,
  stop_on_error = TRUE,
  slack_upper_bound = 1e+06
)
```

## Arguments

- stop_on_infeasible:

  Logical. If `TRUE`, stop the complete multi-objective workflow when a
  run is reported as infeasible. If `FALSE`, retain the attempted run in
  the run table and continue with the remaining runs. Defaults to
  `FALSE`.

- stop_on_no_solution:

  Logical. If `TRUE`, stop when a run does not return a usable solution
  vector. If `FALSE`, retain the attempted run without a stored
  `solution_id` and continue. Defaults to `FALSE`.

- stop_on_error:

  Logical. If `TRUE`, stop on unexpected errors raised during model
  preparation, solving, or result processing. If `FALSE`, attempt to
  record the failed run and continue. Defaults to `TRUE`.

- slack_upper_bound:

  A single positive finite numeric value defining the upper bound of
  AUGMECON slack variables. This setting is ignored by other
  multi-objective methods. Defaults to `1e6`.

## Value

An object of class `MOControl` containing the validated
execution-control settings. The object is intended to be supplied to the
`control` argument of a supported multi-objective method.

## Details

Multi-objective methods commonly solve a sequence of related
optimization models. Some parameter combinations, particularly
restrictive epsilon levels, may be infeasible or may fail to produce a
usable solution.

`mo_control()` determines whether such events stop the entire
multi-objective workflow or are recorded in the resulting
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

A `SolutionSet` distinguishes between:

- a `run_id`, which identifies every attempted optimization run;

- a `solution_id`, which is assigned only when a run produces a stored
  solution.

When a run is retained after an infeasibility or missing-solution event,
its run-level metadata remains available through
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
but its `solution_id` and objective values will generally be missing.

**Infeasible runs**

If `stop_on_infeasible = FALSE`, an infeasible run is recorded and the
workflow continues with the remaining run design. This is generally
useful when exploring automatically generated epsilon grids because
restrictive combinations of epsilon levels may be infeasible.

If `stop_on_infeasible = TRUE`, the workflow stops when the first
infeasible run is encountered.

**Runs without a solution vector**

A solver may terminate without returning a usable decision vector even
when the outcome is not classified explicitly as infeasible.

If `stop_on_no_solution = FALSE`, the attempted run is recorded without
a stored solution and the remaining runs are attempted. If
`stop_on_no_solution = TRUE`, the workflow stops immediately.

**Unexpected errors**

If `stop_on_error = TRUE`, unexpected errors raised while preparing,
solving, or processing a run are propagated and stop the workflow. This
is the recommended default because such errors may indicate an invalid
model, unsupported solver behaviour, or an internal implementation
problem.

If `stop_on_error = FALSE`, the workflow attempts to record the failed
run and continue. This option should be used cautiously because it may
conceal modelling or implementation errors.

**AUGMECON slack upper bound**

`slack_upper_bound` defines an explicit upper bound for slack variables
introduced by the AUGMECON formulation. It is used only by
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)
and has no effect on weighted-sum or standard epsilon-constraint
workflows.

The value should be sufficiently large to avoid excluding valid
solutions, but unnecessarily large bounds can weaken the mixed-integer
formulation and reduce numerical performance. When possible, a
problem-specific bound based on the ranges of the constrained objectives
should be used.

The default settings favour completing the requested run design while
still stopping on unexpected errors:


    stop_on_infeasible = FALSE
    stop_on_no_solution = FALSE
    stop_on_error = TRUE
    slack_upper_bound = 1e6

## See also

[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md),
[`run_manual`](https://josesalgr.github.io/multiscape/reference/run_manual.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)

## Examples

``` r
# Default behaviour: continue after infeasible runs or runs without a
# solution, but stop on unexpected errors
control <- mo_control()
control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     

# Stop as soon as an infeasible run or missing solution is encountered
strict_control <- mo_control(
  stop_on_infeasible = TRUE,
  stop_on_no_solution = TRUE
)

strict_control
#> $stop_on_infeasible
#> [1] TRUE
#> 
#> $stop_on_no_solution
#> [1] TRUE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     

# Define a problem with explicit conservation and restoration actions
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
  set_method_epsilon_constraint(
    primary = "cost",
    runs = run_grid(
      n = 5,
      include_extremes = TRUE
    ),
    control = mo_control(
      stop_on_infeasible = FALSE,
      stop_on_no_solution = FALSE,
      stop_on_error = TRUE
    )
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # All attempted runs, including runs without stored solutions
  get_runs(solutions)

  # Only runs with a usable solver status
  get_runs(
    solutions,
    feasible_only = TRUE
  )
}
#>   run_id solution_id  status runtime gap message value_benefit value_cost
#> 1      1          s1 optimal    0.00   0                   0.0          2
#> 2      2          s2 optimal    0.00   0                   3.5          3
#> 3      3          s3 optimal    0.02   0                   5.0          7
#> 4      4          s4 optimal    0.00   0                   7.0         12
#> 5      5          s5 optimal    0.00   0                   7.5         18
```
