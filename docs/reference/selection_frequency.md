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
if (FALSE) { # \dontrun{
# Frequency across all stored solutions
freq <- selection_frequency(ss)

# Frequency across non-dominated and structurally unique solutions
ss_clean <- ss |>
  solution_filter(nondominated = TRUE) |>
  solution_unique(by = "decisions")

freq_clean <- selection_frequency(ss_clean)

# Planning-unit frequency for receiving any action
pu_frequency <- aggregate(
  frequency ~ pu,
  data = freq_clean,
  FUN = sum
)
} # }
```
