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

- `solution_id`: solution id;

- `objective`: objective name;

- `sense`: optimization sense, either `"min"` or `"max"`;

- `bound`: observed bound, either `"min"` or `"max"`;

- `role`: interpretation of the bound, either `"best"` or `"worst"`;

- `value`: objective value at the observed bound.

## Details

Objective values are obtained from the stored run table. Objective
senses are obtained from the objective specifications stored in the
original problem.

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
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

problem <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
) |>
  add_actions(
    example_data$actions,
    cost = example_data$action_costs
  ) |>
  add_effects(
    example_data$effects,
    effect_type = "delta"
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
  add_objective_max_benefit(alias = "benefit") |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(n = 3),
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
#>   solution_id objective sense bound  role       value
#> 1           1      cost   min   min  best   2.1000000
#> 2           3      cost   min   max worst 101.2800000
#> 3           1   benefit   max   min worst   0.7616224
#> 4           3   benefit   max   max  best  29.7962175
```
