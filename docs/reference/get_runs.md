# Get run-level metadata from a solution set

Extract the run table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Usage

``` r
get_runs(x)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Value

A `data.frame` with one row per attempted optimization run. The table
contains run metadata and the numeric mapping between `run_id` and
`solution_id`, but not objective-value columns.

## Details

A run represents an attempted optimization solve. Each run has a unique
`run_id`. Only runs that produce a stored solution receive a
`solution_id`.

The `solution_id` is numeric and matches the corresponding `run_id`.
Therefore, if a run fails or is infeasible, its `solution_id` is `NA`;
if a later run succeeds, its `solution_id` keeps the same value as its
`run_id`.

This function is the user-facing place where the relationship between
attempted runs and stored solutions is reported.

Objective values are not returned by `get_runs()`. To extract objective
values, use
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md).

## See also

[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md),
[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md),
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)

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

problem <- create_problem(
  pu = pu,
  features = features,
  dist_features = dist_features,
  cost = "cost"
) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost")

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  get_runs(solutions)
}
#>   run_id solution_id  status runtime gap objective
#> 1      1           1 optimal       0   0         1
```
