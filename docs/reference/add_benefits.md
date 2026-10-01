# Add benefits

Convenience wrapper around
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
that keeps only positive effects, that is, rows with `benefit > 0`.

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

  A `Problem` object created by
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  with feasible actions defined by
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- benefits:

  Alias of `effects`, kept for backwards compatibility.

- effect_type:

  Deprecated interpretation argument: `"delta"` for changes or `"after"`
  for action amounts. With historical multipliers, delta means reference
  times multiplier; after means an outcome equal to reference times
  multiplier. Omit for new table inputs.

- effect_aggregation:

  Deprecated raster aggregation argument; use `raster_aggregation`.

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
