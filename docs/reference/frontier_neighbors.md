# Identify neighboring solutions in objective space

Connect nearby stored solutions in normalized objective space. The
resulting pairs can be supplied directly to objective–decision linkage
functions.

## Usage

``` r
frontier_neighbors(
  x,
  objectives = NULL,
  method = c("auto", "sequence", "mst", "knn"),
  metric = c("euclidean", "manhattan", "chebyshev"),
  k = 1L
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- objectives:

  Optional character vector of objective aliases. If `NULL`, all
  registered objectives are used.

- method:

  Neighborhood method: `"auto"`, `"sequence"`, `"mst"`, or `"knn"`.

- metric:

  Objective-space distance metric: `"euclidean"`, `"manhattan"`, or
  `"chebyshev"`.

- k:

  Number of nearest neighbors used only by `method = "knn"`.

  The first selected objective orients all pairs and, for
  `method = "sequence"`, also orders the solutions. Supply the desired
  ordering objective first in `objectives`.

## Value

A `data.frame` with `from_solution`, `to_solution`,
`objective_distance`, and objective-specific values and changes.
Analysis settings are retained as attributes.

## Details

Objective values are oriented to minimization and normalized using the
solutions retained in the supplied `SolutionSet`. The function does not
remove dominated or repeated solutions; use
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
or
[`solution_unique`](https://josesalgr.github.io/multiscape/reference/solution_unique.md)
beforehand when required.

`method = "auto"` uses a sequence for one or two objectives and a
minimum spanning tree for higher-dimensional objective spaces.

## See also

[`frontier_distances`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md),
[`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
[`linkage_turnover`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md)

## Examples

``` r
# Load a complete simulated multi-action problem.
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
    example_data$effect_assumptions
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(
    alias = "cost",
    include_pu_cost = FALSE
  ) |>
  add_objective_max_effect(
    alias = "benefit"
  ) |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(n = 5),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(problem, verbose = FALSE)
  solutions <- solve(problem)

  neighbors <- frontier_neighbors(
    solutions,
    objectives = c("benefit", "cost")
  )

  neighbors

  frontier_neighbors(
    solutions,
    objectives = c("cost", "benefit"),
    method = "knn",
    k = 2
  )
}
#>   from_solution to_solution objective_distance from_cost to_cost delta_cost
#> 1             2           1         0.01899231      2.20    2.10      -0.10
#> 2             3           1         0.05327404      2.73    2.10      -0.63
#> 3             3           2         0.03434672      2.73    2.20      -0.53
#> 4             5           4         0.62154653    101.28   42.11     -59.17
#> 5             4           3         0.86879505     42.11    2.73     -39.38
#> 6             5           3         1.37271481    101.28    2.73     -98.55
#>   improvement_cost from_benefit to_benefit delta_benefit improvement_benefit
#> 1             0.10     1.312279  0.7616224    -0.5506563          -0.5506563
#> 2             0.63     2.297378  0.7616224    -1.5357557          -1.5357557
#> 3             0.53     2.297378  1.3122787    -0.9850994          -0.9850994
#> 4            59.17    29.796218 24.7340291    -5.0621884          -5.0621884
#> 5            39.38    24.734029  2.2973781   -22.4366510         -22.4366510
#> 6            98.55    29.796218  2.2973781   -27.4988394         -27.4988394
```
