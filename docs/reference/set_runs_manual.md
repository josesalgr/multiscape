# Define a manual multi-objective run design

Create an explicit run-design specification in which each row defines
one multi-objective optimization run.

`set_runs_manual()` is used when exact objective weights or epsilon
levels should be supplied by the user instead of being generated
automatically with
[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md).

## Usage

``` r
set_runs_manual(x)
```

## Arguments

- x:

  A non-empty `data.frame` with one row per optimization run. Run-design
  columns must be named using the `weight_<alias>` or `eps_<alias>`
  convention.

## Value

An object of class `RunManual` and `RunDesign` containing the validated
run table.

## Details

The input must be a non-empty `data.frame` with one row per requested
optimization run.

Weighted-sum columns must follow the convention:


    weight_<alias>

Epsilon-constraint and AUGMECON columns must follow the convention:


    eps_<alias>

A manual design must contain at least one column beginning with
`weight_` or `eps_`. Mixing both column families in the same design is
not allowed.

All run-design columns must be numeric, finite, and free of missing
values. Weight columns must contain non-negative values, and each
weighted-sum row must assign a strictly positive total weight.

This function performs method-independent structural validation.
Method-specific validation is performed later by the corresponding
`set_method_*()` function. This includes checking:

- that all required objective aliases are represented;

- that no unknown objective columns are supplied;

- that epsilon columns correspond only to secondary objectives;

- and that the supplied design is compatible with the selected method.

Therefore, an object may be structurally valid for `set_runs_manual()`
but rejected later by
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
or
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md).

## See also

[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md),
[`set_method_weighted_sum`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md),
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)

## Examples

``` r
weighted_runs <- set_runs_manual(
  data.frame(
    weight_cost = c(1.0, 0.5, 0.0),
    weight_benefit = c(0.0, 0.5, 1.0)
  )
)

epsilon_runs <- set_runs_manual(
  data.frame(
    eps_benefit = c(2, 4, 6, 8)
  )
)

weighted_runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   weight_cost weight_benefit
#> 1         1.0            0.0
#> 2         0.5            0.5
#> 3         0.0            1.0
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
epsilon_runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   eps_benefit
#> 1           2
#> 2           4
#> 3           6
#> 4           8
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
```
