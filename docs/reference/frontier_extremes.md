# Find objective-wise extreme solutions

Identify the observed minimum and maximum values for each objective in a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object.

This function returns the solutions that define the observed range of
each selected objective. It also labels each extreme as `"best"` or
`"worst"` according to the registered optimization sense of the
objective.

## Usage

``` r
frontier_extremes(x, objectives = NULL, ties = c("all", "first"))
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- objectives:

  Optional character vector of objective names to inspect. If `NULL`,
  all available objective-value columns are used.

- ties:

  Character. How to handle ties. If `"all"`, all tied solutions are
  returned. If `"first"`, only the first tied solution is returned.

## Value

A `data.frame` with one or more rows per objective. The returned columns
are:

- `objective`: objective name;

- `sense`: optimization sense, either `"min"` or `"max"`;

- `bound`: observed bound, either `"min"` or `"max"`;

- `role`: interpretation of the bound, either `"best"` or `"worst"`;

- `run_id`: run id of the solution;

- `solution_id`: solution id;

- `value`: objective value at the observed bound.

## Details

Objective values are obtained from
[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md)
with `format = "wide"`. Objective senses are obtained from
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md).

For objectives with `sense = "min"`, the observed minimum is labelled as
`"best"` and the observed maximum is labelled as `"worst"`. For
objectives with `sense = "max"`, the observed maximum is labelled as
`"best"` and the observed minimum is labelled as `"worst"`.

Runs without a stored `solution_id` or with missing objective values for
the selected objectives are ignored automatically. Therefore, infeasible
runs are not considered in the computation.

If several solutions have the same extreme value for an objective, the
behaviour is controlled by `ties`.

## See also

[`get_objectives`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`get_objective_specs`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md),
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)

## Examples

``` r
if (FALSE) { # \dontrun{
frontier_extremes(ss)

frontier_extremes(
  ss,
  objectives = c("cost", "benefit")
)

frontier_extremes(
  ss,
  ties = "first"
)
} # }
```
