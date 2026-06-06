# Append solutions from another solution set

Append the runs and stored solutions from one
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object to another.

This function combines two `SolutionSet` objects generated from the same
planning problem. It is intended for combining results obtained with
different multiscape solving workflows, such as weighted-sum,
epsilon-constraint, or AUGMECON methods, while keeping a single coherent
result object for downstream extraction, plotting, and analysis.

## Usage

``` r
solution_append(x, y)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- y:

  A second
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)
  and generated from the same planning problem as `x`.

## Value

A new
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object containing the runs and stored solutions from both input objects.

## Details

`solution_append()` is a solution-set management function. It does not
modify the original input objects. Instead, it returns a new
`SolutionSet` containing the runs and solutions from both inputs.

Both input objects must be generated from the same planning problem.
This is checked conservatively before appending. In particular, the two
objects must have compatible:

- planning units;

- features and feature distributions;

- actions, feasible action pairs, and effects;

- profit data, when present;

- targets;

- locks and constraints;

- spatial relations;

- objective specifications.

Differences in method settings, run design, solver settings, solver
status, runtime, gaps, and other solve diagnostics are allowed.

The appended runs and solutions are assigned new `run_id` and
`solution_id` values to keep identifiers unique in the combined object.
Identifiers are not required to match between the two inputs.

This function is not intended to combine results from different planning
problems, scenarios, target sets, or objective definitions. Such
workflows should be handled by a future comparison/binding function
rather than by `solution_append()`.

## See also

[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md),
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`plot_tradeoff`](https://josesalgr.github.io/multiscape/reference/plot_tradeoff.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ss_weighted <- solve(problem_weighted)
ss_epsilon <- solve(problem_epsilon)

ss_all <- solution_append(ss_weighted, ss_epsilon)

get_runs(ss_all)
get_objectives(ss_all)
plot_tradeoff(ss_all)
} # }
```
