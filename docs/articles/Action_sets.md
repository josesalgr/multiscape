# Defining sets of management actions

An action set gives a name to a combination of existing management
actions. For example, restoration and invasive-species control can be
members of `restore_control`, while the same restoration action can also
belong to `restore_fence`. The actions remain individual decisions;
membership is many-to-many.

## Register the individual actions first

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
    cost = c(restore = 2, control = 1, fence = 1)
  )

# No combinations have been registered yet.
get_action_sets(problem)
#> [1] set    action
#> <0 rows> (or 0-length row.names)
```

## Use a named list

The list names are set identifiers; each vector contains registered
action ids.

``` r

list_problem <- add_action_sets(problem, list(
  restore_control = c("restore", "control"),
  restore_fence = c("restore", "fence")
))
get_action_sets(list_problem)
#>               set  action
#> 1 restore_control control
#> 2 restore_control restore
#> 3   restore_fence   fence
#> 4   restore_fence restore
```

## Use a long table

Each row defines one membership. An action can occur in several rows as
long as it belongs to different sets.

``` r

memberships <- data.frame(
  set = c("restore_control", "restore_control", "restore_fence", "restore_fence"),
  action = c("restore", "control", "restore", "fence")
)
table_problem <- add_action_sets(problem, memberships)
get_action_sets(table_problem)
#>               set  action
#> 1 restore_control control
#> 2 restore_control restore
#> 3   restore_fence   fence
#> 4   restore_fence restore
identical(get_action_sets(list_problem), get_action_sets(table_problem))
#> [1] TRUE
```

Both formats are stored as a long table and returned in a consistent
order by
[`get_action_sets()`](https://josesalgr.github.io/multiscape/reference/get_action_sets.md).
The input problem is preserved:

``` r

get_action_sets(problem)
#> [1] set    action
#> <0 rows> (or 0-length row.names)
```

## Add further combinations

Subsequent calls add new sets without replacing existing definitions:

``` r

extended_problem <- table_problem |>
  add_action_sets(list(control_fence = c("control", "fence")))
get_action_sets(extended_problem)
#>               set  action
#> 1   control_fence control
#> 2   control_fence   fence
#> 3 restore_control control
#> 4 restore_control restore
#> 5   restore_fence   fence
#> 6   restore_fence restore
get_action_sets(table_problem)
#>               set  action
#> 1 restore_control control
#> 2 restore_control restore
#> 3   restore_fence   fence
#> 4   restore_fence restore
```

Each set must contain at least two distinct actions. A set identifier
cannot match an action id, an action display name, or an existing
`actions$action_set` classification label. Members must be action ids;
sets cannot be nested. Duplicated memberships and reusing an existing
set identifier are errors. The action catalog is fixed after its first
definition. Define a different catalog in a separate problem before
registering its sets.

## What registration means

Registering a set does not create another action, modify costs or
feasibility, impose dependencies or exclusivity, or introduce a joint
effect. The original `actions$action_set` classification is also
preserved. The same definitions can therefore describe candidate
combinations without deciding their management rules.

``` r

identical(problem$data$actions, table_problem$data$actions)
#> [1] TRUE
identical(problem$data$dist_actions, table_problem$data$dist_actions)
#> [1] TRUE
```

These remain neutral definitions. The default is still at most one
selected action per planning unit. The separate
[`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md)
function can allow concurrent actions in economic and ecological
workflows; see the [action-cardinality
vignette](https://josesalgr.github.io/multiscape/articles/Action_cardinality.md).
Modern
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
accepts set identifiers for total joint outcomes or changes; see the
[joint-effects
vignette](https://josesalgr.github.io/multiscape/articles/Joint_effects.md).
Objectives and constraints still receive individual members. Benefit
maximizes signed joint change; loss measures final deterioration per
unit and feature. Concurrent targets count the reference once.

To require selection of the members together, pass their individual IDs
to
[`add_constraint_action_together()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_together.md).
Directional dependencies and mutually exclusive alternatives use
[`add_constraint_action_requires()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_requires.md)
and
[`add_constraint_action_excludes()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_excludes.md);
see the [action-relations
vignette](https://josesalgr.github.io/multiscape/articles/Action_relations.md).
