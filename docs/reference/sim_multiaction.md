# Simulated spatial multi-action planning inputs

A compact example dataset containing all inputs needed to build a
multi-objective spatial planning problem with protection and restoration
as mutually exclusive candidate actions.

## Usage

``` r
data(sim_multiaction)
```

## Format

A named list with six components:

- `planning_units`:

  An `sf` object with 64 square planning units.

- `features`:

  A data frame with two feature identifiers and names.

- `dist_features`:

  A data frame of feature amounts by planning unit.

- `actions`:

  A data frame describing protection and restoration.

- `action_costs`:

  A data frame of spatially varying action costs.

- `effects`:

  A data frame of action-specific feature multipliers.
