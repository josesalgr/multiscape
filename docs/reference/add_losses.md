# Add losses

Legacy convenience wrapper around
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
that retains only negative signed changes (`effect < 0`). Negative
change does not necessarily imply an ecological loss. For new code,
prefer
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
to retain signed effects of both directions. Effects can be defined only
once per problem.

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

  A `Problem` created by
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  with feasible actions already defined by
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- losses:

  Alias of `effects`, used for symmetry with
  [`add_benefits()`](https://josesalgr.github.io/multiscape/reference/add_benefits.md).

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
  `loss > 0`.

- `dist_loss`:

  A convenience table containing only the loss component.

- `losses_meta`:

  Metadata for the stored loss table.

## See also

[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md),
[`add_benefits`](https://josesalgr.github.io/multiscape/reference/add_benefits.md),
[`add_objective_min_loss`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)
