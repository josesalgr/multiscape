# Get raw decision vector from a solution set

Return the raw decision-variable vector for a selected run in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

The vector is returned in the internal model-variable order used by the
optimization backend.

## Usage

``` r
get_solution_vector(x, run = NULL, solution_id = NULL)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- run:

  Optional positive integer giving the run id to extract. If `NULL`, the
  first stored solution is used unless `solution_id` is supplied.

- solution_id:

  Optional character string giving the solution id to extract. If
  supplied, `run` must be `NULL`.

## Value

A numeric vector with one value per internal model variable.

## Details

This function extracts the raw decision vector for one run. The returned
vector is in the internal variable order of the optimization model.
Depending on the problem formulation, it may include:

- planning-unit selection variables;

- action-allocation variables;

- auxiliary variables introduced for targets, budgets, fragmentation, or
  other constraints/objectives;

- and potentially additional blocks created internally by the model
  builder.

Therefore, this vector is primarily intended for advanced users,
debugging, diagnostics, or internal verification. It is not a
user-facing allocation table.

To inspect selected planning units or selected actions in a more
interpretable form, use
[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md)
or
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md)
instead.

## See also

[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md),
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`get_features`](https://josesalgr.github.io/multiscape/reference/get_features.md),
[`get_targets`](https://josesalgr.github.io/multiscape/reference/get_targets.md)

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

  # Extract the first stored raw solution vector
  vector <- get_solution_vector(solutions)
  vector
  length(vector)

  # Extract a vector using its solution_id
  runs <- get_runs(solutions)
  solution_ids <- runs$solution_id[
    !is.na(runs$solution_id)
  ]

  if (length(solution_ids) > 0L) {
    get_solution_vector(
      solutions,
      solution_id = solution_ids[1]
    )
  }
}
#>  [1] 1 0 0 0 1 0 0 0 0 0 0 0 0
```
