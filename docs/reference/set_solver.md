# Configure solver settings

Store solver configuration inside a `Problem` object so that
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md) can
later run using the stored backend and runtime options.

This function does not build or solve the optimization model. It only
updates the solver configuration stored in `x$data$solve_args`.

## Usage

``` r
set_solver(
  x,
  solver = NULL,
  gap_limit = NULL,
  time_limit = NULL,
  solution_limit = NULL,
  cores = NULL,
  verbose = NULL,
  log_file = NULL,
  write_log = NULL,
  solver_params = list(),
  ...
)
```

## Arguments

- x:

  A `Problem` object.

- solver:

  Character string indicating the solver backend to use. Must be one of
  `"auto"`, `"gurobi"`, `"cplex"`, `"cbc"`, or `"symphony"`.

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

- solver_params:

  Named list of solver-specific parameters. These are merged with
  previously stored parameters. Rcplex parameters are validated against
  its supported control names; Rsymphony does not currently receive
  arbitrary solver-specific parameters.

- ...:

  Additional named solver-specific parameters. These are merged into
  `solver_params`. For example, `MIPFocus = 1` for Gurobi.

## Value

An updated `Problem` object with modified solver settings stored in
`x$data$solve_args`.

## Details

**Purpose**

The `multiscape` workflow separates problem specification from solver
configuration. Problem data, actions, effects, targets, objectives, and
methods are stored in the `Problem` object, and solver settings are
stored separately in `x$data$solve_args`.

This function allows solver options to be configured once and reused
later through
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)`(x)`
without repeating the same arguments each time.

**Stored fields**

The solver configuration is stored in `x$data$solve_args`. Typical
entries include:

- `solver`,

- `gap_limit`,

- `time_limit`,

- `solution_limit`,

- `cores`,

- `verbose`,

- `write_log`,

- `log_file`,

- `solver_params`.

**Single configuration**

Solver settings can be configured only once per problem, including
through backend wrappers. A second call raises an error, even if the
arguments are identical. Supply all settings together. Arguments left as
`NULL` use solver defaults. Reading defaults does not count as explicit
configuration. To compare configurations, derive each alternative from
the same problem before the first solver call.

**Gap limit**

The argument `gap_limit` is interpreted as a relative optimality gap for
mixed-integer optimization. It must lie in \\\[0,1\]\\.

If the solver stops with incumbent value \\z^{\mathrm{inc}}\\ and best
bound \\z^{\mathrm{bd}}\\, then the exact stopping rule depends on the
solver backend, but conceptually `gap_limit` controls the maximum
accepted relative difference between the incumbent and the bound.

**Time limit**

The argument `time_limit` is interpreted as a maximum wall-clock time in
seconds allowed for the solver.

**Solution limit**

The argument `solution_limit` is stored as a logical flag. Its exact
meaning depends on the backend-specific solving layer, but conceptually
it requests early termination after finding a feasible solution
according to the behaviour supported by the chosen solver.

**Cores**

The argument `cores` specifies the maximum number of solver threads. It
is supported by Gurobi. Rcplex, rcbc, and Rsymphony do not reliably
expose thread control through the interfaces used here; multiscape
therefore warns and ignores `cores` for CPLEX, CBC, and SYMPHONY. If the
requested number exceeds the number of detected logical processors, it
is capped to the detected maximum with a warning.

**Verbose output and log files**

The arguments `verbose`, `write_log`, and `log_file` control how solver
logging is handled. These options are stored and later interpreted by
the solving layer for the selected backend. Solver log files are
currently available only with Gurobi. A parameter that is not available
through the selected R solver interface is reported with a warning and
is not stored as if it had been applied.

**Backend capabilities**

Common parameters are translated only when the selected backend supports
them:

- Gurobi supports `cores`, `solution_limit`, and `write_log`.

- CBC supports `solution_limit`. Thread control and CBC log files are
  not exposed reliably through the current rcbc integration.

- CPLEX through Rcplex does not expose `cores`, `solution_limit`, or
  solver log files.

- SYMPHONY through Rsymphony supports `solution_limit`, but does not
  expose `cores` or solver log files.

**Solver-specific parameters**

Additional backend-specific parameters can be passed in two ways:

- through the named list `solver_params`,

- through additional named arguments in `...`.

These two sources are merged within the single configuration call.

This is particularly useful for backend-specific controls such as node
selection, emphasis parameters, tolerances, or heuristics.

**Supported backends**

The `solver` argument selects the backend to be used later by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).
Supported values are:

- `"auto"`: let the solving layer choose an available backend,

- `"gurobi"`,

- `"cplex"`,

- `"cbc"`,

- `"symphony"`.

This function only stores the requested backend. Availability of the
backend is checked later when solving.

## See also

[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md),
[`set_solver_gurobi`](https://josesalgr.github.io/multiscape/reference/set_solver_gurobi.md),
[`set_solver_cplex`](https://josesalgr.github.io/multiscape/reference/set_solver_cplex.md),
[`set_solver_cbc`](https://josesalgr.github.io/multiscape/reference/set_solver_cbc.md),
[`set_solver_symphony`](https://josesalgr.github.io/multiscape/reference/set_solver_symphony.md)

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

x1 <- set_solver(
  x,
  solver = "cbc",
  gap_limit = 0.01,
  time_limit = 300,
  cores = 2,
  verbose = TRUE
)
#> Warning: Parameter(s) not available for solver 'cbc' through its current R interface: cores (thread control is not available through rcbc). The unsupported setting(s) will be ignored.

x1$data$solve_args
#> $solver
#> [1] "cbc"
#> 
#> $gap_limit
#> [1] 0.01
#> 
#> $time_limit
#> [1] 300
#> 
#> $verbose
#> [1] TRUE
#> 
#> $solver_params
#> list()
#> 

# Define an alternative from the common unconfigured problem
x2 <- set_solver(
  x,
  gap_limit = 0.05,
  solver_params = list(randomSeed = 123)
)

x2$data$solve_args
#> $solver
#> [1] "auto"
#> 
#> $gap_limit
#> [1] 0.05
#> 
#> $solver_params
#> $solver_params$randomSeed
#> [1] 123
#> 
#> 
```
