# Measure decision turnover along an objective-space neighborhood

Measure decision-space change between selected solution pairs and relate
it to their normalized objective-space distance.

## Usage

``` r
linkage_turnover(
  x,
  objectives = NULL,
  pairs = NULL,
  objective_metric = c("euclidean", "manhattan", "chebyshev"),
  decision_metric = c("jaccard", "hamming"),
  tolerance = sqrt(.Machine$double.eps)
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
  If `NULL`, objectives stored on `pairs` are reused when available;
  otherwise all registered objectives are used.

- pairs:

  Either `NULL`, or a non-empty `data.frame` containing numeric
  positive-integer `from_solution` and `to_solution` columns. Output
  from
  [`frontier_neighbors`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md)
  can be supplied directly.

- objective_metric:

  Objective-space metric: `"euclidean"`, `"manhattan"`, or
  `"chebyshev"`. The metric is also used to generate neighbors when
  `pairs = NULL`.

- decision_metric:

  Decision-space metric over the complete planning-unit/action
  assignment space: `"jaccard"` or `"hamming"`.

- tolerance:

  A single finite non-negative number. Pairs whose normalized objective
  distance is less than or equal to this value are treated as objective
  ties.

## Value

A `data.frame` extending the output of
[`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md)
with logical `objective_tie` and numeric `reconfiguration_rate` columns.
Decision turnover is the existing `decision_distance` column.

## Details

Decision turnover is the `decision_distance` returned by
[`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md).
The reconfiguration rate relates that turnover to normalized
objective-space separation: \$\$R\_{rs} = d_X(r,s) / d_Z(r,s).\$\$ It is
a unitless ratio, not a temporal rate or a percentage of landscape area.
No additional `turnover` column is returned because it would duplicate
`decision_distance`.

A pair is an objective tie when `objective_distance <= tolerance`. Tied
pairs receive `NA_real_` for `reconfiguration_rate`, including pairs
with identical decisions, avoiding undefined or infinite ratios.
Non-tied pairs with identical decisions receive a rate of zero.

If `pairs = NULL`, neighboring pairs are generated with
[`frontier_neighbors`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md)
using `method = "auto"` and the requested `objective_metric`. Supplied
pairs preserve their direction. Reconfiguration rates should be compared
only among analyses using the same objectives, supplied `SolutionSet`,
normalization basis, and distance metrics.

## See also

[`frontier_neighbors`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md),
[`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
[`linkage_contrasts`](https://josesalgr.github.io/multiscape/reference/linkage_contrasts.md)

Other Objective–decision linkage:
[`linkage_contrasts()`](https://josesalgr.github.io/multiscape/reference/linkage_contrasts.md),
[`linkage_distances()`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
[`linkage_transition()`](https://josesalgr.github.io/multiscape/reference/linkage_transition.md)

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
    objectives = c("cost", "benefit")
  )

  turnover <- linkage_turnover(
    solutions,
    objectives = c("cost", "benefit"),
    pairs = neighbors
  )

  turnover

  turnover[
    turnover$objective_tie &
      turnover$decision_distance > 0,
    ,
    drop = FALSE
  ]
}
#>  [1] from_solution              to_solution               
#>  [3] objective_distance         decision_similarity       
#>  [5] decision_distance          objective_tie             
#>  [7] reconfiguration_rate       changed_assignments       
#>  [9] changed_planning_units     additions                 
#> [11] removals                   activated_planning_units  
#> [13] deactivated_planning_units action_switches           
#> [15] composition_changes        from_cost                 
#> [17] to_cost                    delta_cost                
#> [19] improvement_cost           from_benefit              
#> [21] to_benefit                 delta_benefit             
#> [23] improvement_benefit       
#> <0 rows> (or 0-length row.names)
```
