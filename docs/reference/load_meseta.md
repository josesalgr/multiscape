# Load the Meseta Iberica spatial action example

Load the complete inputs used by the introductory README tutorial. These
earlier available data support an adaptation of the Meseta case study,
not an exact reproduction of the final 2025 article.

## Usage

``` r
load_meseta()
```

## Value

A named list containing:

- planning_units:

  An `sf` object with 11,109 planning units.

- features:

  A catalogue of 155 features.

- dist_features:

  The explicit comparison reference used in the tutorial.

- actions:

  A catalogue of four management strategies.

- action_costs:

  Costs by planning unit and action.

- outcomes:

  Outcomes by planning unit, action and feature.

- targets:

  Representation targets for all features.

- boundary:

  The supplied weighted spatial relation. Replacing it with a newly
  derived boundary can change the optimization problem.

- provenance:

  Data sources and preparation notes.

## Examples

``` r
meseta <- load_meseta()
names(meseta)
#> [1] "planning_units" "features"       "dist_features"  "actions"       
#> [5] "action_costs"   "outcomes"       "targets"        "boundary"      
#> [9] "provenance"    
meseta$actions
#>   id          name
#> 1  1 Afforestation
#> 2  2           BAU
#> 3  3    FarmReturn
#> 4  4     Firesmart
```
