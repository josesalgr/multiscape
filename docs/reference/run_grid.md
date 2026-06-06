# Define an automatic run grid

Create a run-design specification for automatically generating multiple
optimization runs in multi-objective methods.

The meaning of the grid depends on the method:

- in weighted-sum methods, it defines a grid of weight combinations;

- in epsilon-constraint methods, it defines epsilon levels;

- in AUGMECON, it defines epsilon levels for secondary objectives.

## Usage

``` r
run_grid(n, include_extremes = TRUE)
```

## Arguments

- n:

  Integer. Grid resolution.

- include_extremes:

  Logical. Whether to include extreme values.

## Value

An object of class `RunGrid`.
