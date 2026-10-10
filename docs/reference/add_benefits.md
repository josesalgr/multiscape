# Add benefits

Legacy convenience wrapper around
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
that retains only positive signed changes (`effect > 0`). Positive
change does not necessarily imply an ecological benefit. For new code,
prefer
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
to retain signed effects of both directions. Effects can be defined only
once per problem.

## Usage

``` r
add_benefits(
  x,
  benefits = NULL,
  effect_type = c("delta", "after"),
  effect_aggregation = c("sum", "mean")
)
```

## Arguments

- x:

  A `Problem` created by
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  with feasible actions already defined by
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- benefits:

  Alias of `effects`, kept for backwards compatibility.

- effect_type:

  Deprecated interpretation argument: `"delta"` for signed changes or
  `"after"` for expected amounts. Legacy multipliers retain their
  original interpretation; omit for modern tables.

- effect_aggregation:

  Deprecated raster aggregation argument; use `raster_aggregation`
  instead.

## Value

An updated `Problem` object containing:

- `dist_effects`:

  The canonical filtered effects table, containing only rows with
  `benefit > 0`.

- `dist_benefit`:

  A backwards-compatible mirror table containing only the benefit
  component.

## See also

[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md),
[`add_losses`](https://josesalgr.github.io/multiscape/reference/add_losses.md),
[`add_objective_max_benefit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md)
