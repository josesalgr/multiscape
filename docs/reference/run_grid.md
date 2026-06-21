# Define an automatic multi-objective run grid

**\[deprecated\]**

`run_grid()` has been replaced by
[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md).

The argument `include_extremes` is deprecated and ignored. Boundary
levels are now always included.

## Usage

``` r
run_grid(n, include_extremes = TRUE)
```

## Arguments

- n:

  Integer. Resolution of the automatically generated run design. Must be
  at least `2`.

- include_extremes:

  Deprecated. Boundary levels are now always included.

## Value

An object of class `RunGrid` and `RunDesign`.

## See also

[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
