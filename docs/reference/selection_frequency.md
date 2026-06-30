# Calculate selection frequency across solutions

Calculate how frequently each planning-unit/action assignment is
selected across the stored solutions in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Usage

``` r
selection_frequency(x)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Value

A `data.frame` with one row per planning-unit/action pair and the
following columns:

- `pu`: planning-unit identifier;

- `action`: action identifier or name;

- `n_selected`: number of stored solutions in which the
  planning-unit/action pair is selected;

- `n_solutions`: total number of stored solutions considered;

- `frequency`: proportion of stored solutions in which the pair is
  selected.

## Details

Selection frequency is calculated at the planning-unit/action level.
This is the canonical decision representation used by this function
because it preserves differences between solutions that select the same
planning unit but assign different actions.

For each planning-unit/action pair, the frequency is:

\$\$ f\_{ia} = \frac{\sum\_{s \in S} x\_{ias}} {\|S\|}, \$\$

where \\x\_{ias}\\ equals one when planning unit \\i\\ receives action
\\a\\ in solution \\s\\, and zero otherwise.

The result is computed over all stored solutions in the supplied
`SolutionSet`. To calculate frequencies for only a subset of solutions,
first use
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
or
[`solution_unique`](https://josesalgr.github.io/multiscape/reference/solution_unique.md).

For simple conservation-planning problems without explicit actions,
selected planning units are represented using the canonical action name
`"conservation"`.

Selection frequency measures recurrence across the supplied solutions.
It should not automatically be interpreted as formal irreplaceability
because it depends on the solutions included, their sampling across
objective space, and whether duplicate or dominated solutions have been
retained.

## See also

[`selection_similarity`](https://josesalgr.github.io/multiscape/reference/selection_similarity.md),
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md),
[`solution_unique`](https://josesalgr.github.io/multiscape/reference/solution_unique.md),
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md)

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

  # Frequency across all stored solutions
  frequency <- selection_frequency(solutions)
  frequency

  # Restrict the analysis to non-dominated solutions
  if (requireNamespace("moocore", quietly = TRUE)) {
    nondominated_solutions <- solution_filter(
      solutions,
      feasible_only = TRUE,
      nondominated = TRUE
    )

    selection_frequency(nondominated_solutions)
  }

  # Give each distinct decision configuration the same weight
  unique_solutions <- solution_unique(
    solutions,
    by = "decisions"
  )

  unique_frequency <- selection_frequency(
    unique_solutions
  )

  unique_frequency
}
#>   pu       action n_selected n_solutions frequency
#> 1  1 conservation          1           4      0.25
#> 2  1  restoration          3           4      0.75
#> 3  2 conservation          0           4      0.00
#> 4  2  restoration          2           4      0.50
#> 5  3 conservation          0           4      0.00
#> 6  3  restoration          2           4      0.50
#> 7  4 conservation          0           4      0.00
#> 8  4  restoration          1           4      0.25
```
