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
space using the objective senses registered in
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md).
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
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md),
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Distance to the observed ideal point
frontier_distances(ss)

# Distances to both observed ideal and nadir points
frontier_distances(
  ss,
  reference = c("ideal", "nadir")
)

# Use only a subset of objectives
frontier_distances(
  ss,
  objectives = c("cost", "frag")
)

# Use Chebyshev distance
frontier_distances(
  ss,
  metric = "chebyshev"
)

# Calculate distances only over non-dominated solutions
ss_nd <- solution_filter(ss, nondominated = TRUE)
d <- frontier_distances(
  ss_nd,
  reference = c("ideal", "nadir")
)

# Inspect the observed reference points and ranges
attr(d, "ideal")
attr(d, "nadir")
attr(d, "ranges")
} # }
```
