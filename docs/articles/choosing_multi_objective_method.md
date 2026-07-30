# Choosing a multi-objective method

## The decision comes before the method

Multi-objective optimisation is useful when no plan is best in every
respect. A plan with greater ecological benefit may also cost more, or a
compact plan may protect less of a particular feature. An MO method does
not make this conflict disappear: it expresses how trade-offs should be
handled and produces solutions that decision makers can compare.

Before choosing a method, ask:

1.  Are preferences sufficiently clear to combine the objectives?
2.  Are any objectives naturally expressed as limits, such as a budget?
3.  Is the aim to select one plan now, or to learn about trade-offs
    first?
4.  How many optimisation runs can reasonably be solved?

## A common mathematical view

Let \\\mathbf{x}\\ be a feasible spatial plan and let \\\mathcal{X}\\
contain all plans satisfying the constraints. With \\K\\ objectives:

\\ \mathbf{z}(\mathbf{x}) =
\left(z_1(\mathbf{x}),\ldots,z_K(\mathbf{x})\right), \qquad
\mathbf{x}\in\mathcal{X}. \\

Some objectives are minimised and others maximised. Below, \\g_k\\
denotes an objective converted conceptually to minimisation: \\g_k=z_k\\
for minimisation and \\g_k=-z_k\\ for maximisation. `multiscape` handles
objective senses internally.

A plan is **Pareto efficient** if no other feasible plan is at least as
good in every objective and strictly better in at least one. The
objective values of these plans form the **Pareto frontier**.

## Preferences before or after optimisation

- **A priori:** preferences enter before solving. This suits priorities,
  exchange rates, or limits that are already defensible.
- **A posteriori:** efficient alternatives are generated first and
  stakeholders choose after inspecting their consequences. This suits
  uncertain or contested preferences.

These terms describe the *workflow*, not an immutable property of an
algorithm. One weighted sum with agreed weights is a priori, but a grid
of weights can be exploratory. Epsilon-constraint is a priori with a
fixed policy threshold and a posteriori when multiple epsilon levels
trace a frontier.

## What does `lexicographic = TRUE` mean?

Before an automatic epsilon grid can be constructed, the range of each
objective must be estimated from **anchor solutions**. A simple anchor
is found by optimising one objective alone. The difficulty is that
several plans can have the same optimal value for that objective but
very different values for the others. A solver may return any of these
tied solutions, producing unstable or unnecessarily poor endpoints for
the payoff table.

Lexicographic anchoring resolves that ambiguity in two stages. For two
minimisation objectives \\g_1\\ and \\g_2\\, the anchor associated with
\\g_1\\ is computed as:

\\ g_1^\*=\min\_{\mathbf{x}\in\mathcal{X}}g_1(\mathbf{x}), \\

followed by

\\ \begin{aligned} \min\_{\mathbf{x}\in\mathcal{X}}\quad
&g_2(\mathbf{x})\\ \text{subject to}\quad &g_1(\mathbf{x})\leq
g_1^\*+\tau, \end{aligned} \\

where \\\tau\\ is `lexicographic_tol`. The roles are then reversed to
obtain the other anchor. For maximisation objectives, `multiscape`
applies the equivalent bound in the appropriate direction.

Thus, the first objective keeps strict priority; the second only breaks
ties among solutions that are optimal, or within \\\tau\\ of optimal,
for the first. This generally produces better-defined payoff-table
ranges and avoids choosing an arbitrarily poor secondary value at an
extreme.

In `multiscape`, this option is relevant to the **automatic grid
construction** used by epsilon-constraint and AUGMECON. It does not:

- change a manually supplied epsilon design;
- turn weighted sum into a lexicographic method;
- define a permanent stakeholder ranking for every frontier solution; or
- replace AUGMECON’s slack-based augmentation.

Set `lexicographic = TRUE` in most automatic-grid analyses, especially
when multiple solutions tie on an objective. Set it to `FALSE` mainly to
reduce the additional anchor solves or to reproduce non-lexicographic
endpoints. `lexicographic_tol = 0` preserves the first optimum exactly,
subject to solver numerics. A small positive tolerance can improve
numerical robustness, but it also permits the first objective to
deteriorate by that amount while the second improves. The tolerance is
expressed in the first objective’s original units, so it should be
chosen relative to its scale and the solver’s feasibility tolerance. \##
Quick choice

| Decision situation | Suggested start | Why |
|----|----|----|
| Relative preferences are defensible | Weighted sum | Directly represents weights |
| One objective is primary and others have meaningful limits | Epsilon-constraint | Keeps limits explicit |
| Preferences are unsettled and a frontier is needed | AUGMECON | Generates strongly efficient alternatives |

This is a starting point, not a rule. An analysis can use a coarse
weighted-sum exploration followed by targeted epsilon-constraint or
AUGMECON runs.

## Weighted sum: state relative preferences

\\ \min\_{\mathbf{x}\in\mathcal{X}}
\sum\_{k=1}^{K}w_k\widetilde{g}\_k(\mathbf{x}), \qquad
w_k\geq0,\quad\sum\_{k=1}^{K}w_k=1. \\

Here \\w_k\\ expresses importance and \\\widetilde{g}\_k\\ is a suitably
scaled objective. Scaling matters: an objective with numerically large
values can dominate despite a small weight. Weights are not
automatically percentages of final performance.

Use weighted sum when stakeholders can defend relative trade-offs, a few
preference scenarios suffice, or computational simplicity matters. Be
cautious when scales have not been examined, limits have legal or
physical meanings, or the frontier may be non-convex. Weighted sum can
miss efficient solutions in non-convex regions, common in discrete
spatial problems.

``` r

# Explore preferences
p_weighted <- p |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(n = 11)
  )

# Or enter agreed scenarios
weight_scenarios <- data.frame(
  weight_cost = c(0.75, 0.50, 0.25),
  weight_benefit = c(0.25, 0.50, 0.75)
)

p_weighted <- p |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_manual(weight_scenarios)
  )
```

## Epsilon-constraint: state acceptable limits

\\ \begin{aligned} \min\_{\mathbf{x}\in\mathcal{X}}\quad
&g_p(\mathbf{x})\\ \text{subject to}\quad
&g_k(\mathbf{x})\leq\epsilon_k,\qquad k\neq p. \end{aligned} \\

For a secondary objective expressed directly as maximisation, the
inequality reverses: benefit may require
\\z\_{\mathrm{benefit}}(\mathbf{x})\geq\epsilon\_{\mathrm{benefit}}\\.

Epsilon values retain concrete meanings such as maximum cost, minimum
benefit, or maximum loss. This is often clearer than saying “give cost
weight 0.63”. Use this method when one objective is primary, thresholds
have policy or ecological meaning, or non-convex frontier regions
matter. Arbitrary or infeasible epsilon values and dense grids require
care.

``` r

# A priori policy scenarios
budgets <- data.frame(eps_cost = c(2e6, 3e6, 4e6))

p_epsilon <- p |>
  set_method_epsilon_constraint(
    primary = "benefit",
    aliases = c("benefit", "cost"),
    runs = set_runs_manual(budgets)
  )

# A posteriori exploration
p_epsilon <- p |>
  set_method_epsilon_constraint(
    primary = "benefit",
    aliases = c("benefit", "cost"),
    runs = set_runs_grid(n = 11),
    lexicographic = TRUE
  )
```

An infeasible epsilon combination is useful information: the requested
guarantees cannot all be achieved simultaneously.

## AUGMECON: construct a cleaner efficient frontier

Basic epsilon-constraint can return a **weakly efficient** solution,
where a secondary objective could improve without worsening the primary
objective. AUGMECON adds slack variables to favour fuller use of epsilon
bounds. A simplified minimisation form is:

\\ \begin{aligned} \min\_{\mathbf{x},\mathbf{s}}\quad
&g_p(\mathbf{x})-\rho\sum\_{k\neq p}\frac{s_k}{R_k}\\ \text{subject
to}\quad &g_k(\mathbf{x})+s_k=\epsilon_k,\qquad k\neq p,\\ &s_k\geq0.
\end{aligned} \\

Here \\s_k\\ measures improvement beyond a limit, \\R_k\\ is the
payoff-table range, and \\\rho\>0\\ is a small augmentation coefficient.
Signs depend on the objective senses; `multiscape` constructs them
internally. Division by \\R_k\\ prevents measurement units from driving
the augmentation.

Use AUGMECON to present strongly efficient alternatives for later
discussion. Its cost is computational: with \\m\\ secondary objectives
and \\n\\ levels each, a Cartesian grid can require up to \\n^m\\ runs,
besides those needed to establish objective ranges. Start coarse and
refine only relevant regions.

``` r

p_augmecon <- p |>
  set_method_augmecon(
    primary = "benefit",
    aliases = c("benefit", "cost", "fragmentation"),
    runs = set_runs_grid(n = 5),
    lexicographic = TRUE,
    augmentation = 1e-3
  )
```

## A practical workflow

1.  **Establish objective ranges.** Solve each objective separately. The
    extremes expose redundant, incorrectly scaled, or strongly
    conflicting objectives. Automatic epsilon grids use extreme-point
    and payoff-table information during
    [`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md).
2.  **Express preferences clearly.** Use weights for meaningful relative
    compensation, epsilon bounds for meaningful guarantees, and a
    frontier when neither can yet be agreed.
3.  **Start coarse and refine.** Inspect objective values and spatial
    plans, then add manual runs around relevant regions. A visually
    attractive “knee” is not automatically the preferred plan.
4.  **Document the choice.** Report objective senses, scaling, the
    source of weights or bounds, the primary objective, run design,
    solver tolerances, failed runs, and the final selection rule.

``` r

solutions <- solve(p_augmecon)
get_objectives(solutions)
plot_tradeoff(solutions)
solutions <- solution_unique(solutions)
```

## Summary

- Choose **weighted sum** for defensible relative preferences and a
  compact, computationally simple analysis.
- Choose **epsilon-constraint** when one objective is primary and the
  others can be stated as meaningful limits.
- Choose **AUGMECON** for a systematic set of strongly efficient
  alternatives to discuss and select from later.

When uncertain, solve individual objectives, explore a coarse frontier,
and only then invest in finer preference elicitation or grid design.
