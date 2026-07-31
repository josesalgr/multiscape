# MaPP Rwanda reserve-planning example

Derived inputs from the Rwanda training exercise developed for the
Marxan Planning Platform (MaPP). The object contains planning units, a
Human Modification Index-based cost, existing protected areas, nine
mammal distributions, four terrestrial ecoregions, and tables that
encode a single reserve action for use in package examples.

## Usage

``` r
data(rwanda_reserve)
```

## Format

A named list with six components:

- planning_units:

  An `sf` object with planning-unit identifiers, costs, areas,
  protected-area coverage, and a logical `protected` field.

- features:

  A data frame describing nine species and four ecoregions.

- feature_distribution:

  A data frame containing feature amounts, measured as intersection area
  in square metres, by planning unit.

- actions:

  A one-row data frame defining the `reserve` action.

- effects:

  A feature-level table assigning the baseline amount to the reserve
  action.

- metadata:

  Tutorial citation, target, protected-area threshold, and
  interpretation notes.

## Source

TNC (2024). *The Marxan Planning Platform: Tutorial (Rwanda)*. Global
Science, The Nature Conservancy, Arlington, Virginia, USA.
<https://marxanplanning.org>

Mammal distributions: Rondinini et al. (2011),
[doi:10.1098/rstb.2011.0113](https://doi.org/10.1098/rstb.2011.0113) .
Terrestrial ecoregions: Olson et al. (2001),
[doi:10.1641/0006-3568(2001)051\[0933:TEOTWA\]2.0.CO;2](https://doi.org/10.1641/0006-3568%282001%29051%5B0933%3ATEOTWA%5D2.0.CO%3B2)
. Human modification: Kennedy et al. (2019),
[doi:10.1111/gcb.14549](https://doi.org/10.1111/gcb.14549) , and
Theobald et al. (2020),
[doi:10.5194/essd-12-1953-2020](https://doi.org/10.5194/essd-12-1953-2020)
.

## Details

The training exercise is fictional and uses an arbitrary subset of
biodiversity features. It is provided for methodological illustration
only; solutions generated from these data should not be interpreted as
conservation recommendations for Rwanda.
