# Get objective values from a solution set

Extract objective values from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

Objective values are read from run-table columns named
`value_<objective>`, where `<objective>` is the objective alias.

## Usage

``` r
get_objectives(x, format = c("long", "wide"), feasible_only = FALSE)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- format:

  Character. Either `"long"` or `"wide"`.

- feasible_only:

  Logical. If `TRUE`, use only feasible runs.

## Value

If `format = "long"`, a `data.frame` with columns `run_id`,
`solution_id`, `objective`, and `value`.

If `format = "wide"`, a `data.frame` with one row per run, columns
`run_id` and `solution_id`, and one column per objective.
