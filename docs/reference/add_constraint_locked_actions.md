# Add locked action decisions to a planning problem

Fix feasible planning unit–action decisions to be selected or excluded.

This function modifies the status of existing feasible `(pu, action)`
pairs stored in the feasible action table. It does not create new
feasible action pairs and therefore must be used only after
[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
has been called.

## Usage

``` r
add_constraint_locked_actions(x, locked_in = NULL, locked_out = NULL)
```

## Arguments

- x:

  A `Problem` object with action feasibility already defined via
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- locked_in:

  Optional specification of feasible `(pu, action)` pairs that must be
  selected. It may be `NULL`, a `data.frame`, or a named list.

- locked_out:

  Optional specification of feasible `(pu, action)` pairs that must not
  be selected. It may be `NULL`, a `data.frame`, or a named list.

## Value

An updated `Problem` object in which the status column of the feasible
action table has been modified to reflect locked-in and locked-out
decisions.

## Details

Use this function when only specific feasible `(pu, action)` decisions
must be forced in or out of the solution, rather than whole planning
units.

Let \\\mathcal{I}\\ denote the set of planning units and \\\mathcal{A}\\
the set of actions. Let \\\mathcal{D} \subseteq \mathcal{I} \times
\mathcal{A}\\ denote the set of feasible planning unit–action pairs
already defined in the problem.

This function allows the user to define two subsets:

- \\\mathcal{D}^{in} \subseteq \mathcal{D}\\, the set of feasible pairs
  that must be selected,

- \\\mathcal{D}^{out} \subseteq \mathcal{D}\\, the set of feasible pairs
  that must not be selected.

These sets are encoded by updating the `status` column of the feasible
action table. The function validates that all requested locked-in and
locked-out pairs are already feasible. Therefore, it cannot be used to
introduce new planning unit–action combinations into the problem.

In optimization terms, if \\x\_{ia}\\ denotes the decision variable
associated with planning unit \\i\\ and action \\a\\, then:

- locked-in pairs conceptually impose \\x\_{ia} = 1\\,

- locked-out pairs conceptually impose \\x\_{ia} = 0\\.

The exact translation into solver-side constraints occurs later when the
model is built.

In contrast,
[`add_constraint_locked_pu`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_pu.md)
fixes whole planning units through the unit-selection variables, whereas
this function fixes only specific feasible `(pu, action)` decisions.

**Accepted formats**

Both `locked_in` and `locked_out` accept the same formats:

- `NULL`,

- a `data.frame` with columns `pu` and `action`, optionally including a
  `feasible` column used as a filter,

- a named list whose names are action ids and whose elements are either
  vectors of planning unit ids or `sf` objects.

If a `feasible` column is supplied in a `data.frame`, only rows with
`feasible = TRUE` are used. Missing values in `feasible` are treated as
`FALSE`.

If an `sf` specification is supplied, the problem object must contain
planning-unit geometry, and planning units are matched spatially using
[`sf::st_intersects()`](https://r-spatial.github.io/sf/reference/geos_binary_pred.html).

**Conflict checking**

Calls accumulate compatible locks and preserve omitted arguments.
Repeating the same lock is idempotent. Changing an existing locked-in
pair to locked-out, or vice versa, raises an error. To change a lock,
rebuild from the problem before it was added.

A given `(pu, action)` pair cannot be simultaneously requested in both
`locked_in` and `locked_out`. Such overlaps are rejected.

In addition, if a planning unit is already marked as locked out at the
planning-unit level, then all feasible actions in that planning unit are
forced to `status = 3`. Any attempt to lock in an action within such a
planning unit raises an error.

**Order of precedence**

User-supplied locked-in and locked-out action requests are first applied
to the feasible action table. Afterwards, any planning-unit-level
`locked_out` flag is enforced, overriding action-level status and
ensuring consistency with planning-unit exclusions.

## See also

[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_constraint_locked_pu`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_pu.md)

## Examples

``` r
# Build a small spatial planning problem with two available actions.
sim <- load_sim_multiaction()
p <- create_problem(
  pu = sim$planning_units,
  features = sim$features,
  dist_features = sim$dist_features,
  cost = "cost"
) |>
  add_actions(sim$actions, cost = sim$action_costs)

# EXAMPLE 1: Fix individual planning-unit/action decisions.
# Protection must be selected in unit 1, restoration in unit 2,
# and protection cannot be selected in unit 4.
locked <- add_constraint_locked_actions(
  p,
  locked_in = data.frame(
    pu = c(1, 2), action = c("protect", "restore")
  ),
  locked_out = data.frame(pu = 4, action = "protect")
)

# Only show modified decisions: 2 = locked in, 3 = locked out.
# All remaining feasible decisions retain status 0 (free).
subset(locked$data$dist_actions, status %in% c(2L, 3L),
       select = c(pu, action, status))
#>    pu  action status
#> 1   1 protect      2
#> 66  2 restore      2
#> 4   4 protect      3

# EXAMPLE 2: Specify the same locks using a named list.
# List names are action IDs; values are planning-unit IDs.
locked_list <- add_constraint_locked_actions(
  p,
  locked_in = list(protect = 1, restore = 2),
  locked_out = list(protect = 4)
)

# Both input formats lead to the same decision statuses.
identical(locked$data$dist_actions$status,
          locked_list$data$dist_actions$status)
#> [1] TRUE
```
