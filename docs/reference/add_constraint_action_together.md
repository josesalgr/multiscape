# Select actions together within each planning unit

Require all actions in a group to be selected together or all to remain
unselected in each scoped unit.

## Usage

``` r
add_constraint_action_together(x, actions, pu = NULL, name = NULL)
```

## Arguments

- x:

  A `Problem` with registered actions.

- actions:

  Non-empty vector of triggering action IDs or legacy
  `actions$action_set` classification labels. For excludes/together,
  this is the group of mutually exclusive or jointly selected actions
  and must resolve to at least two distinct actions. Display names and
  IDs registered with
  [`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)
  are not accepted; supply their individual members.

- pu:

  Optional vector of external planning-unit IDs. `NULL` applies the
  relation to all currently registered units.

- name:

  Optional non-empty, unique constraint label. A name is generated if
  omitted.

## Value

A new `Problem` with the relation appended and compiled caches
invalidated. The input problem is preserved.

## Details

The relation equates the binary action decisions \\x\_{i,a} = x\_{i,b}\\
for every pair of group members. This expresses both directions of
dependency; it does not require implementation of the group. Registering
an action set alone does not add this relation. Cardinality must permit
the full group if it is to be selected.

## Scope and feasibility

Relations are applied separately within every unit in `pu`. `NULL`
resolves to all currently registered units. Relations do not force any
action to be selected and do not change the registered feasible pairs or
the implicit one-action maximum. Use
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md)
to permit simultaneous actions. An action that has no feasible pair, is
locked out, or is removed because its cost is non-finite is treated as
zero. A missing required action can therefore prohibit its trigger; a
missing together member prohibits the other members. Cycles and
combinations of valid relations can make the model infeasible; the
solver determines joint feasibility, including conflicts with locks,
budgets, and cardinality. No cross-unit dependency or temporal order is
implied. Registered joint effects support concurrent economic and
ecological workflows. Benefit maximizes signed joint change; loss
minimizes final deterioration within each unit and feature. Ecological
targets count the reference once per selected unit within their action
scope.

## Repeated calls

Distinct relations accumulate in `x$data$constraints$action_relations`
and apply simultaneously. Duplicate combinations of type, action groups,
sense, and PU scope raise an error, regardless of the name. Names must
be unique across requires, excludes, and together relations. Ordering
and repeated IDs in input vectors do not change identity. Names label
constraints independently of objective aliases. To change a relation,
rebuild from the preceding problem.

## See also

[`add_constraint_action_requires()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_requires.md),
[`add_constraint_action_excludes()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_excludes.md),
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)

## Examples

``` r
base <- create_problem(
  pu = data.frame(id = 1:2, cost = 0),
  features = data.frame(id = 1L),
  dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
) |>
  add_actions(data.frame(id = c("restore", "control", "monitor")), cost = 1) |>
  add_constraint_action_cardinality(2, "max")

joint <- base |>
  add_constraint_action_together(c("restore", "control"), pu = 1L)
joint$data$constraints$action_relations
#>       type sense              name          actions requires pu
#> 1 together  <NA> action_together_1 control, restore     NULL  1
```
