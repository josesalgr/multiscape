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
    runs = run_grid(
      n = 5,
      include_extremes = TRUE
    ),
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
#>    s1        s2        s4   s5
#> s1  1 0.0000000 0.0000000 0.00
#> s2  0 1.0000000 0.3333333 0.25
#> s4  0 0.3333333 1.0000000 0.75
#> s5  0 0.2500000 0.7500000 1.00
#> attr(,"metric")
#> [1] "jaccard"
```
