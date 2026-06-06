# Keep unique solutions in a solution set

Return a reduced
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object containing one representative from each group of equivalent
solutions.

Solutions can be considered equivalent according to either their
decision vectors or their objective values.

## Usage

``` r
solution_unique(
  x,
  by = c("decisions", "objectives"),
  keep = c("first", "last"),
  objectives = NULL,
  tolerance = sqrt(.Machine$double.eps)
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- by:

  Character. Definition of uniqueness. One of `"decisions"` or
  `"objectives"`.

- keep:

  Character. Which representative to retain from each group of
  equivalent solutions. If `"first"`, retain the first solution in the
  current run order. If `"last"`, retain the last.

- objectives:

  Optional character vector of objective names to compare when
  `by = "objectives"`. If `NULL`, all available objectives are used.
  This argument is ignored when `by = "decisions"`.

- tolerance:

  Non-negative numeric tolerance used when comparing objective values.
  It is only used when `by = "objectives"`.

## Value

A new
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object containing one representative from each group of equivalent
stored solutions, together with any runs that did not produce a stored
solution.

## Details

`solution_unique()` is a solution-set management function. It removes
repeated solutions while consistently filtering the run table, design
table, stored run-level solutions, and summary tables.

Two definitions of uniqueness are supported:

- `by = "decisions"` compares the complete stored decision vector of
  each solution. Two solutions are considered equivalent when their
  decision vectors are identical. This identifies repeated planning-unit
  or planning-unit/action configurations, even when they were generated
  by different runs or multi-objective parameter combinations.

- `by = "objectives"` compares the selected objective values. Two
  solutions are considered equivalent when all compared objective values
  are equal within the specified numerical `tolerance`. Such solutions
  may still have different decision vectors.

Consequently, uniqueness in objective space and uniqueness in decision
space are not equivalent. Two spatially different solutions may produce
the same objective values, while repeated runs may generate exactly the
same decision vector.

Only runs with a stored `solution_id` can be assessed. Runs without a
stored solution, such as infeasible runs, are preserved unchanged. This
retains the full run history while removing only duplicated stored
solutions.

The function does not renumber `run_id` or `solution_id`. The
representative retained from each duplicate group keeps its original
identifiers, preserving traceability to the original run design.

For `by = "objectives"`, numerical equality is assessed using a relative
comparison:

\$\$ \|a-b\| \leq \epsilon \max(1, \|a\|, \|b\|), \$\$

where \\\epsilon\\ is specified by `tolerance`. This avoids treating
insignificant floating-point differences as distinct objective points.

## See also

[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md),
[`solution_append`](https://josesalgr.github.io/multiscape/reference/solution_append.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`get_solution_vector`](https://josesalgr.github.io/multiscape/reference/get_solution_vector.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Keep one representative for each distinct decision vector
ss_unique <- solution_unique(ss)

# Keep one representative for each distinct objective point
ss_unique_obj <- solution_unique(
  ss,
  by = "objectives"
)

# Compare only selected objectives
ss_unique_cf <- solution_unique(
  ss,
  by = "objectives",
  objectives = c("cost", "frag")
)

# Keep the last representative from each duplicate group
ss_unique_last <- solution_unique(
  ss,
  by = "decisions",
  keep = "last"
)

# Typical multi-objective cleaning workflow
ss_clean <- ss |>
  solution_filter(
    feasible_only = TRUE,
    nondominated = TRUE
  ) |>
  solution_unique(
    by = "decisions"
  )
} # }
```
