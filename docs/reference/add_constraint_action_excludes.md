# Make actions mutually exclusive within each planning unit

Prevent two or more incompatible actions from being selected together in
the same planning unit. At most one action in the specified group may be
selected; selecting none is also allowed.

## Usage

``` r
add_constraint_action_excludes(x, actions, pu = NULL, name = NULL)
```

## Arguments

- x:

  A `Problem` with actions registered by
  [`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- actions:

  At least two action IDs or existing classification labels that must be
  mutually exclusive in each scoped planning unit.

- pu:

  Optional external planning-unit IDs. `NULL` applies the rule to all
  planning units.

- name:

  Optional unique, non-empty constraint label. If omitted, a label is
  generated automatically.

## Value

A new `Problem` with the relation appended. The input problem is
unchanged.

## Details

**How the relation works**

Suppose restoration and harvesting are incompatible uses of a site. This
relation prevents their simultaneous selection without prohibiting
either action individually. With three or more actions, **every pair in
the group** is mutually exclusive, not just the complete combination.

For every scoped unit, the constraint is \\\sum\_{a \in A} x\_{ia} \le
1\\. Actions outside the group are not restricted by this relation. The
rule is most informative when the cardinality settings otherwise permit
more than one action per unit.

## Scope and feasibility

Each relation applies separately within each unit specified by `pu`;
`pu = NULL` applies it to all registered planning units. Relations do
not select actions by themselves or make unavailable actions feasible.
**By default, at most one action can be selected per planning unit.**
Use
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md)
when a requires or together rule needs simultaneous selections.
Unavailable or locked-out actions are treated as unselected: missing
companions may prohibit a trigger, and a missing together member may
prohibit the other members. Combined rules, budgets, and locks can also
make a model infeasible.

Relations do not imply a temporal sequence or dependencies between
different planning units. They can be combined with joint effects
registered through
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md),
but defining a joint effect does not itself require actions to be
selected together.

## Repeated calls

Distinct rules accumulate and are enforced simultaneously. Duplicate
rules with the same type, action groups, sense, and PU scope are
rejected; names must be unique across requires, excludes, and together
relations. To revise a rule, start from the problem before that rule was
added.

## See also

[`add_constraint_action_requires()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_requires.md),
[`add_constraint_action_together()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_together.md),
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md)

## Examples

``` r
# EXAMPLE 1: Allow multiple actions, but exclude an incompatible pair

# Up to three actions may be selected per unit. Restoration and harvesting
# are incompatible, while threat control can accompany either one.

base <- create_problem(
  pu = data.frame(id = 1:2, cost = 0),
  features = data.frame(id = 1L, name = "habitat"),
  dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
) |>
  add_actions(
    data.frame(id = c("restore", "harvest", "control", "monitor")),
    cost = 1
  ) |>
  add_constraint_action_cardinality(3, "max")

exclusive <- add_constraint_action_excludes(
  base,
  actions = c("restore", "harvest"),
  name = "incompatible_uses"
)

# EXAMPLE 2: Restrict the rule to selected planning units

# In unit 1, choosing any one of restoration, harvesting, or control
# precludes the other two. The same rule is not imposed in unit 2.

local <- add_constraint_action_excludes(
  base,
  actions = c("restore", "harvest", "control"),
  pu = 1L,
  name = "local_exclusion"
)

# Inspect the stored relation, not a selected management plan.
local$data$constraints$action_relations[, c("type", "name")]
#>       type            name
#> 1 excludes local_exclusion
```
