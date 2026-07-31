# Load the simulated spatial multi-action example

Load a compact, deterministic dataset for examples of multi-objective
spatial planning. The landscape contains 64 square planning units, two
spatially structured features, and two mutually exclusive candidate
actions.

## Usage

``` r
load_sim_multiaction()
```

## Value

A named list containing:

- `planning_units`:

  An `sf` object with 64 planning units.

- `features`:

  A feature catalogue.

- `dist_features`:

  Feature amounts by planning unit.

- `actions`:

  The action catalogue.

- `action_costs`:

  Action costs by planning unit and action.

- `effect_assumptions`:

  Relative-change assumptions by action and feature.

- `effects`:

  Explicit signed changes by planning unit, action, and feature.

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()
names(example_data)
#> [1] "planning_units"     "features"           "dist_features"     
#> [4] "actions"            "action_costs"       "effect_assumptions"
#> [7] "effects"           
utils::head(example_data$planning_units)
#> Simple feature collection with 6 features and 4 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 6 ymax: 1
#> CRS:           NA
#>   id                       geometry   x   y cost
#> 1  1 POLYGON ((0 0, 1 0, 1 1, 0 ... 0.5 0.5    0
#> 2  2 POLYGON ((1 0, 2 0, 2 1, 1 ... 1.5 0.5    0
#> 3  3 POLYGON ((2 0, 3 0, 3 1, 2 ... 2.5 0.5    0
#> 4  4 POLYGON ((3 0, 4 0, 4 1, 3 ... 3.5 0.5    0
#> 5  5 POLYGON ((4 0, 5 0, 5 1, 4 ... 4.5 0.5    0
#> 6  6 POLYGON ((5 0, 6 0, 6 1, 5 ... 5.5 0.5    0
```
