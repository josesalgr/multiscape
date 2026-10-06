# Logical relations between management actions

Cardinality controls how many actions can be selected. Logical relations
control which combinations are permitted **within each planning unit**.
They constrain existing individual decisions without adding selectable
sets or changing costs, profit, or effects.

| Function | Meaning in each scoped unit |
|:---|:---|
| `add_constraint_action_requires(x, actions, requires, sense = "all", pu = NULL, name = NULL)` | Each selected trigger requires every companion. |
| `add_constraint_action_requires(..., sense = "any")` | Each selected trigger requires at least one companion. |
| `add_constraint_action_excludes(x, actions, pu = NULL, name = NULL)` | At most one group member can be selected. |
| `add_constraint_action_together(x, actions, pu = NULL, name = NULL)` | All group members are selected or none are. |

All three allow the scoped actions to remain unselected. They express
neither temporal order nor dependencies between different units. `name`
is an optional constraint label, independent of objective aliases used
by MO methods.

## Define a common base

``` r
base <- create_problem(
  pu = data.frame(id = c(10L, 20L), cost = 5),
  features = data.frame(id = 1L, name = "woodland"),
  dist_features = data.frame(pu = c(10L, 20L), feature = 1L, amount = 100)
) |>
  add_actions(
    data.frame(id = c("restore", "control", "fence", "monitor")), cost = 1
  ) |>
  add_constraint_action_cardinality(3, "max")
```

The total maximum explicitly permits three simultaneous actions in both
units. Logical relations alone retain the implicit maximum of one. With
that default, a two-action together group cannot be selected, and a
trigger requiring another action cannot be selected either. Actions
outside those groups remain possible. Subset maxima and minima do not
lift the default total maximum.

## Require all or any companions

``` r
dependencies <- base |>
  add_constraint_action_requires(
    "restore", c("control", "monitor"), pu = 10L, name = "restore_requirements"
  ) |>
  add_constraint_action_requires(
    "restore", c("control", "fence"), sense = "any", pu = 20L,
    name = "alternative_protection"
  )
dependencies$data$constraints$action_relations
#>       type sense                   name actions         requires pu
#> 1 requires   all   restore_requirements restore control, monitor 10
#> 2 requires   any alternative_protection restore   control, fence 20
```

In unit 10, restoration needs **both** control and monitoring. In unit
20, it needs **either** control or fencing (both also satisfy an any
dependency). Selecting a companion alone does not force restoration.

For binary decision \\x\_{i,a}\\, all requires \\x\_{i,a} \le x\_{i,b}\\
for each companion \\b\\. Any requires \\x\_{i,a} \le \sum_b x\_{i,b}\\.
If `actions` contains several triggers, **each trigger independently**
obeys the relation; the model does not wait for the entire triggering
group to be selected. Triggering and required groups must be disjoint.

## Exclude alternatives or implement a group together

``` r
exclusive <- base |>
  add_constraint_action_excludes(c("control", "fence"), name = "protection_choice")

joint <- base |>
  add_constraint_action_together(c("restore", "control"), pu = 10L,
                                 name = "joint_implementation")
```

Excludes imposes \\\sum\_{a \in A}x\_{i,a} \le 1\\. For three or more
members, every pair is incompatible, rather than just forbidding the
complete group. Together equates all member decisions: selecting any
member selects every other member, while selecting none remains valid.
Other actions can accompany the group if cardinality and other
constraints permit it.

## Use registered action-set members explicitly

``` r
sets <- base |>
  add_action_sets(data.frame(
    set = c("restore_control", "restore_control"),
    action = c("restore", "control")
  ))
membership <- get_action_sets(sets)
members <- membership$action[membership$set == "restore_control"]
sets_joint <- add_constraint_action_together(sets, members)
```

Registering a set alone does not impose a relation. These functions
accept individual action IDs (or legacy `actions$action_set`
classification labels); registered set IDs and display names are not
resolved as decisions.

## Scope, unavailable actions, and repeated calls

`pu = NULL` resolves to all current external PU IDs. A vector such as
`pu = c(10L, 20L)` applies the rule separately in both units. A
companion in another unit cannot satisfy a dependency.

A missing feasible pair, locked-out action, or action removed for a
non-finite cost is treated as a zero decision. In an all dependency, one
unavailable companion prevents its trigger. In an any dependency, the
remaining companions can satisfy it; if none are available, the trigger
is prevented. In a together group, an unavailable member prevents every
other member. Excludes simply restricts the remaining members.

Distinct relations accumulate. Their identity includes type, action
groups, all/any sense, and PU scope; order and repeated input IDs do not
matter. With one companion, all and any have identical identity.
Duplicate identities raise an error even with a different name, and
names must be unique across the three relation functions. To compare
different specifications, derive each from the common base before adding
that relation.

Cycles are allowed. For example, A requires B and B requires A imply
joint selection. Combining this with an A/B exclusion prohibits both;
locking A in then makes the model infeasible. The solver determines
joint feasibility with locks, budgets, cardinality, and all other
constraints.

## Solve an economic example

This example uses independent action profits. For concurrent ecological
effects, see the [joint-effects
vignette](https://josesalgr.github.io/multiscape/articles/Joint_effects.md).
Restoring requires control; their combined profit is 7, compared with
fencing alone at 6. The two-action capacity prevents adding fencing to
the restoration group.

``` r
economic <- create_problem(
  pu = data.frame(id = 10L, cost = 5),
  features = data.frame(id = 1L, name = "woodland"),
  dist_features = data.frame(pu = 10L, feature = 1L, amount = 100)
) |>
  add_actions(data.frame(id = c("restore", "control", "fence")), cost = 1) |>
  add_constraint_action_cardinality(2, "max") |>
  add_constraint_action_requires("restore", "control") |>
  add_profit(c(restore = 8, control = -1, fence = 6)) |>
  add_objective_max_profit(alias = "profit") |>
  set_solver_cbc(gap_limit = 0, verbose = FALSE)
```

``` r
solution <- solve(economic)
get_actions(solution)
#>   solution_id pu  action cost status action_area selected
#> 1           1 10 control    1      0          NA        1
#> 2           1 10   fence    1      0          NA        0
#> 3           1 10 restore    1      0          NA        1
get_objectives(solution)
#>   solution_id profit
#> 1           1      7
stopifnot(get_objectives(solution)$profit == 7)
```

The negative profit of control remains included when restoration is
selected. Planning-unit implementation cost is counted once even when
several actions are selected; action costs are counted for each selected
action.

These relations also constrain the common feasible set used by
weighted-sum, epsilon-constraint, and AUGMECON methods. Objective
definitions, aliases, and method signatures are unchanged. For example,
add a cost objective to the economic base and choose a profit threshold:

``` r
mo <- economic |>
  add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
  set_method_epsilon_constraint(
    primary = "cost", aliases = c("cost", "profit"),
    runs = set_runs_manual(data.frame(eps_profit = 7))
  )
```

``` r
mo_solution <- solve(mo)
#> Warning: The minimum-cost problem has no feature targets, positive
#> minimum/equality area or action-count constraint, or locked-in decisions. The
#> all-zero solution may therefore be optimal. Add a selection requirement if an
#> empty solution is not intended.
get_objectives(mo_solution)
#>   solution_id cost profit
#> 1           1    2      7
stopifnot(get_objectives(mo_solution)$profit == 7,
          get_objectives(mo_solution)$cost == 2)
```

Logical coupling does not specify an ecological synergy or antagonism.
Supply joint totals through
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
to express interactions. Benefit maximizes signed joint change, loss
minimizes final deterioration per unit and feature, and targets count
the reference once; see the [joint-effects
vignette](https://josesalgr.github.io/multiscape/articles/Joint_effects.md).
