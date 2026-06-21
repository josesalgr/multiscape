# Find objective-wise extreme solutions

Identify the observed minimum and maximum values for each objective in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

This function returns the solutions that define the observed range of
each selected objective. It also labels each extreme as `"best"` or
`"worst"` according to the registered optimization sense of the
objective.

## Usage

``` r
frontier_extremes(x, objectives = NULL, ties = c("all", "first"))
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- objectives:

  Optional character vector of objective names to inspect. If `NULL`,
  all available objective-value columns are used.

- ties:

  Character. How to handle ties. If `"all"`, all tied solutions are
  returned. If `"first"`, only the first tied solution is returned.

## Value

A `data.frame` with one or more rows per objective. The returned columns
are:

- `objective`: objective name;

- `sense`: optimization sense, either `"min"` or `"max"`;

- `bound`: observed bound, either `"min"` or `"max"`;

- `role`: interpretation of the bound, either `"best"` or `"worst"`;

- `run_id`: run id of the solution;

- `solution_id`: solution id;

- `value`: objective value at the observed bound.

## Details

Objective values are obtained from
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md)
with `format = "wide"`. Objective senses are obtained from
`get_objective_specs`.

For objectives with `sense = "min"`, the observed minimum is labelled as
`"best"` and the observed maximum is labelled as `"worst"`. For
objectives with `sense = "max"`, the observed maximum is labelled as
`"best"` and the observed minimum is labelled as `"worst"`.

Runs without a stored `solution_id` or with missing objective values for
the selected objectives are ignored automatically. Therefore, infeasible
runs are not considered in the computation.

If several solutions have the same extreme value for an objective, the
behaviour is controlled by `ties`.

## See also

[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
`get_objective_specs`,
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)

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

actions <- data.frame(
  id = c("conservation", "restoration")
)

effects <- data.frame(
  action = rep(actions$id, each = 2),
  feature = rep(features$id, times = 2),
  multiplier = c(
    1.0, 1.0,
    1.5, 1.5
  )
)

problem <- create_problem(
  pu = pu,
  features = features,
  dist_features = dist_features,
  cost = "cost"
) |>
  add_actions(
    actions = actions,
    cost = c(
      conservation = 1,
      restoration = 2
    )
  ) |>
  add_effects(
    effects = effects,
    effect_type = "after"
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_max_benefit(alias = "benefit") |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(
      n = 5
    ),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # Observed minimum and maximum for every objective
  frontier_extremes(solutions)

  # Inspect only selected objectives
  frontier_extremes(
    solutions,
    objectives = c("cost", "benefit")
  )

  # Keep only the first solution when several solutions share an extreme
  frontier_extremes(
    solutions,
    ties = "first"
  )
}
#>   objective sense bound  role run_id solution_id value
#> 1      cost   min   min  best      1           1   2.0
#> 2      cost   min   max worst      5           5  18.0
#> 3   benefit   max   min worst      1           1   0.0
#> 4   benefit   max   max  best      5           5   7.5
```
