# Get target achievement summary from a solution set

Extract a user-facing target-achievement table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

The returned table summarizes, for each stored target, the target level,
the achieved value, the gap between achieved and required values, and
whether the target was met in each run.

## Usage

``` r
get_targets(x, solution = NULL, ...)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- solution:

  Optional positive integer giving the solution index to extract. If
  `NULL`, all runs are returned when available.

## Value

A simplified `data.frame` target summary, or `NULL` if the result does
not contain targets. Typical columns include `feature`, `feature_name`,
`target_level`, `total_available`, `target`, `achieved`, `gap`, and
`met`.

## Details

Targets are optional in multiscape. If the result object does not
contain a targets summary table at `x$summary$targets`, this function
returns `NULL` without error.

This function reads the stored targets summary and returns a simplified
user-facing table. If the summary contains `achieved` and
`target_value`, target satisfaction is evaluated as follows.

For lower-bound targets: \$\$ \mathrm{met} = (\mathrm{achieved} \ge
\mathrm{target}), \$\$

and for upper-bound targets: \$\$ \mathrm{met} = (\mathrm{achieved} \le
\mathrm{target}). \$\$

The interpretation of the target direction is taken from the `sense`
column when available:

- `"ge"`, `">="`, or `"min"` are treated as lower-bound targets;

- `"le"`, `"<="`, or `"max"` are treated as upper-bound targets;

- if `sense` is missing, the target is treated as a lower bound by
  default.

The returned table is simplified and renames some internal fields for
readability:

- `target_raw` is returned as `target_level`;

- `basis_total` is returned as `total_available`;

- `target_value` is returned as `target`.

If `solution` is provided, only rows belonging to that solution are
returned. If the result contains a `run_id` column but only a single
solution is present and `solution` was not requested explicitly, the
`solution_id` column is removed for convenience.

The `gap` column is expected to be part of the stored summary. When
present, it typically represents: \$\$ \mathrm{gap} =
\mathrm{achieved} - \mathrm{target}. \$\$

## See also

[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md),
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`get_features`](https://josesalgr.github.io/multiscape/reference/get_features.md)

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

  # Target requirements and achieved amounts
  get_targets(solutions)

  # Target achievement for one run
  solution_ids <- get_runs(solutions)$solution_id

  get_targets(
    solutions,
    solution = solution_ids[1]
  )
}
#>   run_id feature feature_name target_level total_available target achieved  gap
#> 1      1       1          sp1         0.05               9   0.45        5 4.55
#> 2      1       2          sp2         0.05               6   0.30        2 1.70
#>    met
#> 1 TRUE
#> 2 TRUE
```
