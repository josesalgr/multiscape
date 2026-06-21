# Set the AUGMECON multi-objective method

Configure a `Problem` object to be solved with the augmented
epsilon-constraint method (AUGMECON).

AUGMECON is an exact multi-objective optimization method in which one
objective is treated as the primary objective and the remaining
objectives are converted into \\\varepsilon\\-constraints. In the
augmented formulation, each secondary objective is associated with a
non-negative slack variable, and the primary objective is augmented with
a small reward term based on the normalized slacks. This augmentation is
used to avoid weakly efficient solutions, following Mavrotas (2009).

This function does not solve the problem directly. It stores the
AUGMECON configuration in `x$data$method`, to be used later by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Usage

``` r
set_method_augmecon(
  x,
  primary,
  aliases = NULL,
  runs = NULL,
  grid = NULL,
  n_points = NULL,
  include_extremes = NULL,
  lexicographic = TRUE,
  lexicographic_tol = 1e-09,
  augmentation = 0.001,
  slack_upper_bound = 1e+06,
  control = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- primary:

  Character string giving the alias of the primary objective, that is,
  the objective optimized directly in the AUGMECON formulation.

- aliases:

  Optional character vector of objective aliases to include in the
  method. If `NULL`, all registered objective aliases are used. The
  value of `primary` must be included in `aliases`.

- runs:

  A run design created with
  [`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  or
  [`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).
  For AUGMECON,
  [`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  requests automatic epsilon-level generation for secondary objectives,
  while
  [`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
  requires columns named `eps_<alias>` for each secondary objective.

- grid:

  Deprecated. Previous manual-grid argument. It must be a named list
  with one numeric vector per secondary objective. New code should use
  `runs = set_runs_manual(...)` instead.

- n_points:

  Deprecated. Previous automatic-grid argument. New code should use
  `runs = set_runs_grid(n = ...)` instead.

- include_extremes:

  Deprecated and ignored. Automatic run grids now always include
  boundary levels. New code should use `runs = set_runs_grid(n = ...)`.

- lexicographic:

  Logical. If `TRUE`, use lexicographic anchoring when computing extreme
  points for automatic grid construction.

- lexicographic_tol:

  Non-negative numeric tolerance used in lexicographic anchoring.

- augmentation:

  Positive numeric augmentation coefficient \\\rho\\. The effective
  coefficient of each secondary slack is computed internally as \\\rho /
  R_k\\, where \\R_k\\ is the payoff-table range of the corresponding
  secondary objective.

- slack_upper_bound:

  A single positive finite numeric value defining the upper bound of
  AUGMECON slack variables. Defaults to `1e6`.

- control:

  A control object created with
  [`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md).
  It controls how infeasible runs, runs without a solution, and
  unexpected errors are handled.

## Value

The updated `Problem` object with the AUGMECON method configuration
stored in `x$data$method`.

## Details

Use this method when one objective should be optimized directly, the
remaining objectives should be controlled through epsilon levels, and
weakly efficient solutions should be reduced through the augmented
formulation.

**General idea**

Suppose that \\m \ge 2\\ objective functions have already been
registered in the problem: \$\$ f_1(x), f_2(x), \dots, f_m(x). \$\$

AUGMECON selects one of them as the primary objective, say \\f_p(x)\\,
and treats the remaining \\m - 1\\ objectives as secondary objectives.

For a fixed combination of epsilon levels, the method solves a
single-objective subproblem of the form:

\$\$ \max \\ f_p(x) + \rho \sum\_{k \in \mathcal{S}} \frac{s_k}{R_k}
\$\$

subject to

\$\$ f_k(x) - s_k = \varepsilon_k, \qquad k \in \mathcal{S}, \$\$

\$\$ s_k \ge 0, \qquad k \in \mathcal{S}, \$\$

together with all original feasibility constraints of the planning
problem.

Here:

- \\f_p(x)\\ is the primary objective,

- \\\mathcal{S}\\ is the set of secondary objectives,

- \\\varepsilon_k\\ is the imposed level for secondary objective \\k\\,

- \\s_k\\ is a non-negative slack variable,

- \\R_k\\ is the payoff-table range used to normalize objective \\k\\,

- \\\rho \> 0\\ is a small augmentation coefficient.

In the original AUGMECON formulation of Mavrotas (2009), the
augmentation term ensures that, among solutions with the same primary
objective value, the solver prefers those with larger normalized slack,
thereby avoiding weakly efficient points and improving Pareto-front
generation.

**Secondary-objective equalities and slacks**

The key difference between standard epsilon-constraint and AUGMECON is
that the secondary objectives are written as equalities with slacks
rather than as simple inequalities. For a maximization-type secondary
objective, this takes the form:

\$\$ f_k(x) - s_k = \varepsilon_k, \qquad s_k \ge 0. \$\$

This implies: \$\$ f_k(x) \ge \varepsilon_k, \$\$

while explicitly measuring the excess above the imposed epsilon level
through \\s_k\\. The augmentation term then rewards such excess in
normalized form.

In implementation terms, the exact sign convention for each objective
depends on whether it is internally treated as a minimization or
maximization objective, but the method always preserves the same
AUGMECON principle:

- one objective is optimized directly,

- all others are turned into constrained objectives,

- non-negative slacks measure controlled deviation from the imposed
  epsilon levels,

- the primary objective is augmented with a small slack-based reward.

**Run designs**

AUGMECON runs are specified through the `runs` argument. This argument
must be created with either
[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
or
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).

`set_runs_grid(n = ...)` requests automatic generation of epsilon levels
for the secondary objectives during
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md). In
that case, the method first computes extreme points and payoff-table
ranges for the secondary objectives, and then generates `n` levels for
each one.

Boundary epsilon levels are always included in automatic grids.
Therefore, the lower and upper bounds of the automatically derived
epsilon ranges are part of the generated run design.

[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
allows users to provide explicit epsilon combinations. In manual
AUGMECON runs, each row is one optimization run and columns must be
named `eps_<alias>`, where `<alias>` is the alias of a secondary
objective. For example, if `primary = "benefit"` and
`aliases = c("benefit", "cost", "loss")`, the manual run table must
contain columns `eps_cost` and `eps_loss`.

In
[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md),
each row is used exactly as supplied. The function does not
automatically create a Cartesian product of epsilon values. If a
Cartesian product is desired, it should be created explicitly by the
user, for example with
[`expand.grid`](https://rdrr.io/r/base/expand.grid.html), and then
passed to
[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).

The older arguments `grid`, `n_points`, and `include_extremes` are
deprecated. They are still accepted for backwards compatibility and are
internally converted to
[`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
or
[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
designs. The deprecated `include_extremes` argument is ignored because
automatic run grids now always include boundary levels.

**Automatic epsilon grids**

When `runs = set_runs_grid(n = ...)` is used, the epsilon design is not
built immediately. Instead, it is constructed later during
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)
using extreme-point or payoff-table information.

For each secondary objective,
[`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
generates a sequence of epsilon levels. With multiple secondary
objectives, the final AUGMECON design is the Cartesian product of these
sequences. Therefore, the number of runs can grow quickly as the number
of secondary objectives increases.

If `lexicographic = TRUE`, extreme points are computed using
lexicographic anchoring, which can improve payoff-table quality when
objectives are tightly competing. The tolerance used for lexicographic
anchoring is controlled by `lexicographic_tol`.

**Manual epsilon runs**

Manual run designs are the most explicit way to use AUGMECON, especially
when more than two objectives are involved or when only selected epsilon
combinations should be explored.

For example, with one primary objective and two secondary objectives, a
manual run design may contain:


    data.frame(
      eps_cost = c(4, 6, 8),
      eps_loss = c(0, 1, 1)
    )

This creates three runs, not a full Cartesian grid. To create all
combinations, use
[`expand.grid()`](https://rdrr.io/r/base/expand.grid.html) before
calling
[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).

**Normalization and augmentation**

The augmentation term is scaled using the payoff-table ranges of the
secondary objectives. If \\R_k\\ denotes the range of secondary
objective \\k\\, then the effective coefficient applied to the slack is:

\$\$ \frac{\rho}{R_k}, \$\$

where \\\rho = \code{augmentation}\\.

This normalization is important because different objectives may be
measured on very different numerical scales. Without normalization, a
slack belonging to a large-scale objective could dominate the
augmentation term simply due to units.

In this implementation, the user supplies `augmentation` as the base
coefficient \\\rho\\, while the normalized slack coefficients are
computed internally at solve time using the corresponding payoff-table
ranges.

**Failure handling**

The `control` argument controls how failed runs are handled. It must be
created with
[`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md).

Some epsilon combinations may define infeasible subproblems. By default,
failed runs can be retained in the returned `SolutionSet` with missing
objective values, while feasible runs are preserved. Alternatively,
users can request that the solve stops when an infeasible run, a run
without a solution, or an unexpected error is encountered.

**AUGMECON slack upper bound**

`slack_upper_bound` defines an explicit upper bound for slack variables
introduced by the AUGMECON formulation. The value should be sufficiently
large to avoid excluding valid solutions, but unnecessarily large bounds
can weaken the mixed-integer formulation and reduce numerical
performance.

When possible, a problem-specific bound based on the ranges of the
constrained objectives should be used.

**Stored configuration**

This function stores the method definition in `x$data$method` with:

- `name = "augmecon"`,

- `type = "augmecon"`,

- the primary objective alias,

- the full set of participating aliases,

- the set of secondary aliases,

- `runs`,

- lexicographic configuration,

- `augmentation`,

- `slack_upper_bound`,

- `control`.

The actual payoff table, grid construction, and subproblem solution loop
are performed later by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## References

Mavrotas, G. (2009). Effective implementation of the
\\\varepsilon\\-constraint method in multi-objective mathematical
programming problems. *Applied Mathematics and Computation*, 213(2),
455–465.

## See also

[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md),
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md),
[`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md),
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
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
  add_objective_max_benefit(alias = "benefit") |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_min_loss(alias = "loss")

# Automatic epsilon grids generated later during solve()
x1 <- set_method_augmecon(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  runs = set_runs_grid(n = 5),
  lexicographic = TRUE,
  augmentation = 1e-3
)

x1$data$method
#> $name
#> [1] "augmecon"
#> 
#> $type
#> [1] "augmecon"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $secondary
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
#> [1] 1e-09
#> 
#> $augmentation
#> [1] 0.001
#> 
#> $slack_upper_bound
#> [1] 1e+06
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 

# Manual runs for one secondary objective
aug_runs <- data.frame(
  eps_cost = c(4, 6, 8)
)

x2 <- set_method_augmecon(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  runs = set_runs_manual(aug_runs),
  augmentation = 1e-3
)

x2$data$method
#> $name
#> [1] "augmecon"
#> 
#> $type
#> [1] "augmecon"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $secondary
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
#> [1] 1e-09
#> 
#> $augmentation
#> [1] 0.001
#> 
#> $slack_upper_bound
#> [1] 1e+06
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 

# Manual runs for two secondary objectives
aug_runs_3obj <- data.frame(
  eps_cost = c(4, 6, 8),
  eps_loss = c(0, 1, 1)
)

x3 <- set_method_augmecon(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost", "loss"),
  runs = set_runs_manual(aug_runs_3obj),
  augmentation = 1e-3
)

x3$data$method
#> $name
#> [1] "augmecon"
#> 
#> $type
#> [1] "augmecon"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"    "loss"   
#> 
#> $secondary
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
#> [1] 1e-09
#> 
#> $augmentation
#> [1] 0.001
#> 
#> $slack_upper_bound
#> [1] 1e+06
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 

# Cartesian epsilon design created explicitly by the user
aug_cartesian <- expand.grid(
  eps_cost = c(4, 6, 8),
  eps_loss = c(0, 1),
  KEEP.OUT.ATTRS = FALSE
)

x4 <- set_method_augmecon(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost", "loss"),
  runs = set_runs_manual(aug_cartesian),
  augmentation = 1e-3
)

x4$data$method
#> $name
#> [1] "augmecon"
#> 
#> $type
#> [1] "augmecon"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"    "loss"   
#> 
#> $secondary
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
#> [1] 1e-09
#> 
#> $augmentation
#> [1] 0.001
#> 
#> $slack_upper_bound
#> [1] 1e+06
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 

# Backwards-compatible deprecated usage
x5 <- set_method_augmecon(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost", "loss"),
  grid = list(
    cost = c(4, 6, 8),
    loss = c(0, 1)
  ),
  augmentation = 1e-3
)
#> Warning: `grid/n_points/include_extremes` is deprecated. Use `runs = set_runs_grid(...) or runs = set_runs_manual(...)` instead.

x5$data$method
#> $name
#> [1] "augmecon"
#> 
#> $type
#> [1] "augmecon"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"    "loss"   
#> 
#> $secondary
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
#> [1] 1e-09
#> 
#> $augmentation
#> [1] 0.001
#> 
#> $slack_upper_bound
#> [1] 1e+06
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 

# Control failure handling and the AUGMECON slack upper bound
x6 <- set_method_augmecon(
  x,
  primary = "benefit",
  aliases = c("benefit", "cost"),
  runs = set_runs_manual(data.frame(eps_cost = c(4, 6, 8))),
  augmentation = 1e-3,
  slack_upper_bound = 1e6,
  control = set_runs_control(
    stop_on_infeasible = FALSE,
    stop_on_no_solution = FALSE,
    stop_on_error = TRUE
  )
)

x6$data$method
#> $name
#> [1] "augmecon"
#> 
#> $type
#> [1] "augmecon"
#> 
#> $primary
#> [1] "benefit"
#> 
#> $aliases
#> [1] "benefit" "cost"   
#> 
#> $secondary
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
#> [1] 1e-09
#> 
#> $augmentation
#> [1] 0.001
#> 
#> $slack_upper_bound
#> [1] 1e+06
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
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 
```
