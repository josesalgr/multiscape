# Select informative solution contrasts

Rank pairwise linkage results to identify solution pairs that are
especially informative in objective space, decision space, or their
relationship.

## Usage

``` r
linkage_contrasts(
  x,
  type = c("objective_similar", "decision_similar", "high_turnover",
    "high_reconfiguration", "low_reconfiguration", "objective_tie"),
  n = 3L
)
```

## Arguments

- x:

  A `data.frame` returned by
  [`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md)
  or
  [`linkage_turnover`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md).

- type:

  Contrast to rank: `"objective_similar"`, `"decision_similar"`,
  `"high_turnover"`, `"high_reconfiguration"`, `"low_reconfiguration"`,
  or `"objective_tie"`.

- n:

  Number of contrasts to return.

## Value

The first `n` ranked rows. The columns in `x` are preserved, with
`contrast_rank` and `contrast_type` prepended to identify the rank and
contrast criterion used.

## Details

`"objective_similar"` ranks pairs by increasing objective distance and
uses larger decision distance as a secondary criterion. Conversely,
`"decision_similar"` ranks pairs by increasing decision distance and
then decreasing objective distance. `"high_turnover"` ranks pairs by
decreasing decision distance.

The `"high_reconfiguration"` and `"low_reconfiguration"` types require a
numeric `reconfiguration_rate` column, as returned by
[`linkage_turnover`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md).
Rows with an undefined `reconfiguration_rate` are excluded from these
rankings.

`"objective_tie"` returns objective-equivalent pairs with non-zero
decision distance, ranked from largest to smallest spatial difference.
This type requires the logical `objective_tie` column returned by
[`linkage_turnover`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md).
The numerical tolerance used to identify objective ties is therefore
controlled only by
[`linkage_turnover()`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md).

`from_solution` and `to_solution` must contain positive integer solution
ids. Numeric values such as `1` are accepted when they are
integer-valued and are returned as integers.

## See also

[`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
[`linkage_turnover`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md)

Other Objective–decision linkage:
[`linkage_distances()`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
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
  add_objective_max_benefit(
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

  linkage_contrasts(
    linkage,
    type = "objective_similar",
    n = 3
  )

  turnover <- linkage_turnover(
    solutions,
    objectives = c("cost", "benefit")
  )

  linkage_contrasts(
    turnover,
    type = "high_reconfiguration",
    n = 3
  )
}
#>   contrast_rank        contrast_type from_solution to_solution
#> 1             1 high_reconfiguration             2           1
#> 2             2 high_reconfiguration             3           2
#> 3             3 high_reconfiguration             4           3
#>   objective_distance decision_similarity decision_distance objective_tie
#> 1         0.01899231          0.33333333         0.6666667         FALSE
#> 2         0.03434672          0.33333333         0.6666667         FALSE
#> 3         0.86879505          0.07142857         0.9285714         FALSE
#>   reconfiguration_rate changed_assignments changed_planning_units additions
#> 1            35.101931                   2                      2         1
#> 2            19.409906                   2                      2         1
#> 3             1.068804                  26                     26         0
#>   removals activated_planning_units deactivated_planning_units action_switches
#> 1        1                        1                          1               0
#> 2        1                        1                          1               0
#> 3       26                        0                         26               0
#>   composition_changes from_cost to_cost delta_cost improvement_cost
#> 1                   0      2.20    2.10      -0.10             0.10
#> 2                   0      2.73    2.20      -0.53             0.53
#> 3                   0     42.11    2.73     -39.38            39.38
#>   from_benefit to_benefit delta_benefit improvement_benefit
#> 1     1.312279  0.7616224    -0.5506563          -0.5506563
#> 2     2.297378  1.3122787    -0.9850994          -0.9850994
#> 3    24.734029  2.2973781   -22.4366510         -22.4366510
```
