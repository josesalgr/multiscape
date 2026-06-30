# Define a manual multi-objective run design

**\[deprecated\]**

`run_manual()` has been replaced by
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).

## Usage

``` r
run_manual(x)
```

## Arguments

- x:

  A non-empty `data.frame` with one row per optimization run. Run-design
  columns must be named using the `weight_<alias>` or `eps_<alias>`
  convention.

## Value

An object of class `RunManual` and `RunDesign`.

## See also

[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
