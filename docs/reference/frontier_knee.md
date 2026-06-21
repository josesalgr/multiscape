# Identify knee solutions on an observed Pareto frontier

Identify empirical knee, or compromise, solutions from the objective
values stored in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Usage

``` r
frontier_knee(
  x,
  objectives = NULL,
  method = c("distance", "ideal", "angle"),
  metric = c("euclidean", "manhattan", "chebyshev"),
  nondominated = TRUE,
  ties = c("first", "all"),
  return_all = FALSE
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- objectives:

  Optional character vector of objective names to use. If `NULL`, all
  available objective-value columns are used.

- method:

  Character. Method used to score knee solutions. One of `"distance"`,
  `"ideal"`, or `"angle"`.

- metric:

  Character. Distance metric used when `method = "ideal"`. One of
  `"euclidean"`, `"manhattan"`, or `"chebyshev"`.

- nondominated:

  Logical. If `TRUE`, the knee is computed after filtering to feasible
  non-dominated solutions. Defaults to `TRUE`.

- ties:

  Character. How to handle ties when `return_all = FALSE`. If `"all"`,
  all equally ranked knee solutions are returned. If `"first"`, only the
  first one is returned.

- return_all:

  Logical. If `TRUE`, return all scored solutions. If `FALSE`, return
  only the highest-ranked knee solution or solutions.

## Value

A `data.frame`. If `return_all = FALSE`, the table contains the selected
knee solution or solutions. If `return_all = TRUE`, the table contains
all candidate solutions ranked by knee score.

The returned table includes:

- `solution_id`: solution id;

- the original objective values;

- normalized objective values prefixed with `norm_`;

- method-specific diagnostic columns;

- `knee_score`: score used to rank knee solutions, where larger values
  indicate stronger knee candidates;

- `knee_rank`: rank of each solution according to `knee_score`;

- `method`: knee scoring method used.

The returned table also contains the following attributes:

- `"ideal"`: observed ideal point in the original objective scales;

- `"nadir"`: observed nadir point in the original objective scales;

- `"ranges"`: observed absolute ranges in the original objective scales;

- `"objectives"`: objective names used;

- `"sense"`: optimization sense of each objective;

- `"method"`: knee method used;

- `"nondominated"`: whether non-dominated filtering was applied;

- `"space"`: objective space used for scoring.

## Details

A knee solution is a solution located in a region of the observed
frontier where small improvements in one objective tend to require
relatively large losses in another objective. Because this concept can
be defined in several ways, `frontier_knee()` provides multiple scoring
methods.

Objective values are first transformed to a common minimization space
using the optimization sense registered in the original problem.
Objectives with `sense = "min"` are kept unchanged, whereas objectives
with `sense = "max"` are multiplied by \\-1\\. Values are then
normalized to the observed \\\[0, 1\]\\ range, where `0` represents the
best observed value and `1` represents the worst observed value for each
objective.

The available methods are:

- `"distance"`: identifies the solution with the largest perpendicular
  distance to the line connecting the two observed objective-wise
  extreme solutions. This method requires exactly two objectives and is
  the default geometric knee definition.

- `"ideal"`: identifies the solution closest to the observed ideal point
  in normalized objective space. This method can be used with two or
  more objectives and is best interpreted as a compromise solution.

- `"angle"`: identifies the solution with the largest change in
  direction along the observed bi-objective frontier. This method
  requires exactly two objectives and at least three complete solutions.

By default, `frontier_knee()` first filters the supplied `SolutionSet`
to feasible non-dominated solutions using
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md).
Set `nondominated = FALSE` to compute the knee over all stored solutions
with complete objective values.

The returned knee is empirical and depends on the supplied
`SolutionSet`. It should not be interpreted as the unique knee of the
full feasible objective space unless the supplied solutions adequately
represent the frontier.

## See also

[`frontier_distances`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md),
[`frontier_extremes`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
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
    runs = set_runs_grid(n = 5)
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(
    problem,
    verbose = FALSE
  )

  solutions <- solve(problem)

  # Default geometric knee
  frontier_knee(solutions)

  # Return all solutions ranked by knee score
  frontier_knee(
    solutions,
    return_all = TRUE
  )

  # Closest solution to the observed ideal point
  frontier_knee(
    solutions,
    method = "ideal"
  )

  # Largest change in direction along the bi-objective frontier
  frontier_knee(
    solutions,
    method = "angle"
  )
}
#>   solution_id cost benefit norm_cost norm_benefit turning_angle angle_change
#> 1           2    3     3.5    0.0625    0.5333333      2.396481    0.7451115
#>   knee_score knee_rank method
#> 1  0.7451115         1  angle
```
