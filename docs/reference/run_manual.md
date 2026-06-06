# Define a manual run design

Create a manual run-design specification. Each row represents one
optimization run. Required columns depend on the method.

For weighted-sum methods, columns must be named `weight_<alias>`. For
epsilon-constraint and AUGMECON methods, columns must be named
`eps_<alias>`.

## Usage

``` r
run_manual(x)
```

## Arguments

- x:

  A `data.frame` with one row per run.

## Value

An object of class `RunManual`.
