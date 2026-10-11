# Configure the epsilon-constraint multi-objective method

Optimise one registered objective while imposing performance thresholds
on the others. By varying these thresholds, the epsilon-constraint
method produces alternative spatial plans along an observed trade-off
frontier.

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

  A `Problem` with at least two registered objective aliases.

- primary:

  Character scalar naming the objective to optimise directly.

- aliases:

  Optional character vector of registered objective aliases. By default,
  all registered objectives are used; `primary` must be included.

- runs:

  A run design from
  [`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  or
  [`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).
  Automatic grids require exactly two objectives. Manual designs require
  `eps_<alias>` columns for all constrained objectives.

- eps, mode, n_points, include_extremes:

  Deprecated arguments from the previous interface. Use `runs` instead.
  `include_extremes` is ignored; automatic grids always include their
  endpoints.

- lexicographic:

  Logical. Whether to refine automatic-grid anchor solutions
  lexicographically; the default is `TRUE`.

- lexicographic_tol:

  Non-negative tolerance for lexicographic anchor refinement, expressed
  in the first objective's original units.

- control:

  Optional run-failure settings from
  [`set_runs_control()`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md).

## Value

An updated `Problem` with the method stored in `x$data$method`.
Run-specific epsilon bounds are constructed or read during
[`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Details

First, register at least two objectives with distinct `alias` values.
`primary` identifies the objective to optimise directly; every other
alias included in `aliases` becomes an epsilon-constrained objective.
For example, maximising woodland improvement while restricting
expenditure gives \$\$\max f\_{\mathrm{woodland}}(x)\$\$ subject to
\$\$f\_{\mathrm{cost}}(x) \le \varepsilon.\$\$ For a constrained
maximisation objective, the corresponding requirement is a lower bound,
\\f_k(x) \ge \varepsilon_k\\. Epsilon values are objective values in
their original units, not weights or relative preferences.

**Automatic grids.** `runs = set_runs_grid(n = 5)` generates five
epsilon levels, including the two endpoints, from objective
extreme-point or payoff information computed during
[`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md).
Automatic grids currently support exactly **two objectives**: one
primary and one constrained objective. With `lexicographic = TRUE`, the
anchor solutions are refined using the other objective to break
near-ties. `lexicographic_tol` controls the allowed deterioration of the
first objective during that refinement; it is expressed in that
objective's units. This option concerns automatic-grid anchors, not
every subsequent epsilon-constrained run.

**Manual thresholds.** Use `runs = set_runs_manual()` to supply explicit
bounds. Each row defines one run, with a column named `eps_<alias>` for
every constrained objective. For example, `eps_cost = 10` means *cost at
most 10*, even if the optimal plan spends less. Manual designs support
**two or more objectives**; they do not automatically expand
combinations of epsilon levels. Use
[`expand.grid()`](https://rdrr.io/r/base/expand.grid.html) to create
such a design explicitly.

**Interpreting results.** The method does not guarantee a different plan
for each epsilon level, nor does a finite grid enumerate the full Pareto
frontier. A basic epsilon-constraint formulation can also produce weakly
efficient solutions when an unconstrained secondary objective could
improve without worsening the primary objective. For augmented
tie-breaking, see
[`set_method_augmecon()`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md).
Some requested thresholds may be infeasible; use
[`set_runs_control()`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md)
to specify how unsuccessful runs are handled. The returned solution
diagnostics include checks of the epsilon bounds.

Only one multi-objective method can be configured on a `Problem`. To
compare methods or threshold designs, start again from the problem
before its method was configured. The older `eps`, `mode`, `n_points`,
and `include_extremes` arguments are deprecated; use `runs` instead.

## References

Haimes, Y. Y., Lasdon, L. S., and Wismer, D. A. (1971). On a bicriterion
formulation of the problems of integrated system identification and
system optimization. *IEEE Transactions on Systems, Man, and
Cybernetics*, SMC-1(3), 296-297.
[doi:10.1109/TSMC.1971.4308298](https://doi.org/10.1109/TSMC.1971.4308298)
.

Mavrotas, G. (2009). Effective implementation of the epsilon-constraint
method in multi-objective mathematical programming problems. *Applied
Mathematics and Computation*, 213(2), 455-465.
[doi:10.1016/j.amc.2009.03.037](https://doi.org/10.1016/j.amc.2009.03.037)
.

## See also

[`set_method_weighted_sum()`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
[`set_method_augmecon()`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md),
[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md),
[`set_runs_control()`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md),
[`get_objectives()`](https://josesalgr.github.io/multiscape/reference/get_objectives.md),
[`plot_tradeoff()`](https://josesalgr.github.io/multiscape/reference/plot_tradeoff.md),
[`plot_spatial_actions()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_actions.md),
[`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md)

## Examples

``` r
# EXAMPLE: Maximise woodland improvement under alternative cost limits.
# The landscape has 64 planning units and two candidate actions per unit.
sim <- load_sim_multiaction()

base <- create_problem(
  pu = sim$planning_units,
  features = sim$features,
  dist_features = sim$dist_features,
  cost = "cost"
) |>
  add_actions(sim$actions, cost = sim$action_costs) |>
  add_effects(sim$effect_assumptions) |>
  # Require some woodland improvement, so the low-cost plan is not empty.
  add_constraint_targets_relative(0.05, features = "woodland") |>
  add_objective_max_effect(
    features = "woodland", alias = "woodland"
  ) |>
  add_objective_min_cost(
    include_pu_cost = FALSE, alias = "cost"
  )

# Generate five cost limits automatically from the objective extremes.
epsilon <- set_method_epsilon_constraint(
  base,
  primary = "woodland",
  aliases = c("woodland", "cost"),
  runs = set_runs_grid(n = 5),
  lexicographic = TRUE
)

if (requireNamespace("rcbc", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  solutions <- solve(
    set_solver_cbc(epsilon, time_limit = 30, verbose = FALSE)
  )

  # Each run maximises woodland gain subject to its own cost ceiling.
  get_objectives(solutions, format = "wide")

  # The horizontal axis shows actual cost, not the epsilon ceiling.
  plot_tradeoff(
    solutions, objectives = c("cost", "woodland"),
    label_runs = TRUE
  )

  # Compare low-, intermediate- and high-cost spatial prescriptions.
  # Epsilon levels can sometimes produce the same selected actions.
  plot_spatial_actions(
    solutions, solutions = c(1, 3, 5), layout = "single", ncol = 3
  )
}



# ALTERNATIVE: specify explicit cost ceilings rather than a grid.
# Start from 'base', since each Problem can have only one method.
manual <- set_method_epsilon_constraint(
  base,
  primary = "woodland",
  aliases = c("woodland", "cost"),
  runs = set_runs_manual(data.frame(eps_cost = c(10, 20, 40)))
)
```
