# Add losses

Convenience wrapper around
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
that keeps only negative effects, represented by rows with `loss > 0`.

## Usage

``` r
add_losses(
  x,
  losses = NULL,
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

- losses:

  Alias of `effects`, used for symmetry with
  [`add_benefits()`](https://josesalgr.github.io/multiscape/reference/add_benefits.md).

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
  `loss > 0`.

- `dist_loss`:

  A convenience table containing only the loss component.

- `losses_meta`:

  Metadata for the stored loss table.

## See also

[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md),
[`add_benefits`](https://josesalgr.github.io/multiscape/reference/add_benefits.md),
[`add_objective_min_loss`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)
