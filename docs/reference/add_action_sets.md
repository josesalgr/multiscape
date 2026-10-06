# Register sets of management actions

Define named combinations of existing actions. An action can belong to
more than one set. Sets are stored separately from the individual action
catalog.

## Usage

``` r
add_action_sets(x, sets)
```

## Arguments

- x:

  A `Problem` object with registered actions.

- sets:

  A non-empty named list of action-id vectors, or a non-empty
  `data.frame` with columns `set` and `action`. Set identifiers are
  strings; members can be strings or numeric action ids. Factors are
  accepted.

## Value

A new `Problem` object containing the definitions. The input object is
not modified. Any previously compiled model is invalidated, following
the usual problem-construction workflow.

## Details

Run
[`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
first. Supply either a named list of action-id vectors or a long table
with one row per membership and columns `set` and `action`. Additional
table columns are ignored. Each set must contain at least two distinct
registered actions; duplicate memberships and nested sets are rejected.
Members are matched by action id, not by their display name.

Set identifiers cannot coincide with action ids, action display names,
or existing labels in `actions$action_set`. The latter column remains an
independent, backward-compatible action classification.

Repeated calls add new sets. Reusing a registered set identifier is an
error, including attempts to extend or redefine its membership.
Definitions are returned in a consistent order by
[`get_action_sets()`](https://josesalgr.github.io/multiscape/reference/get_action_sets.md).

Registering a set does not create a selectable action, change feasible
planning-unit/action pairs, require its members to be selected together,
or add an interaction effect. It also does not enable simultaneous
actions: the default maximum of one selected action per planning unit
still applies unless changed with
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md).
Sets may be registered even if their members have no common feasible
unit. The modern
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
interface accepts these identifiers for supplied total joint effects.
Objectives and constraints still receive individual members. Joint
effects do not make a set a separate selectable action.

## See also

[`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`get_action_sets()`](https://josesalgr.github.io/multiscape/reference/get_action_sets.md),
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md)

## Examples

``` r
problem <- create_problem(
  pu = data.frame(id = 1:2, cost = c(1, 2)),
  features = data.frame(id = 1L, name = "woodland"),
  dist_features = data.frame(
    pu = 1:2, feature = 1L, amount = c(10, 20)
  )
) |>
  add_actions(
    actions = data.frame(id = c("restore", "control", "fence")),
    cost = 1
  )

# An action may belong to several sets.
list_problem <- problem |>
  add_action_sets(list(
    restore_control = c("restore", "control"),
    restore_fence = c("restore", "fence")
  ))
get_action_sets(list_problem)
#>               set  action
#> 1 restore_control control
#> 2 restore_control restore
#> 3   restore_fence   fence
#> 4   restore_fence restore

# Equivalent definitions in long-table format.
memberships <- data.frame(
  set = c("restore_control", "restore_control", "restore_fence", "restore_fence"),
  action = c("restore", "control", "restore", "fence")
)
table_problem <- add_action_sets(problem, memberships)
identical(get_action_sets(list_problem), get_action_sets(table_problem))
#> [1] TRUE

# Add another set without changing existing definitions.
table_problem <- table_problem |>
  add_action_sets(list(control_fence = c("control", "fence")))
get_action_sets(table_problem)
#>               set  action
#> 1   control_fence control
#> 2   control_fence   fence
#> 3 restore_control control
#> 4 restore_control restore
#> 5   restore_fence   fence
#> 6   restore_fence restore
```
