# Configure CBC solver settings

Convenience wrapper around
[`set_solver`](https://josesalgr.github.io/multiscape/reference/set_solver.md)
that stores `solver = "cbc"` in the problem object.

This function does not solve the model. It only updates the stored
solver configuration. A solver can be configured only once per problem.
Calling this wrapper after any solver setter raises an error. Derive
alternatives from the same problem before its first solver
configuration.

## Usage

``` r
set_solver_cbc(
  x,
  ...,
  solver_params = list(),
  gap_limit = NULL,
  time_limit = NULL,
  solution_limit = NULL,
  cores = NULL,
  verbose = NULL,
  log_file = NULL,
  write_log = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- ...:

  Additional named solver-specific parameters. These are merged into
  `solver_params`. For example, `MIPFocus = 1` for Gurobi.

- solver_params:

  Named list of solver-specific parameters. These are merged with
  previously stored parameters. Rcplex parameters are validated against
  its supported control names; Rsymphony does not currently receive
  arbitrary solver-specific parameters.

- gap_limit:

  Optional numeric value in \\\[0,1\]\\ giving the relative optimality
  gap for mixed-integer optimization. If `NULL`, the previously stored
  value is kept unchanged.

- time_limit:

  Optional non-negative numeric value giving the maximum solving time in
  seconds. If `NULL`, the previously stored value is kept unchanged.

- solution_limit:

  Optional logical flag requesting early termination after a feasible
  solution is found. Supported by Gurobi, CBC, and SYMPHONY, but not by
  CPLEX through Rcplex. If `NULL`, the previously stored value is kept
  unchanged.

- cores:

  Optional positive integer giving the maximum number of solver threads.
  Currently supported by Gurobi. If `NULL`, the previously stored value
  is kept unchanged.

- verbose:

  Optional logical flag indicating whether the solver should print log
  output. If `NULL`, the previously stored value is kept unchanged.

- log_file:

  Optional character string giving the complete path or file name of the
  solver log. Currently supported by Gurobi. If `NULL`, the previously
  stored value is kept unchanged.

- write_log:

  Optional logical flag indicating whether solver output should be
  written to a file. Currently supported by Gurobi. If `NULL`, the
  previously stored value is kept unchanged.

## Value

An updated `Problem` object with CBC solver settings stored in
`x$data$solve_args`.

## See also

[`set_solver`](https://josesalgr.github.io/multiscape/reference/set_solver.md),
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

x <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
)

x <- set_solver_cbc(
  x,
  gap_limit = 0.01,
  time_limit = 300,
  cores = 2,
  solution_limit = FALSE
)
#> Warning: Parameter(s) not available for solver 'cbc' through its current R interface: cores (thread control is not available through rcbc). The unsupported setting(s) will be ignored.

x$data$solve_args
#> $solver
#> [1] "cbc"
#> 
#> $gap_limit
#> [1] 0.01
#> 
#> $time_limit
#> [1] 300
#> 
#> $solution_limit
#> [1] FALSE
#> 
#> $solver_params
#> list()
#> 
```
