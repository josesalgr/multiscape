# Describe the transition between two solutions

Explain the objective and spatial changes required to transform one
stored solution into another.

## Usage

``` r
linkage_transition(x, from, to, objectives = NULL)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- from:

  A single numeric positive-integer id identifying the starting stored
  solution.

- to:

  A single numeric positive-integer id identifying the destination
  stored solution.

- objectives:

  Optional character vector with one or more objective aliases. If
  `NULL`, all registered objectives are reported.

## Value

An object of class `multiscape_linkage_transition` containing:

- `summary`: the directed solution ids and transition counts;

- `objectives`: objective values and signed changes;

- `transitions`: one row per planning unit in the complete landscape,
  including unchanged units;

- `actions`: action assignments selected in either solution;

- `state_matrix`: counts of planning-unit state transitions.

## Details

The transition is directional. Reversing `from` and `to` reverses signed
objective changes, additions and removals, and planning-unit activations
and deactivations. Canonical planning-unit states are obtained from
[`get_solution_states`](https://josesalgr.github.io/multiscape/reference/get_solution_states.md).

The complete landscape is always returned in `transitions`, including
planning units whose state is unchanged. To keep the action-level output
compact, `actions` contains assignments selected in at least one of the
two solutions; added, removed, and retained actions remain explicit.

## See also

[`get_solution_states`](https://josesalgr.github.io/multiscape/reference/get_solution_states.md),
[`linkage_distances`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
[`frontier_neighbors`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md)

Other Objective–decision linkage:
[`linkage_contrasts()`](https://josesalgr.github.io/multiscape/reference/linkage_contrasts.md),
[`linkage_distances()`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md),
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

  neighbors <- frontier_neighbors(
    solutions,
    objectives = c("cost", "benefit")
  )

  transition <- linkage_transition(
    solutions,
    from = neighbors$from_solution[1],
    to = neighbors$to_solution[1],
    objectives = c("cost", "benefit")
  )

  transition$summary
  transition$objectives

  transition$transitions[
    transition$transitions$changed,
    ,
    drop = FALSE
  ]
}
#>    pu from_state  to_state from_managed to_managed n_actions_from n_actions_to
#> 1   1    restore unmanaged         TRUE      FALSE              1            0
#> 3  11    restore unmanaged         TRUE      FALSE              1            0
#> 4  12    restore unmanaged         TRUE      FALSE              1            0
#> 5  13    protect unmanaged         TRUE      FALSE              1            0
#> 6  14    protect unmanaged         TRUE      FALSE              1            0
#> 7  15    protect unmanaged         TRUE      FALSE              1            0
#> 8  16    protect unmanaged         TRUE      FALSE              1            0
#> 9  17    restore unmanaged         TRUE      FALSE              1            0
#> 12  2    restore unmanaged         TRUE      FALSE              1            0
#> 13 20    restore unmanaged         TRUE      FALSE              1            0
#> 14 21    restore unmanaged         TRUE      FALSE              1            0
#> 15 22    protect unmanaged         TRUE      FALSE              1            0
#> 16 23    protect unmanaged         TRUE      FALSE              1            0
#> 17 24    protect unmanaged         TRUE      FALSE              1            0
#> 18 25    protect unmanaged         TRUE      FALSE              1            0
#> 19 26    protect unmanaged         TRUE      FALSE              1            0
#> 23  3    restore unmanaged         TRUE      FALSE              1            0
#> 24 30    restore unmanaged         TRUE      FALSE              1            0
#> 25 31    restore unmanaged         TRUE      FALSE              1            0
#> 26 32    restore unmanaged         TRUE      FALSE              1            0
#> 33 39    restore unmanaged         TRUE      FALSE              1            0
#> 34  4    protect unmanaged         TRUE      FALSE              1            0
#> 35 40    restore unmanaged         TRUE      FALSE              1            0
#> 40 45    protect unmanaged         TRUE      FALSE              1            0
#> 45  5    protect unmanaged         TRUE      FALSE              1            0
#> 49 53    protect unmanaged         TRUE      FALSE              1            0
#> 50 54    protect unmanaged         TRUE      FALSE              1            0
#> 51 55    restore unmanaged         TRUE      FALSE              1            0
#> 56  6    protect unmanaged         TRUE      FALSE              1            0
#> 57 60    protect unmanaged         TRUE      FALSE              1            0
#> 58 61    protect unmanaged         TRUE      FALSE              1            0
#> 59 62    protect unmanaged         TRUE      FALSE              1            0
#> 60 63    protect unmanaged         TRUE      FALSE              1            0
#> 61 64    restore unmanaged         TRUE      FALSE              1            0
#> 62  7    protect unmanaged         TRUE      FALSE              1            0
#> 63  8    protect unmanaged         TRUE      FALSE              1            0
#>    changed  transition added_actions removed_actions retained_actions
#> 1     TRUE deactivated          <NA>         restore             <NA>
#> 3     TRUE deactivated          <NA>         restore             <NA>
#> 4     TRUE deactivated          <NA>         restore             <NA>
#> 5     TRUE deactivated          <NA>         protect             <NA>
#> 6     TRUE deactivated          <NA>         protect             <NA>
#> 7     TRUE deactivated          <NA>         protect             <NA>
#> 8     TRUE deactivated          <NA>         protect             <NA>
#> 9     TRUE deactivated          <NA>         restore             <NA>
#> 12    TRUE deactivated          <NA>         restore             <NA>
#> 13    TRUE deactivated          <NA>         restore             <NA>
#> 14    TRUE deactivated          <NA>         restore             <NA>
#> 15    TRUE deactivated          <NA>         protect             <NA>
#> 16    TRUE deactivated          <NA>         protect             <NA>
#> 17    TRUE deactivated          <NA>         protect             <NA>
#> 18    TRUE deactivated          <NA>         protect             <NA>
#> 19    TRUE deactivated          <NA>         protect             <NA>
#> 23    TRUE deactivated          <NA>         restore             <NA>
#> 24    TRUE deactivated          <NA>         restore             <NA>
#> 25    TRUE deactivated          <NA>         restore             <NA>
#> 26    TRUE deactivated          <NA>         restore             <NA>
#> 33    TRUE deactivated          <NA>         restore             <NA>
#> 34    TRUE deactivated          <NA>         protect             <NA>
#> 35    TRUE deactivated          <NA>         restore             <NA>
#> 40    TRUE deactivated          <NA>         protect             <NA>
#> 45    TRUE deactivated          <NA>         protect             <NA>
#> 49    TRUE deactivated          <NA>         protect             <NA>
#> 50    TRUE deactivated          <NA>         protect             <NA>
#> 51    TRUE deactivated          <NA>         restore             <NA>
#> 56    TRUE deactivated          <NA>         protect             <NA>
#> 57    TRUE deactivated          <NA>         protect             <NA>
#> 58    TRUE deactivated          <NA>         protect             <NA>
#> 59    TRUE deactivated          <NA>         protect             <NA>
#> 60    TRUE deactivated          <NA>         protect             <NA>
#> 61    TRUE deactivated          <NA>         restore             <NA>
#> 62    TRUE deactivated          <NA>         protect             <NA>
#> 63    TRUE deactivated          <NA>         protect             <NA>
```
