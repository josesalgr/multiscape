# Calculate structural similarity among solutions

Calculate pairwise structural similarity among the stored solutions in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Usage

``` r
selection_similarity(
  x,
  metric = c("jaccard", "hamming"),
  format = c("long", "matrix")
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- metric:

  Character. Similarity metric to use. One of `"jaccard"` or
  `"hamming"`.

- format:

  Character. Output format. If `"long"`, return one row per pair of
  solutions. If `"matrix"`, return a symmetric similarity matrix with
  solution ids as row and column names.

## Value

If `format = "long"`, a `data.frame` with columns:

- `solution_id_1`;

- `solution_id_2`;

- `similarity`;

- `distance`.

If `format = "matrix"`, a symmetric numeric matrix of similarities is
returned. Its diagonal is equal to one.

The selected metric is stored in the `"metric"` attribute.

## Details

Solutions are compared using their complete planning-unit/action
assignment vectors. Consequently, two solutions that select the same
planning unit but assign different actions are treated as structurally
different.

For simple conservation-planning problems without explicit actions,
selected planning units are represented using the canonical action name
`"conservation"`.

Two similarity metrics are supported:

- `"jaccard"` compares the sets of selected planning-unit/action
  assignments:

  \$\$ J(A,B) = \frac{\|A \cap B\|} {\|A \cup B\|}. \$\$

  Jaccard similarity focuses on selected assignments and ignores joint
  absences. It is generally the preferred metric for sparse conservation
  and management portfolios.

- `"hamming"` calculates the proportion of decision-vector positions
  that are equal:

  \$\$ H(A,B) = \frac{1}{m} \sum\_{k=1}^{m} I(A_k = B_k), \$\$

  where \\m\\ is the number of feasible planning-unit/action
  assignments. Unlike Jaccard similarity, Hamming similarity includes
  shared non-selections.

For both metrics, similarity ranges from zero to one:

- `1` indicates identical assignment structures;

- `0` indicates no structural agreement under the selected metric.

The corresponding distance is calculated as:

\$\$ D(A,B) = 1 - S(A,B). \$\$

The comparison is performed over all stored solutions in the supplied
object. To compare only a subset, first use
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
or
[`solution_unique`](https://josesalgr.github.io/multiscape/reference/solution_unique.md).

## See also

[`selection_frequency`](https://josesalgr.github.io/multiscape/reference/selection_frequency.md),
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

  # Pairwise Jaccard similarity in long format
  jaccard_long <- selection_similarity(
    solutions
  )

  jaccard_long

  # Symmetric Jaccard similarity matrix
  jaccard_matrix <- selection_similarity(
    solutions,
    format = "matrix"
  )

  jaccard_matrix

  # Hamming similarity includes shared non-selections
  hamming_long <- selection_similarity(
    solutions,
    metric = "hamming"
  )

  hamming_long

  # Compare only structurally unique solutions
  unique_solutions <- solution_unique(
    solutions,
    by = "decisions"
  )

  selection_similarity(
    unique_solutions,
    format = "matrix"
  )
}
#>            1       2          3
#> 1 1.00000000 0.00000 0.01538462
#> 2 0.00000000 1.00000 0.03125000
#> 3 0.01538462 0.03125 1.00000000
#> attr(,"metric")
#> [1] "jaccard"
```
