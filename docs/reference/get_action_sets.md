# Inspect registered action sets

Return the definitions registered by
[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)
in long format. This function inspects a planning problem, not selected
actions in a solution.

## Usage

``` r
get_action_sets(x)
```

## Arguments

- x:

  A `Problem` object.

## Value

A `data.frame` with character columns `set` and `action`, sorted by set
and action id. If no sets are registered, a zero-row table with the same
columns is returned. Internal identifiers are not exposed.

## See also

[`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md),
[`get_actions()`](https://josesalgr.github.io/multiscape/reference/get_actions.md)

## Examples

``` r
problem <- create_problem(
  pu = data.frame(id = 1:2, cost = 1),
  features = data.frame(id = 1L, name = "woodland"),
  dist_features = data.frame(pu = 1:2, feature = 1L, amount = 10)
) |>
  add_actions(data.frame(id = c("restore", "control")))

get_action_sets(problem)
#> [1] set    action
#> <0 rows> (or 0-length row.names)
problem <- add_action_sets(
  problem, list(restore_control = c("restore", "control"))
)
get_action_sets(problem)
#>               set  action
#> 1 restore_control control
#> 2 restore_control restore
```
