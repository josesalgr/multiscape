# Control multi-objective run behavior

Create a control object that determines how multi-objective workflows
respond to infeasible runs, missing solution vectors, and unexpected
errors.

The resulting object is supplied to the `control` argument of
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md)
or
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md).

## Usage

``` r
set_runs_control(
  stop_on_infeasible = FALSE,
  stop_on_no_solution = FALSE,
  stop_on_error = TRUE
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

## Value

An object of class `RunsControl` and `MOControl` containing the
validated execution-control settings. The object is intended to be
supplied to the `control` argument of a supported multi-objective
method.

## Details

Multi-objective methods commonly solve a sequence of related
optimization models. Some parameter combinations, particularly
restrictive epsilon levels, may be infeasible or may fail to produce a
usable solution.

`set_runs_control()` determines whether such events stop the entire
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

The default settings favour completing the requested run design while
still stopping on unexpected errors:


    stop_on_infeasible = FALSE
    stop_on_no_solution = FALSE
    stop_on_error = TRUE

## See also

[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md),
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)

## Examples

``` r
# Default behaviour: continue after infeasible runs or runs without a
# solution, but stop on unexpected errors
control <- set_runs_control()
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       

# Stop as soon as an infeasible run or missing solution is encountered
strict_control <- set_runs_control(
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
```
