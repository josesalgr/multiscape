# Get planning-unit results from a solution set

**\[deprecated\]**

`get_pu()` has been replaced by
[`get_planning_units`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md).

## Usage

``` r
get_pu(x, solution = NULL, ...)
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

A `data.frame` containing the stored planning-unit summary.
