# Add objective: minimize planning-unit fragmentation

**\[deprecated\]**

`add_objective_min_fragmentation_pu()` has been replaced by
[`add_objective_min_fragmentation_planning_units`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_planning_units.md).

## Usage

``` r
add_objective_min_fragmentation_pu(
  x,
  relation_name = "boundary",
  weight_multiplier = 1,
  alias = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- relation_name:

  Character string giving the name of the spatial relation to use. The
  relation must already exist in `x$data$spatial_relations`.

- weight_multiplier:

  Numeric scalar greater than or equal to zero. Global multiplier
  applied to the relation weights when the objective is built.

- alias:

  Optional identifier used to register this objective for
  multi-objective workflows.

## Value

An updated `Problem` object.

## See also

[`add_objective_min_fragmentation_planning_units`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_planning_units.md)
