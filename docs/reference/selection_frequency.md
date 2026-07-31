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
[`get_planning_units`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md)

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
#>     pu  action n_selected n_solutions frequency
#> 1    1 protect          0           3 0.0000000
#> 2    1 restore          1           3 0.3333333
#> 3   10 protect          0           3 0.0000000
#> 4   10 restore          1           3 0.3333333
#> 5   11 protect          0           3 0.0000000
#> 6   11 restore          1           3 0.3333333
#> 7   12 protect          0           3 0.0000000
#> 8   12 restore          1           3 0.3333333
#> 9   13 protect          1           3 0.3333333
#> 10  13 restore          0           3 0.0000000
#> 11  14 protect          1           3 0.3333333
#> 12  14 restore          0           3 0.0000000
#> 13  15 protect          1           3 0.3333333
#> 14  15 restore          0           3 0.0000000
#> 15  16 protect          1           3 0.3333333
#> 16  16 restore          0           3 0.0000000
#> 17  17 protect          0           3 0.0000000
#> 18  17 restore          1           3 0.3333333
#> 19  18 protect          0           3 0.0000000
#> 20  18 restore          1           3 0.3333333
#> 21  19 protect          0           3 0.0000000
#> 22  19 restore          1           3 0.3333333
#> 23   2 protect          0           3 0.0000000
#> 24   2 restore          1           3 0.3333333
#> 25  20 protect          0           3 0.0000000
#> 26  20 restore          1           3 0.3333333
#> 27  21 protect          0           3 0.0000000
#> 28  21 restore          1           3 0.3333333
#> 29  22 protect          1           3 0.3333333
#> 30  22 restore          0           3 0.0000000
#> 31  23 protect          1           3 0.3333333
#> 32  23 restore          0           3 0.0000000
#> 33  24 protect          1           3 0.3333333
#> 34  24 restore          0           3 0.0000000
#> 35  25 protect          1           3 0.3333333
#> 36  25 restore          0           3 0.0000000
#> 37  26 protect          1           3 0.3333333
#> 38  26 restore          0           3 0.0000000
#> 39  27 protect          0           3 0.0000000
#> 40  27 restore          1           3 0.3333333
#> 41  28 protect          0           3 0.0000000
#> 42  28 restore          1           3 0.3333333
#> 43  29 protect          0           3 0.0000000
#> 44  29 restore          1           3 0.3333333
#> 45   3 protect          0           3 0.0000000
#> 46   3 restore          1           3 0.3333333
#> 47  30 protect          0           3 0.0000000
#> 48  30 restore          1           3 0.3333333
#> 49  31 protect          0           3 0.0000000
#> 50  31 restore          1           3 0.3333333
#> 51  32 protect          0           3 0.0000000
#> 52  32 restore          1           3 0.3333333
#> 53  33 protect          2           3 0.6666667
#> 54  33 restore          0           3 0.0000000
#> 55  34 protect          1           3 0.3333333
#> 56  34 restore          0           3 0.0000000
#> 57  35 protect          1           3 0.3333333
#> 58  35 restore          0           3 0.0000000
#> 59  36 protect          1           3 0.3333333
#> 60  36 restore          0           3 0.0000000
#> 61  37 protect          0           3 0.0000000
#> 62  37 restore          1           3 0.3333333
#> 63  38 protect          0           3 0.0000000
#> 64  38 restore          1           3 0.3333333
#> 65  39 protect          0           3 0.0000000
#> 66  39 restore          1           3 0.3333333
#> 67   4 protect          1           3 0.3333333
#> 68   4 restore          0           3 0.0000000
#> 69  40 protect          0           3 0.0000000
#> 70  40 restore          1           3 0.3333333
#> 71  41 protect          1           3 0.3333333
#> 72  41 restore          0           3 0.0000000
#> 73  42 protect          2           3 0.6666667
#> 74  42 restore          0           3 0.0000000
#> 75  43 protect          1           3 0.3333333
#> 76  43 restore          0           3 0.0000000
#> 77  44 protect          1           3 0.3333333
#> 78  44 restore          0           3 0.0000000
#> 79  45 protect          1           3 0.3333333
#> 80  45 restore          0           3 0.0000000
#> 81  46 protect          0           3 0.0000000
#> 82  46 restore          1           3 0.3333333
#> 83  47 protect          0           3 0.0000000
#> 84  47 restore          2           3 0.6666667
#> 85  48 protect          0           3 0.0000000
#> 86  48 restore          1           3 0.3333333
#> 87  49 protect          1           3 0.3333333
#> 88  49 restore          0           3 0.0000000
#> 89   5 protect          1           3 0.3333333
#> 90   5 restore          0           3 0.0000000
#> 91  50 protect          1           3 0.3333333
#> 92  50 restore          0           3 0.0000000
#> 93  51 protect          1           3 0.3333333
#> 94  51 restore          0           3 0.0000000
#> 95  52 protect          1           3 0.3333333
#> 96  52 restore          0           3 0.0000000
#> 97  53 protect          1           3 0.3333333
#> 98  53 restore          0           3 0.0000000
#> 99  54 protect          1           3 0.3333333
#> 100 54 restore          0           3 0.0000000
#> 101 55 protect          0           3 0.0000000
#> 102 55 restore          1           3 0.3333333
#> 103 56 protect          0           3 0.0000000
#> 104 56 restore          1           3 0.3333333
#> 105 57 protect          1           3 0.3333333
#> 106 57 restore          0           3 0.0000000
#> 107 58 protect          1           3 0.3333333
#> 108 58 restore          0           3 0.0000000
#> 109 59 protect          1           3 0.3333333
#> 110 59 restore          0           3 0.0000000
#> 111  6 protect          1           3 0.3333333
#> 112  6 restore          0           3 0.0000000
#> 113 60 protect          1           3 0.3333333
#> 114 60 restore          0           3 0.0000000
#> 115 61 protect          1           3 0.3333333
#> 116 61 restore          0           3 0.0000000
#> 117 62 protect          1           3 0.3333333
#> 118 62 restore          0           3 0.0000000
#> 119 63 protect          1           3 0.3333333
#> 120 63 restore          0           3 0.0000000
#> 121 64 protect          0           3 0.0000000
#> 122 64 restore          1           3 0.3333333
#> 123  7 protect          1           3 0.3333333
#> 124  7 restore          0           3 0.0000000
#> 125  8 protect          1           3 0.3333333
#> 126  8 restore          0           3 0.0000000
#> 127  9 protect          1           3 0.3333333
#> 128  9 restore          1           3 0.3333333
```
