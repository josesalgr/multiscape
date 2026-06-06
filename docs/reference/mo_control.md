# Control multi-objective method behavior

Create a control object for multi-objective methods.

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

  Logical. If TRUE, stop when a run is infeasible. If FALSE, keep the
  run in the SolutionSet with missing objective values.

- stop_on_no_solution:

  Logical. If TRUE, stop when the solver does not return a solution
  vector. If FALSE, keep the run in the SolutionSet with missing
  objective values.

- stop_on_error:

  Logical. If TRUE, stop on unexpected solver errors.

- slack_upper_bound:

  Positive numeric value used as upper bound for AUGMECON slack
  variables.

## Value

An object of class `MOControl`.
