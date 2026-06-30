# Control multi-objective run behavior

**\[deprecated\]**

`mo_control()` has been replaced by
[`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md).

The argument `slack_upper_bound` is deprecated and ignored. For
AUGMECON, use the `slack_upper_bound` argument directly in
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md).

## Usage

``` r
mo_control(
  stop_on_infeasible = FALSE,
  stop_on_no_solution = FALSE,
  stop_on_error = TRUE,
  slack_upper_bound = NULL
)
```

## Arguments

- stop_on_infeasible:

  Logical. If `TRUE`, stop the complete multi-objective workflow when a
  run is reported as infeasible.

- stop_on_no_solution:

  Logical. If `TRUE`, stop when a run does not return a usable solution
  vector.

- stop_on_error:

  Logical. If `TRUE`, stop on unexpected errors.

- slack_upper_bound:

  Deprecated. Use `slack_upper_bound` in
  [`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)
  instead.

## Value

An object of class `RunsControl`, `MOControl`, and `list`.

## See also

[`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)
