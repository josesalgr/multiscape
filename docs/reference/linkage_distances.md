# Compare objective and decision distances

Measure separately how far pairs of stored solutions are in objective
space and how much their planning-unit/action assignments differ.

## Usage

``` r
linkage_distances(
  x,
  objectives = NULL,
  pairs = NULL,
  objective_metric = c("euclidean", "manhattan", "chebyshev"),
  decision_metric = c("jaccard", "hamming")
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- objectives:

  Optional character vector with two or more unique objective aliases.
  If `NULL`, all registered objectives are used.

- pairs:

  Either `NULL`, or a non-empty `data.frame` containing numeric
  positive-integer `from_solution` and `to_solution` columns. Output
  from
  [`frontier_neighbors`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md)
  can be supplied directly.

- objective_metric:

  Objective-space distance metric: `"euclidean"`, `"manhattan"`, or
  `"chebyshev"`.

- decision_metric:

  Decision-space metric: `"jaccard"` or `"hamming"`.

## Value

A `data.frame` with one row per directed pair, including
`objective_distance`, `decision_similarity`, `decision_distance`,
decision-change counts, and objective-specific from/to values, changes,
and improvements.

## Details

Objective values are oriented to minimization and normalized using the
solutions retained in the supplied `SolutionSet`. Decision distances are
always calculated on the complete planning-unit/action assignment space
represented by the supplied solutions.

If `pairs = NULL`, all unordered pairs are generated and oriented from
worse to better on the first selected objective. If `pairs` is supplied,
its `from_solution` and `to_solution` direction is preserved. Distances
are symmetric, but signed objective changes and action additions or
removals depend on pair direction.

No combined linkage score is calculated.

## See also

[`frontier_neighbors`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md),
[`frontier_distances`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md),
[`selection_similarity`](https://josesalgr.github.io/multiscape/reference/selection_similarity.md),
[`linkage_transition`](https://josesalgr.github.io/multiscape/reference/linkage_transition.md)

Other Objective–decision linkage:
[`linkage_contrasts()`](https://josesalgr.github.io/multiscape/reference/linkage_contrasts.md),
[`linkage_transition()`](https://josesalgr.github.io/multiscape/reference/linkage_transition.md),
[`linkage_turnover()`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md)

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

  linkage <- linkage_distances(
    solutions,
    objectives = c("cost", "benefit")
  )

  head(linkage)

  neighbors <- frontier_neighbors(
    solutions,
    objectives = c("cost", "benefit")
  )

  linkage_distances(
    solutions,
    objectives = c("cost", "benefit"),
    pairs = neighbors
  )
}
#>   from_solution to_solution objective_distance decision_similarity
#> 1             5           4         0.62154653          0.43750000
#> 2             4           3         0.86879505          0.07142857
#> 3             3           2         0.03434672          0.33333333
#> 4             2           1         0.01899231          0.33333333
#>   decision_distance changed_assignments changed_planning_units additions
#> 1         0.5625000                  36                     36         0
#> 2         0.9285714                  26                     26         0
#> 3         0.6666667                   2                      2         1
#> 4         0.6666667                   2                      2         1
#>   removals activated_planning_units deactivated_planning_units action_switches
#> 1       36                        0                         36               0
#> 2       26                        0                         26               0
#> 3        1                        1                          1               0
#> 4        1                        1                          1               0
#>   composition_changes from_cost to_cost delta_cost improvement_cost
#> 1                   0    101.28   42.11     -59.17            59.17
#> 2                   0     42.11    2.73     -39.38            39.38
#> 3                   0      2.73    2.20      -0.53             0.53
#> 4                   0      2.20    2.10      -0.10             0.10
#>   from_benefit to_benefit delta_benefit improvement_benefit
#> 1    29.796218 24.7340291    -5.0621884          -5.0621884
#> 2    24.734029  2.2973781   -22.4366510         -22.4366510
#> 3     2.297378  1.3122787    -0.9850994          -0.9850994
#> 4     1.312279  0.7616224    -0.5506563          -0.5506563
```
