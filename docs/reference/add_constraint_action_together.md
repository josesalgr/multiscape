# Select actions together within each planning unit

Link a group of actions so that, in each specified planning unit, either
all are selected or none are selected.

## Usage

``` r
add_constraint_action_together(x, actions, pu = NULL, name = NULL)
```

## Arguments

- x:

  A `Problem` with actions registered by
  [`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- actions:

  At least two action IDs or existing classification labels that must be
  selected together or omitted together in each scoped unit.

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

Suppose restoration and threat control must be implemented as one
package. This relation requires both actions whenever either is
selected. It does **not** require either action to be selected in the
first place.

The binary decisions satisfy \\x\_{ia} = x\_{ib}\\ for all members of
the group. Unlike
[`add_constraint_action_requires()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_requires.md),
dependency is bidirectional. Unlike
[`add_constraint_action_excludes()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_excludes.md),
simultaneous selection is permitted and, when the group is used,
required.

Cardinality must allow all members to be selected. Registering a set
with
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)
specifies a possible combination for joint effects; it does not itself
impose the together relation.

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
[`add_constraint_action_excludes()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_excludes.md),
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md),
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)

## Examples

``` r
# EXAMPLE 1: Require restoration and control to occur together

# In planning unit 1, restoration and control must be selected together
# or both omitted. Monitoring remains independently selectable.
# Allow two simultaneous actions in unit 1; elsewhere the default
# maximum of one action still applies.

base <- create_problem(
  pu = data.frame(id = 1:2, cost = 0),
  features = data.frame(id = 1L, name = "habitat"),
  dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
) |>
  add_actions(
    data.frame(id = c("restore", "control", "monitor")), cost = 1
  ) |>
  add_constraint_action_cardinality(2, "max", pu = 1L)

together <- add_constraint_action_together(
  base,
  actions = c("restore", "control"),
  pu = 1L,
  name = "restoration_package"
)

# Inspect the registered requirement; no solver has been run.
together$data$constraints$action_relations[, c("type", "name")]
#>       type                name
#> 1 together restoration_package

# EXAMPLE 2: Extend the package to three actions

# All three must be selected or omitted as a group. The cardinality
# upper bound must now allow three actions in the scoped unit.

extended <- create_problem(
  pu = data.frame(id = 1L, cost = 0),
  features = data.frame(id = 1L, name = "habitat"),
  dist_features = data.frame(pu = 1L, feature = 1L, amount = 100)
) |>
  add_actions(
    data.frame(id = c("restore", "control", "monitor")), cost = 1
  ) |>
  add_constraint_action_cardinality(3, "max") |>
  add_constraint_action_together(c("restore", "control", "monitor"))
```
