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

  A catalogue of four management strategies, with readable character
  identifiers in `id` (also provided in `name`).

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

  Data sources and preparation notes. `action_id_lookup` records the
  original numeric `source_id` and the returned character `id` for each
  action.

- maps:

  Ready-to-plot `sf` views: `costs`, `DENMINO`, `CISJUNC`, `MLE`,
  `AGRICULTURE` and `ROS`. Each view contains four strategy columns and
  geometry, so [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  displays the four action scenarios directly.

## Details

The action identifiers in `actions$id`, `action_costs$action` and
`outcomes$action` consistently use `Afforestation`, `BAU`, `FarmReturn`
and `Firesmart`. The tables can be passed directly to
[`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
and
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md),
without recoding identifiers. Scripts that explicitly select numeric
action identifiers must use these names instead. Original identifiers
remain available in `provenance$action_id_lookup`. All amounts, costs,
targets, reference values and geometries are preserved. Planning-unit
costs are retained; use `include_pu_cost = FALSE` in
[`add_objective_min_cost()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_cost.md)
to count only action implementation costs. Maps are derived when
loading, without storing additional copies of geometry in package data.
Map columns use the names in `actions$name`; rows follow
`planning_units` order, and row names contain planning-unit identifiers.

The five feature maps illustrate contrasting action scenarios (three
species and two ecosystem-service features), not ecological importance.
Missing outcome rows are displayed as zero, following the dataset
convention. These maps describe inputs under each action, not optimized
selections.

## Examples

``` r
meseta <- load_meseta()
names(meseta)
#>  [1] "planning_units" "features"       "dist_features"  "actions"       
#>  [5] "action_costs"   "outcomes"       "targets"        "boundary"      
#>  [9] "provenance"     "maps"          
meseta$actions
#>              id          name
#> 1 Afforestation Afforestation
#> 2           BAU           BAU
#> 3    FarmReturn    FarmReturn
#> 4     Firesmart     Firesmart
plot(meseta$maps$costs)

plot(meseta$maps$DENMINO)
```
