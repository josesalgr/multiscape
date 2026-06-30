# Get feature summary from a solution set

Extract the per-feature summary table from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

The returned table summarizes, for each feature, how much of the feature
was available in the full baseline landscape and how much is represented
by the selected planning units or selected actions in each run.

## Usage

``` r
get_features(x, solution = NULL, ...)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- solution:

  Optional positive integer giving the solution index to extract. If
  `NULL`, all runs are returned when available.

- ...:

  Deprecated arguments kept for backwards compatibility. Currently
  supports `run` and `solution_id`, which are redirected to `solution`.

## Value

A `data.frame` with one row per feature, or one row per feature–run
combination when multiple runs are present. The returned table includes,
when available or derivable, the columns `baseline_total`,
`selected_baseline`, `selected_amount_after`, `selected_benefit`,
`selected_loss`, `selected_net`, and `selected_fraction_of_baseline`.

## Details

This function reads the feature summary stored in `x$summary$features`.
It errors if that table is missing.

Feature summaries distinguish between baseline availability in the full
landscape and the contribution of selected planning units or selected
actions.

Let \\B_f\\ denote the total baseline amount of feature \\f\\ available
in the full landscape. Let \\S_f\\ denote the baseline amount of feature
\\f\\ in selected rows. Let \\A_f\\ denote the after-action amount of
feature \\f\\ contributed by those selected rows. Let \\G_f\\ and
\\L_f\\ denote the positive and negative net-change components induced
by selected actions. Then:

\$\$ \mathrm{selected\\net}\_f = G_f - L_f, \$\$

and:

\$\$ A_f = S_f + \mathrm{selected\\net}\_f. \$\$

The main returned columns are:

- `baseline_total`: total baseline amount in the full landscape;

- `selected_baseline`: baseline amount in selected rows;

- `selected_amount_after`: after-action amount contributed by selected
  rows;

- `selected_benefit`: positive net-change component from selected
  actions;

- `selected_loss`: negative net-change component from selected actions;

- `selected_net`: net change from selected actions;

- `selected_fraction_of_baseline`: ratio between `selected_amount_after`
  and `baseline_total`.

Importantly, this summary does not assume that planning units without a
selected action contribute to the achieved feature amount. Therefore,
the achieved amount for a feature is represented by
`selected_amount_after`, not by a full-landscape total obtained by
adding net changes to the baseline.

For backwards compatibility with older result objects, if the newer
selected-action columns are missing, this function attempts to construct
them from older columns such as `total_available`, `benefit`, `loss`,
`net`, and `amount_after`. However, the returned table is organized
using the newer selected-action terminology.

If `solution` is provided, only rows belonging to that solution are
returned. If the result contains a `solution_id` column but only a
single solution is present and `solution` was not requested explicitly,
the `solution_id` column is removed for convenience.

This function summarizes feature outcomes in the result. It is different
from
[`get_targets`](https://josesalgr.github.io/multiscape/reference/get_targets.md),
which focuses on target achievement.

## See also

[`get_planning_units`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md),
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`get_targets`](https://josesalgr.github.io/multiscape/reference/get_targets.md)

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

problem <- create_problem(
  pu = pu,
  features = features,
  dist_features = dist_features,
  cost = "cost"
) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(alias = "cost")

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # Feature outcomes for all stored runs
  get_features(solutions)

  # Feature outcomes for one run
  solution_ids <- get_runs(solutions)$solution_id

  get_features(
    solutions,
    solution = solution_ids[1]
  )
}
#>   solution_id feature feature_name baseline_total selected_baseline
#> 1           1       1          sp1              9                 5
#> 2           1       2          sp2              6                 2
#>   selected_amount_after selected_benefit selected_loss selected_net
#> 1                     5                0             0            0
#> 2                     2                0             0            0
#>   selected_fraction_of_baseline
#> 1                     0.5555556
#> 2                     0.3333333
```
