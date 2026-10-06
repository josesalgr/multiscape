# Constrain the number of actions in each planning unit

Add a minimum, maximum, or exact count of selected individual actions in
each of the specified planning units. Multiple rules can be added across
calls, including different limits for different units or action subsets.

## Usage

``` r
add_constraint_action_cardinality(
  x,
  count,
  sense,
  actions = NULL,
  pu = NULL,
  name = NULL
)
```

## Arguments

- x:

  A `Problem` object with registered actions.

- count:

  A single finite, non-negative integer.

- sense:

  Required string: `"min"`, `"max"`, or `"equal"`.

- actions:

  Optional action subset, using the standard parser for action ids or
  existing `actions$action_set` classification labels. `NULL` counts all
  actions. Identifiers defined by
  [`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)
  are not selectable actions and are not accepted here; supply their
  individual members.

- pu:

  Optional vector of external planning-unit ids. `NULL` applies the rule
  to all currently registered units.

- name:

  Optional non-empty string used to label the constraint. If `NULL`, a
  name is generated. This label is independent of objective aliases.

## Value

A new `Problem` with the rule appended to
`x$data$constraints$action_cardinality`. Its compiled model is
invalidated; the input problem is preserved.

## Details

The constraint is applied separately to every unit in `pu`, rather than
to their combined count. For each unit it constrains the sum of binary
action-selection variables, using `>=`, `<=`, or `=` for
`sense = "min"`, `"max"`, or `"equal"`, respectively. There is no
equality tolerance because the count is an integer. Counts refer to
individual actions; registering an action set does not add another
counted decision.

By default, at most one action can be selected in each unit. An explicit
rule with `actions = NULL` and `sense = "max"` or `"equal"` replaces
that implicit limit in the units it covers. A minimum alone or a rule
restricted to an action subset does not remove the implicit limit. To
require at least two actions, also supply a total upper bound allowing
two or more.

All explicit rules are enforced together, independently of call order.
Overlapping maxima use the stricter bound; a later rule does not
overwrite an earlier one. Duplicate combinations of planning-unit
subset, action subset, and sense are rejected. Names must also be unique
within these constraints. Contradictions involving multiple rules,
budgets, or locks can still make the model infeasible; the solver
reports such infeasibility.

Only available planning-unit/action pairs are counted. Locked-out
actions and pairs with invalid costs are excluded as in model
compilation. A positive minimum or equality exceeding available actions
in any scoped unit is rejected. An empty sum is zero, so maxima and zero
bounds remain valid even in units without available actions.

Concurrent actions support costs, profits, ecological objectives, and
targets. Individual effects are additive unless a joint total is
supplied through a registered action set. Benefit maximizes signed
change; loss is split after aggregation within each unit and feature.
Targets count the reference once for selected units in their action
scope.

## See also

[`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md),
[`add_constraint_budget()`](https://josesalgr.github.io/multiscape/reference/add_constraint_budget.md)

## Examples

``` r
problem <- create_problem(
  pu = data.frame(id = c(10L, 20L, 30L), cost = 1),
  features = data.frame(id = 1L, name = "woodland"),
  dist_features = data.frame(pu = c(10L, 20L, 30L), feature = 1L, amount = 10)
) |>
  add_actions(data.frame(id = c("restore", "control", "fence", "monitor")), cost = 1)

# Different capacities: four in unit 10, two in unit 20, default one in 30.
capacities <- problem |>
  add_constraint_action_cardinality(4, "max", pu = 10L, name = "capacity_10") |>
  add_constraint_action_cardinality(2, "max", pu = 20L, name = "capacity_20")

# At least one action from this subset in each of those units.
required <- capacities |>
  add_constraint_action_cardinality(
    1, "min", actions = c("restore", "control"), pu = c(10L, 20L)
  )

# An exact total count also replaces the implicit one-action maximum.
exact <- problem |>
  add_constraint_action_cardinality(2, "equal", pu = 10L)
exact$data$constraints$action_cardinality
#>                 type count sense                 name actions pu
#> 1 action_cardinality     2 equal action_cardinality_1    NULL 10
```
