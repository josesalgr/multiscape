# Add action effects to a planning problem

Describe how feasible actions change feature amounts relative to a
user-defined reference scenario.

## Usage

``` r
add_effects(
  x,
  effects = NULL,
  effect_type = c("delta", "after"),
  effect_aggregation = c("sum", "mean"),
  component = c("any", "benefit", "loss"),
  raster_aggregation = c("sum", "mean"),
  raster_type = c("effect", "outcome")
)
```

## Arguments

- x:

  A `Problem` object created by
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  with feasible actions defined by
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- effects:

  A table with `action`, `feature`, optional `pu`, and exactly one of
  `effect`, `outcome`, or `relative_change`; a named list of action
  rasters; or `NULL` to store an empty effects table. Historical input
  formats remain supported.

- effect_type:

  Deprecated interpretation argument: `"delta"` for changes or `"after"`
  for action amounts. With historical multipliers, delta means reference
  times multiplier; after means an outcome equal to reference times
  multiplier. Omit for new table inputs.

- effect_aggregation:

  Deprecated raster aggregation argument; use `raster_aggregation`.

- component:

  Deprecated filtering argument: `"any"` retains all rows, `"benefit"`
  retains positive changes, and `"loss"` retains negative changes. New
  calls retain all components.

- raster_aggregation:

  Raster aggregation within planning units: `"sum"` (default) or
  `"mean"`.

- raster_type:

  Raster interpretation: `"effect"` (default) or `"outcome"`. Explicitly
  supply this or `raster_aggregation` to select the new raster
  interface.

## Value

An updated `Problem` containing `dist_effects` and `effects_meta`.
Existing model coefficients remain available.

## Details

The feature distribution supplied to
[`create_problem()`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
defines the reference amounts. The reference can describe current
conditions, a future without intervention, or existing management.
Action outcomes and references must share units and, for future
scenarios, the same time horizon.

**Tabular inputs**

Supply a table with `action`, `feature`, optional `pu`, and exactly one
of these numeric columns:

- `effect`: signed absolute change relative to the reference.

- `outcome`: feature amount under the action.

- `relative_change`: proportional change; 0.25 means +25 percent, zero
  means no change, and -0.25 means a 25 percent decrease.

If `pu` is omitted, each action/feature specification is expanded over
feasible planning-unit/action pairs. Actions must be defined first using
[`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md);
locked-out pairs are excluded. Features may be supplied as numeric
identifiers or names. Duplicate keys and ambiguous columns are rejected.
Values must be numeric, finite, and non-missing. Computed outcomes must
be non-negative. Missing reference amounts are zero, so relative change
cannot create an amount from a zero reference; use `effect` or `outcome`
in that case.

**Canonical representation**

For reference amount \\r\_{if}\\ and action outcome \\q\_{iaf}\\, the
signed effect is \\e\_{iaf} = q\_{iaf} - r\_{if}\\. Relative-change
inputs \\c\_{iaf}\\ are converted using \\e\_{iaf} = r\_{if} c\_{iaf}\\.
The stored table exposes `reference_amount`, `action_outcome`, and
`effect`. It also retains `amount_after` as an alias of
`action_outcome`, plus \\\mathrm{benefit} = \max(e, 0)\\ and
\\\mathrm{loss} = \max(-e, 0)\\. These components cannot both be
positive for a single triple. A positive effect denotes an increase, not
necessarily an improvement: whether increasing a feature is desirable
depends on the objective. Zero effects are retained and have an outcome
equal to the reference amount.

**Raster inputs**

Supply a named list of
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
objects, one per action. Names must match action identifiers. Each
raster must have one layer per feature, in the order of the problem's
feature catalogue; layer names do not reorder features. The problem must
contain planning-unit geometry or a planning-unit raster. Rasters are
aligned to the planning-unit raster when needed. Use
`raster_type = "effect"` for signed changes or `raster_type = "outcome"`
for feature amounts under the action. `raster_aggregation` specifies
`"sum"` or `"mean"` within each planning unit. Aggregated values must be
comparable with the reference: do not compare a mean outcome with a
reference total. Relative-change rasters are not accepted directly;
prepare a tabular relative-change specification or a raster of
effects/outcomes first.

**Compatibility with earlier versions**

Explicit legacy arguments `effect_type`, `effect_aggregation`, and
`component`, and historical `delta`, `after`, `multiplier`, `benefit`,
and `loss` inputs remain supported with their existing behavior. They
emit a lifecycle deprecation warning announcing removal in a future
release. Positional legacy arguments keep their original order. New
table inputs need no interpretation argument.

## See also

[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_benefits`](https://josesalgr.github.io/multiscape/reference/add_benefits.md),
[`add_losses`](https://josesalgr.github.io/multiscape/reference/add_losses.md)

## Examples

``` r
p <- create_problem(
  pu = data.frame(id = 1, cost = 1),
  features = data.frame(id = 1, name = "habitat"),
  dist_features = data.frame(pu = 1, feature = 1, amount = 100)
) |>
  add_actions(actions = data.frame(id = "restore"))

# Equivalent ways to specify an increase from 100 to 150.
p_effect <- add_effects(p, data.frame(
  pu = 1, action = "restore", feature = "habitat", effect = 50
))
p_outcome <- add_effects(p, data.frame(
  pu = 1, action = "restore", feature = "habitat", outcome = 150
))
p_relative <- add_effects(p, data.frame(
  action = "restore", feature = "habitat", relative_change = 0.50
))
p_effect$data$dist_effects[, c("reference_amount", "effect", "action_outcome")]
#>   reference_amount effect action_outcome
#> 1              100     50            150

# Raster example: one polygon contains two cells with reference amounts 40, 60.
r <- terra::rast(nrows = 1, ncols = 2, xmin = 0, xmax = 2,
                 ymin = 0, ymax = 1, crs = "EPSG:3857")
terra::values(r) <- c(40, 60)
names(r) <- "habitat"
polygon <- sf::st_polygon(list(matrix(
  c(0, 0, 2, 0, 2, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE
)))
pu <- sf::st_sf(id = 1L, cost = 1,
                geometry = sf::st_sfc(polygon, crs = 3857))
p_spatial <- create_problem(pu = pu, features = r, cost = "cost") |>
  add_actions(actions = data.frame(id = "restore"))
terra::values(r) <- c(20, 30)
p_raster <- add_effects(p_spatial, list(restore = r),
                       raster_type = "effect", raster_aggregation = "sum")
terra::values(r) <- c(60, 90)
p_raster_outcome <- add_effects(p_spatial, list(restore = r),
                               raster_type = "outcome", raster_aggregation = "sum")
p_raster$data$dist_effects[, c("reference_amount", "effect", "action_outcome")]
#>   reference_amount effect action_outcome
#> 1              100     50            150
```
