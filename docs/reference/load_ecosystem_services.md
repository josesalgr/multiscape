# Load the ecosystem-services spatial example

Load the paired planning units and feature raster used by the integrated
planning vignette. This is a different landscape from both the compact
simulated example and Meseta. The vignette derives its feature catalogue
and reference amounts from the raster.

## Usage

``` r
load_ecosystem_services()
```

## Value

A named list containing:

- planning_units:

  An `sf` object with 30,496 planning units, including cost, area and
  historical lock columns.

- feature_raster:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  with four ecosystem-service layers.

## Examples

``` r
services <- load_ecosystem_services()
nrow(services$planning_units)
#> [1] 30496
names(services$feature_raster)
#> [1] "L1_control_inv" "L1_stock_inv"   "L1_rend_inv"    "L1_reten_inv"  
```
