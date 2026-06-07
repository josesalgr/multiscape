# Get objective specifications from a solution set

Extract the definitions of the objectives registered in the original
planning problem associated with a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

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

A `data.frame` with one row per registered objective and the columns:

- `objective`: user-defined objective alias;

- `objective_id`: internal objective type;

- `model_type`: internal model formulation;

- `sense`: optimization direction, `"min"` or `"max"`;

- `created_at`: objective registration timestamp.

## Details

Objective specifications are read from `x$problem$data$objectives`. They
describe how each objective was registered, independently of the
multi-objective method later used to solve the problem.

The returned optimization sense is used by frontier and dominance
functions to place objectives in a common minimization space.

## See also

[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`frontier_extremes`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md),
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
    runs = run_grid(
      n = 5,
      include_extremes = TRUE
    ),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  get_objective_specs(solutions)
}
#>   objective objective_id       model_type sense                 created_at
#> 1   benefit  max_benefit maximizeBenefits   max 2026-06-07 14:41:06.546347
#> 2      cost     min_cost    minimizeCosts   min 2026-06-07 14:41:06.545646
```
