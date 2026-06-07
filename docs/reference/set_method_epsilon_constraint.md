# Set the epsilon-constraint multi-objective method

Configure a `Problem` object to be solved with the epsilon-constraint
multi-objective method.

In this method, one objective is designated as the *primary* objective
and is optimized directly, while the remaining objectives are
transformed into \\\varepsilon\\-constraints. Multiple subproblems are
generated using a run design supplied through `runs`.

This function does not solve the problem. It stores the method
configuration in `x$data$method`, to be used later by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Usage

``` r
set_method_epsilon_constraint(
  x,
  primary,
  aliases = NULL,
  runs = NULL,
  eps = NULL,
  mode = NULL,
  n_points = NULL,
  include_extremes = NULL,
  lexicographic = TRUE,
  lexicographic_tol = 1e-08,
  control = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- primary:

  Character string giving the alias of the primary objective to optimize
  directly.

- aliases:

  Optional character vector of objective aliases to include. By default,
  all registered objective aliases are used. The value of `primary` must
  be included in `aliases`.

- runs:

  A run design created with
  [`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
  or
  [`run_manual`](https://josesalgr.github.io/multiscape/reference/run_manual.md).
  For epsilon-constraint methods,
  [`run_grid()`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
  requests automatic epsilon-level generation, while
  [`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md)
  requires columns named `eps_<alias>` for each constrained objective.

- eps:

  Deprecated. Epsilon specification used by the previous
  `mode = "manual"` interface. It may be a named numeric vector or a
  named list of numeric vectors. New code should use
  `runs = run_manual(...)` instead.

- mode:

  Deprecated. Previous interface selector, either `"manual"` or
  `"auto"`. New code should use `runs = run_manual(...)` or
  `runs = run_grid(...)` instead.

- n_points:

  Deprecated. Previous automatic-grid argument. New code should use
  `runs = run_grid(n = ...)` instead.

- include_extremes:

  Deprecated. Previous automatic-grid argument. New code should use
  `runs = run_grid(n = ..., include_extremes = ...)` instead.

- lexicographic:

  Logical scalar. If `TRUE`, compute automatic-grid extreme points
  lexicographically when `runs = run_grid(...)` is used.

- lexicographic_tol:

  Numeric scalar \\\ge 0\\. Tolerance used in lexicographic
  extreme-point computation.

- control:

  A control object created with
  [`mo_control`](https://josesalgr.github.io/multiscape/reference/mo_control.md).
  It controls how infeasible runs, runs without a solution, and
  unexpected errors are handled.

## Value

An updated `Problem` object with the epsilon-constraint method
configuration stored in `x$data$method`.

## Details

Use this method when one objective should be optimized directly while
the remaining objectives are controlled through explicit performance
thresholds.

**General idea**

Suppose that \\m \ge 2\\ objective functions have already been
registered in the problem: \$\$ f_1(x), f_2(x), \dots, f_m(x). \$\$

The epsilon-constraint method selects one of them as the primary
objective, say \\f_p(x)\\, and treats the remaining objectives as
constrained objectives.

For a fixed vector of epsilon levels, the method solves subproblems in
which the primary objective is optimized directly and the remaining
objectives are imposed through epsilon constraints.

A representative formulation is:

\$\$ \max \\ f_p(x) \$\$

subject to

\$\$ f_k(x) \ge \varepsilon_k, \qquad k \in \mathcal{C}, \$\$

together with all original feasibility constraints of the planning
problem, where \\\mathcal{C}\\ is the set of constrained objectives.

Depending on the sense of each objective, the internal implementation
may transform minimization and maximization objectives into equivalent
solver-ready constrained forms. The method always follows the same
principle:

- one objective is optimized directly,

- all remaining objectives are imposed through
  \\\varepsilon\\-constraints.

By solving the problem repeatedly for different epsilon levels, the
method generates a set of trade-off solutions.

**Run designs**

Epsilon-constraint runs are specified through the `runs` argument. This
argument must be created with either
[`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
or
[`run_manual`](https://josesalgr.github.io/multiscape/reference/run_manual.md).

`run_grid(n = ...)` requests automatic generation of epsilon levels
during
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).
The epsilon levels are computed from extreme-point or payoff
information. In the current implementation,
[`run_grid()`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
for epsilon-constraint supports exactly two objectives: one primary
objective and one constrained objective.

[`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md)
allows users to provide explicit epsilon combinations. In manual
epsilon-constraint runs, each row is one optimization run and columns
must be named `eps_<alias>`, where `<alias>` is the alias of a
constrained objective. For example, if `primary = "benefit"` and
`aliases = c("benefit", "cost", "loss")`, the manual run table must
contain columns `eps_cost` and `eps_loss`.

In
[`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md),
each row is used exactly as supplied. The function does not
automatically create a Cartesian product of epsilon values. If a
Cartesian product is desired, it should be created explicitly by the
user, for example with
[`expand.grid`](https://rdrr.io/r/base/expand.grid.html), and then
passed to
[`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md).

The older arguments `eps`, `mode`, `n_points`, and `include_extremes`
are deprecated. They are still accepted for backwards compatibility and
are internally converted to
[`run_grid()`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
or
[`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md)
designs.

**Atomic objectives requirement**

The epsilon-constraint method can only be used with atomic objectives
that have already been registered under aliases. These aliases are
typically created by calling objective setters with an `alias` argument,
for example:


    x <- x |>
      add_objective_max_benefit(alias = "benefit") |>
      add_objective_min_cost(alias = "cost") |>
      add_objective_min_fragmentation(alias = "frag")

The `primary` argument selects which registered objective is optimized
directly. The remaining aliases are treated as constrained objectives.

**Automatic epsilon grids**

When `runs = run_grid(n = ...)` is used, the epsilon grid is not built
immediately. Instead, it is constructed later during
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)
using extreme-point or payoff information.

In the current implementation, automatic epsilon-grid generation
supports exactly two objectives:

- one primary objective,

- one constrained objective.

Therefore, if `runs = run_grid(...)`, then `aliases` must contain
exactly two objective aliases. Problems with three or more objectives
must use `runs = run_manual(...)`.

If `include_extremes = TRUE` is supplied inside
[`run_grid()`](https://josesalgr.github.io/multiscape/reference/run_grid.md),
the automatically generated grid includes the extreme values of the
constrained objective. Otherwise, only interior values are used.

If `lexicographic = TRUE`, the extreme points used to generate the grid
are computed lexicographically. In that case, one objective is optimized
first, and then the second objective is optimized while constraining the
first to remain within `lexicographic_tol` of its optimum.

**Manual epsilon runs**

Manual run designs support two or more objectives. They are the general
way to use the epsilon-constraint method when more than two objectives
are involved.

For example, with one primary objective and two constrained objectives,
a manual run design may contain:


    data.frame(
      eps_cost = c(4, 6, 8),
      eps_loss = c(0, 1, 1)
    )

This creates three runs, not a full Cartesian grid. To create all
combinations, use
[`expand.grid()`](https://rdrr.io/r/base/expand.grid.html) before
calling
[`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md).

**Failure handling**

The `control` argument controls how failed runs are handled. It must be
created with
[`mo_control`](https://josesalgr.github.io/multiscape/reference/mo_control.md).

Some epsilon levels may define infeasible subproblems. By default,
failed runs can be retained in the returned `SolutionSet` with missing
objective values, while feasible runs are preserved. Alternatively,
users can request that the solve stops when an infeasible run, a run
without a solution, or an unexpected error is encountered.

**Stored configuration**

The configured method stores:

- `name = "epsilon_constraint"`,

- `type = "epsilon_constraint"`,

- `primary`,

- `aliases`,

- `constrained`,

- `runs`,

- lexicographic configuration,

- `control`.

With `runs = run_grid(...)`, the actual epsilon design is generated
later during
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).
With `runs = run_manual(...)`, the explicit user-supplied run design is
stored and then used by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## See also

[`run_grid`](https://josesalgr.github.io/multiscape/reference/run_grid.md),
[`run_manual`](https://josesalgr.github.io/multiscape/reference/run_manual.md),
[`mo_control`](https://josesalgr.github.io/multiscape/reference/mo_control.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)

## Examples

``` r
# Small toy problem
pu_tbl <- data.frame(
  id = 1:4,
  cost = c(1, 2, 3, 4)
)

feat_tbl <- data.frame(
  id = 1:2,
  name = c("feature_1", "feature_2")
)

dist_feat_tbl <- data.frame(
  pu = c(1, 1, 2, 3, 4),
  feature = c(1, 2, 2, 1, 2),
  amount = c(5, 2, 3, 4, 1)
)

actions_df <- data.frame(
  id = c("conservation", "restoration"),
  name = c("conservation", "restoration")
)

effects_df <- data.frame(
  pu = c(1, 2, 3, 4, 1, 2, 3, 4),
  action = c("conservation", "conservation", "conservation", "conservation",
             "restoration", "restoration", "restoration", "restoration"),
  feature = c(1, 1, 1, 1, 2, 2, 2, 2),
  benefit = c(2, 1, 0, 1, 3, 0, 1, 2),
  loss = c(0, 0, 1, 0, 0, 1, 0, 0)
)

x <- create_problem(
  pu = pu_tbl,
  features = feat_tbl,
  dist_features = dist_feat_tbl,
  cost = "cost"
) |>
  add_actions(actions_df, cost = c(conservation = 1, restoration = 2)) |>
  add_effects(effects_df) |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_max_benefit(alias = "benefit") |>
  add_objective_min_loss(alias = "loss")

# Automatic epsilon grid for two objectives
x1 <- set_method_epsilon_constraint(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  runs = run_grid(n = 5, include_extremes = TRUE),
  lexicographic = TRUE,
  lexicographic_tol = 1e-8
)

x1$data$method
#> $name
#> [1] "epsilon_constraint"
#> 
#> $type
#> [1] "epsilon_constraint"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $constrained
#> [1] "cost"
#> 
#> $runs
#> $type
#> [1] "grid"
#> 
#> $n
#> [1] 5
#> 
#> $include_extremes
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunGrid"   "RunDesign"
#> 
#> $lexicographic
#> [1] TRUE
#> 
#> $lexicographic_tol
#> [1] 1e-08
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Manual runs with one constrained objective
eps_runs <- data.frame(
  eps_cost = c(4, 6, 8)
)

x2 <- set_method_epsilon_constraint(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  runs = run_manual(eps_runs)
)

x2$data$method
#> $name
#> [1] "epsilon_constraint"
#> 
#> $type
#> [1] "epsilon_constraint"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $constrained
#> [1] "cost"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   eps_cost
#> 1        4
#> 2        6
#> 3        8
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $lexicographic
#> [1] TRUE
#> 
#> $lexicographic_tol
#> [1] 1e-08
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Manual runs with more than two objectives
eps_runs_3obj <- data.frame(
  eps_cost = c(4, 6, 8),
  eps_loss = c(0, 1, 1)
)

x3 <- set_method_epsilon_constraint(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost", "loss"),
  runs = run_manual(eps_runs_3obj)
)

x3$data$method
#> $name
#> [1] "epsilon_constraint"
#> 
#> $type
#> [1] "epsilon_constraint"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"    "loss"   
#> 
#> $constrained
#> [1] "cost" "loss"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   eps_cost eps_loss
#> 1        4        0
#> 2        6        1
#> 3        8        1
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $lexicographic
#> [1] TRUE
#> 
#> $lexicographic_tol
#> [1] 1e-08
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Cartesian epsilon design created explicitly by the user
eps_cartesian <- expand.grid(
  eps_cost = c(4, 6, 8),
  eps_loss = c(0, 1),
  KEEP.OUT.ATTRS = FALSE
)

x4 <- set_method_epsilon_constraint(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost", "loss"),
  runs = run_manual(eps_cartesian)
)

x4$data$method
#> $name
#> [1] "epsilon_constraint"
#> 
#> $type
#> [1] "epsilon_constraint"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"    "loss"   
#> 
#> $constrained
#> [1] "cost" "loss"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   eps_cost eps_loss
#> 1        4        0
#> 2        6        0
#> 3        8        0
#> 4        4        1
#> 5        6        1
#> 6        8        1
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $lexicographic
#> [1] TRUE
#> 
#> $lexicographic_tol
#> [1] 1e-08
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Backwards-compatible deprecated usage
x5 <- set_method_epsilon_constraint(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  mode = "manual",
  eps = list(cost = c(4, 6, 8))
)
#> Warning: `eps/mode/n_points/include_extremes` is deprecated. Use `runs = run_grid(...) or runs = run_manual(...)` instead.

x5$data$method
#> $name
#> [1] "epsilon_constraint"
#> 
#> $type
#> [1] "epsilon_constraint"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $constrained
#> [1] "cost"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   run_id eps_cost
#> 1      1        4
#> 2      2        6
#> 3      3        8
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $lexicographic
#> [1] TRUE
#> 
#> $lexicographic_tol
#> [1] 1e-08
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Control failure handling
x6 <- set_method_epsilon_constraint(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  runs = run_manual(data.frame(eps_cost = c(4, 6, 8))),
  control = mo_control(
    stop_on_infeasible = FALSE,
    stop_on_no_solution = FALSE,
    stop_on_error = TRUE
  )
)

x6$data$method
#> $name
#> [1] "epsilon_constraint"
#> 
#> $type
#> [1] "epsilon_constraint"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $constrained
#> [1] "cost"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   eps_cost
#> 1        4
#> 2        6
#> 3        8
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $lexicographic
#> [1] TRUE
#> 
#> $lexicographic_tol
#> [1] 1e-08
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> $slack_upper_bound
#> [1] 1e+06
#> 
#> attr(,"class")
#> [1] "MOControl" "list"     
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
```
