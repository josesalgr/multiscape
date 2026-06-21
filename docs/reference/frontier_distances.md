# Compute distances to observed ideal or nadir points

Compute normalized distances from each stored solution in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object to the observed ideal and/or nadir point in objective space.

## Usage

``` r
frontier_distances(
  x,
  objectives = NULL,
  reference = "ideal",
  metric = c("euclidean", "manhattan", "chebyshev")
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

- reference:

  Character vector indicating the reference point or points to use.
  Allowed values are `"ideal"` and `"nadir"`. If both are supplied,
  distances and ranks for both reference points are returned. Default is
  `"ideal"`.

- metric:

  Character. Distance metric to use. One of `"euclidean"`,
  `"manhattan"`, or `"chebyshev"`.

## Value

A `data.frame` with one row per stored solution having complete values
for the selected objectives.

The table contains:

- `run_id` and `solution_id`;

- the original objective values;

- normalized objective values prefixed with `norm_`;

- distance and rank columns for the requested reference points.

The returned table also contains the following attributes:

- `"ideal"`: observed ideal point in the original objective scales;

- `"nadir"`: observed nadir point in the original objective scales;

- `"ranges"`: observed absolute ranges in the original objective scales;

- `"objectives"`: objective names used;

- `"sense"`: optimization sense of each objective;

- `"metric"`: distance metric used;

- `"reference"`: requested reference point or points;

- `"normalized"`: whether normalized values were used;

- `"space"`: objective space used for distance calculations.

## Details

This function supports the interpretation and ranking of trade-offs
among solutions stored in a `SolutionSet`.

The calculations are based on the solutions contained in the supplied
object. Therefore, the observed ideal point, observed nadir point,
objective ranges, normalized values, and distances may change when the
input `SolutionSet` is filtered.

To calculate distances using only non-dominated solutions, first use:


    x_nd <- solution_filter(x, nondominated = TRUE)
    frontier_distances(x_nd)

Objective values are internally transformed to a common minimization
space using the objective senses registered in `get_objective_specs`.
Objectives with `sense = "min"` are kept unchanged, whereas objectives
with `sense = "max"` are multiplied by \\-1\\. In this transformed
space, lower values are always better.

The observed ideal point is defined by the best observed value for each
objective:

\$\$ z_j^{ideal} = \min_i z\_{ij}, \$\$

where \\z\_{ij}\\ is the transformed value of solution \\i\\ for
objective \\j\\.

The observed nadir point is defined by the worst observed value for each
objective:

\$\$ z_j^{nadir} = \max_i z\_{ij}. \$\$

These reference points are empirical bounds derived from the supplied
solutions. They are not necessarily the true ideal and nadir points of
the complete feasible objective space.

Objective values are normalized to the interval \\\[0,1\]\\ using:

\$\$ \tilde{z}\_{ij} = \frac{z\_{ij} - z_j^{ideal}} {z_j^{nadir} -
z_j^{ideal}}. \$\$

After normalization:

- `0` represents the best observed value for an objective;

- `1` represents the worst observed value for an objective.

This interpretation is independent of whether the original objective was
minimized or maximized.

If an objective has zero observed range, all normalized values for that
objective are set to zero. The objective therefore does not contribute
to the calculated distances.

For distances to the ideal point, smaller values are preferred and
`rank_to_ideal = 1` identifies the closest solution.

For distances to the nadir point, larger values are preferred and
`rank_from_nadir = 1` identifies the solution farthest from the observed
nadir point.

## See also

[`frontier_extremes`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
`get_objective_specs`,
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

  # Normalized Euclidean distance to the observed ideal point
  frontier_distances(solutions)

  # Distances to both observed ideal and nadir points
  distances <- frontier_distances(
    solutions,
    reference = c("ideal", "nadir")
  )

  # Use only selected objectives
  frontier_distances(
    solutions,
    objectives = c("cost", "benefit")
  )

  # Use Manhattan distance
  frontier_distances(
    solutions,
    metric = "manhattan"
  )

  # Use Chebyshev distance
  frontier_distances(
    solutions,
    metric = "chebyshev"
  )

  # Inspect observed reference points and objective ranges
  attr(distances, "ideal")
  attr(distances, "nadir")
  attr(distances, "ranges")

  # Calculate distances only over non-dominated solutions
  if (requireNamespace("moocore", quietly = TRUE)) {
    nondominated_solutions <- solution_filter(
      solutions,
      feasible_only = TRUE,
      nondominated = TRUE
    )

    frontier_distances(
      nondominated_solutions,
      reference = c("ideal", "nadir")
    )
  }
}
#> 'as(<dgTMatrix>, "dgCMatrix")' is deprecated.
#> Use 'as(., "CsparseMatrix")' instead.
#> See help("Deprecated") and help("Matrix-deprecated").
#>   run_id solution_id cost benefit norm_cost norm_benefit distance_to_ideal
#> 1      1           1    2     0.0    0.0000   1.00000000         1.0000000
#> 2      2           2    3     3.5    0.0625   0.53333333         0.5369830
#> 3      4           4   12     7.0    0.6250   0.06666667         0.6285455
#> 4      5           5   18     7.5    1.0000   0.00000000         1.0000000
#>   rank_to_ideal distance_to_nadir rank_from_nadir
#> 1             3          1.000000               3
#> 2             1          1.047227               1
#> 3             2          1.005851               2
#> 4             3          1.000000               3
```
