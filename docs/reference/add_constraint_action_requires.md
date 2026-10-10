# Require companion actions in each planning unit

Make the selection of one or more actions conditional on selecting
companion actions in the same planning unit. With `sense = "all"`, every
companion is required; with `sense = "any"`, at least one is required.

## Usage

``` r
add_constraint_action_requires(
  x,
  actions,
  requires,
  sense = c("all", "any"),
  pu = NULL,
  name = NULL
)
```

## Arguments

- x:

  A `Problem` with actions registered by
  [`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- actions:

  Non-empty vector of triggering action IDs or existing
  `actions$action_set` classification labels. For excludes and together,
  this is the group of related actions and must resolve to at least two
  distinct actions. Identifiers registered through
  [`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)
  are not selectable actions; supply their individual members.

- requires:

  Non-empty vector of companion action IDs or existing classification
  labels, disjoint from `actions`.

- sense:

  `"all"` (default) requires every companion; `"any"` requires at least
  one companion.

- pu:

  Optional external planning-unit IDs. `NULL` applies the rule to all
  planning units.

- name:

  Optional unique, non-empty constraint label. If omitted, a label is
  generated automatically.

## Value

A new `Problem` with the relation appended to
`x$data$constraints$action_relations`. The input problem is unchanged.

## Details

**How the relation works**

Suppose restoration is effective only when threat control is also
carried out. If restoration is selected, control must also be selected;
if restoration is not selected, the relation imposes no requirement.
With several triggering actions, each independently activates the
requirement.

For binary action decisions \\x\_{ia}\\, requiring all companions gives
\\x\_{ia} \le x\_{ib}\\ for each required action \\b\\. Requiring any
companion gives \\x\_{ia} \le \sum_b x\_{ib}\\. When there is only one
companion, `"all"` and `"any"` are equivalent.

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

[`add_constraint_action_excludes()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_excludes.md),
[`add_constraint_action_together()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_together.md),
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md),
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)

## Examples

``` r
# EXAMPLE 1: Create a problem where concurrent actions are possible

# Three planning units offer restoration, control, fencing, and monitoring.
# Allow up to three actions per unit: the default one-action maximum
# would otherwise prevent restoration and its companions being selected.

base <- create_problem(
  pu = data.frame(id = c(10L, 20L, 30L), cost = 0),
  features = data.frame(id = 1L, name = "habitat"),
  dist_features = data.frame(
    pu = c(10L, 20L, 30L), feature = 1L, amount = 100
  )
) |>
  add_actions(
    data.frame(id = c("restore", "control", "fence", "monitor")),
    cost = 1
  ) |>
  add_constraint_action_cardinality(3, "max")

# EXAMPLE 2: Require all companions in a specific unit

# In unit 10, restoration must be accompanied by both control and fencing.
# This is a conditional requirement: it does not force restoration.

required <- add_constraint_action_requires(
  base,
  actions = "restore",
  requires = c("control", "fence"),
  sense = "all",
  pu = 10L,
  name = "restore_with_both"
)

# EXAMPLE 3: Require at least one alternative companion

# In unit 20, either control OR fencing is sufficient for restoration.
# These rules have different PU scopes and can coexist.

required <- add_constraint_action_requires(
  required,
  actions = "restore",
  requires = c("control", "fence"),
  sense = "any",
  pu = 20L,
  name = "restore_with_either"
)

# EXAMPLE 4: Multiple independent triggers

# In unit 30, choosing either restoration or monitoring requires control.
# The triggers need not both be selected.

required <- add_constraint_action_requires(
  required,
  actions = c("restore", "monitor"),
  requires = "control",
  pu = 30L
)

# Inspect the three registered rules (not an optimised solution).
required$data$constraints$action_relations[, c("type", "sense", "name")]
#>       type sense                name
#> 1 requires   all   restore_with_both
#> 2 requires   any restore_with_either
#> 3 requires   all   action_requires_3

# EXAMPLE 5: Map where a requirement applies (no solver needed)

if (requireNamespace("sf", quietly = TRUE)) {
  sim <- load_sim_multiaction()

  # Apply the restoration-protection requirement to the first 16 cells.
  # Both actions may be selected in these cells, so permit cardinality 2.
  scoped_pu <- head(sim$planning_units$id, 16)
  spatial <- create_problem(
    pu = sim$planning_units,
    features = sim$features,
    dist_features = sim$dist_features,
    cost = "cost"
  ) |>
    add_actions(sim$actions, cost = sim$action_costs) |>
    add_constraint_action_cardinality(2, "max", pu = scoped_pu) |>
    add_constraint_action_requires(
      "restore", "protect", pu = scoped_pu
    )

  # The map shows the SCOPE of the requirement, not selected actions.
  mapped <- sim$planning_units
  mapped$requirement <- ifelse(
    mapped$id %in% scoped_pu, "Applies", "Does not apply"
  )
  plot(mapped["requirement"], main = "Restoration requires protection")
}

```
