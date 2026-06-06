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

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).
  It must already contain feasible actions; run
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
  first.

- benefits:

  Alias of `effects`, kept for backwards compatibility.

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
  `benefit > 0`.

- `dist_benefit`:

  A backwards-compatible mirror table containing only the benefit
  component.

## See also

[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md),
[`add_losses`](https://josesalgr.github.io/multiscape/reference/add_losses.md),
[`add_objective_max_benefit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md)
