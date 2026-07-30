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

- `effects`:

  Action effects by action and feature.

## Examples

``` r
toy <- get_sim_multiaction()
#> Error in get_sim_multiaction(): could not find function "get_sim_multiaction"
names(toy)
#> Error: object 'toy' not found
toy$planning_units
#> Error: object 'toy' not found
```
