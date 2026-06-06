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
if (FALSE) { # \dontrun{
# Pairwise Jaccard similarity in long format
sim <- selection_similarity(ss)

# Similarity matrix
sim_matrix <- selection_similarity(
  ss,
  format = "matrix"
)

# Hamming similarity
sim_hamming <- selection_similarity(
  ss,
  metric = "hamming"
)

# Compare only non-dominated and structurally unique solutions
ss_clean <- ss |>
  solution_filter(nondominated = TRUE) |>
  solution_unique(by = "decisions")

sim_clean <- selection_similarity(ss_clean)
} # }
```
