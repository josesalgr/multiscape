# Get objective specifications from a solution set

Extract objective aliases, model types, objective ids, optimization
senses, and objective arguments from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

Objective specifications are read from the original `Problem` object
stored in the `SolutionSet`.

## Usage

``` r
get_objective_specs(x)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Value

A `data.frame` with one row per registered objective.
