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

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).
  It must already contain feasible actions; run
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
  first.

- losses:

  Alias of `effects`, used for symmetry with
  [`add_benefits()`](https://josesalgr.github.io/multiscape/reference/add_benefits.md).

- effect_type:

  Character string indicating how supplied effect values are
  interpreted. Must be one of:

  - `"delta"`: values represent signed net changes,

  - `"after"`: values represent after-action amounts and are converted
    to net changes relative to baseline feature amounts.

- effect_aggregation:

  Character string giving the aggregation used when converting raster
  values to planning-unit level. Must be one of `"sum"` or `"mean"`.

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
