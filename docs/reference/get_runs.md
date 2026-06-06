# Get run-level results from a solution set

Extract the run-level summary table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Usage

``` r
get_runs(x, feasible_only = FALSE)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object.

- feasible_only:

  Logical. If `TRUE`, return only runs with solver status interpreted as
  feasible or successful.

## Value

A `data.frame` with one row per run.
