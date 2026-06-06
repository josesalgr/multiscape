# Filter solutions in a solution set

Return a reduced
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object containing only the runs or solutions that match the requested
filters.

This function is intended to curate `SolutionSet` objects before
downstream analysis, plotting, frontier analysis, or post-hoc
evaluation. It filters all relevant components of the object
consistently, including the run table, design table, stored run-level
solutions, and available summary tables.

## Usage

``` r
solution_filter(
  x,
  run_id = NULL,
  solution_id = NULL,
  status = NULL,
  feasible_only = FALSE,
  nondominated = FALSE,
  objectives = NULL
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- run_id:

  Optional integer vector of run ids to keep.

- solution_id:

  Optional character vector of solution ids to keep. Runs without a
  stored solution are never matched by this filter.

- status:

  Optional character vector of run statuses to keep. Matching is
  case-insensitive.

- feasible_only:

  Logical. If `TRUE`, keep only runs whose status is interpreted as
  having produced a usable solution. The current accepted statuses are
  `"optimal"`, `"feasible"`, `"suboptimal"`, `"time_limit"`, and
  `"gap_limit"`.

- nondominated:

  Logical. If `TRUE`, keep only non-dominated solutions among the runs
  retained by the other filters. This uses moocore internally.

- objectives:

  Optional character vector of objective names to use when
  `nondominated = TRUE`. If `NULL`, all available objective-value
  columns are used.

## Value

A filtered
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

## Details

A `SolutionSet` distinguishes between runs and stored solutions.

- `run_id` identifies a run or attempted solve. Runs may be feasible,
  optimal, infeasible, failed, or otherwise incomplete.

- `solution_id` identifies a stored solution. Runs that did not produce
  a solution have `solution_id = NA`.

Therefore, filtering by `run_id` and filtering by `solution_id` are not
always equivalent. For example, an infeasible run may have a `run_id`
but no `solution_id`.

The function filters:

- `x$solution$runs`, using the selected `run_id`s;

- `x$solution$design`, when it contains a `run_id` column;

- `x$solution$solutions`, using the selected `solution_id`s;

- all tables in `x$summary` that contain a `run_id` column.

The function does not renumber `run_id` or `solution_id`. This preserves
traceability to the original run design.

If more than one filter is supplied, filters are combined using logical
*and*. For example, setting both `status = "optimal"` and
`solution_id = c("s1", "s3")` keeps only optimal runs whose
`solution_id` is either `"s1"` or `"s3"`.

If `nondominated = TRUE`, the function further keeps only non-dominated
solutions among the runs retained by the previous filters. Dominance is
evaluated in objective space using the objective values stored in the
run table. Objective senses are read from
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md);
any maximization objective is internally multiplied by \\-1\\ so that
dominance can be evaluated in minimization space.

Non-dominated filtering requires the moocore package.

## See also

[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md),
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md),
[`get_runs`](https://josesalgr.github.io/multiscape/reference/get_runs.md),
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md),
[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md),
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Keep only feasible or solved runs
ss_feasible <- solution_filter(ss, feasible_only = TRUE)

# Keep selected solution ids
ss_subset <- solution_filter(ss, solution_id = c("s1", "s3"))

# Keep selected run ids
ss_runs <- solution_filter(ss, run_id = c(2, 4))

# Keep only optimal runs
ss_optimal <- solution_filter(ss, status = "optimal")

# Keep only non-dominated solutions
ss_nd <- solution_filter(ss, feasible_only = TRUE, nondominated = TRUE)

# Keep non-dominated solutions using only selected objectives
ss_nd_cf <- solution_filter(
  ss,
  feasible_only = TRUE,
  nondominated = TRUE,
  objectives = c("cost", "frag")
)
} # }
```
