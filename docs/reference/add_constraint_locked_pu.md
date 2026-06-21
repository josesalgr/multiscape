# Add locked planning units to a problem

**\[deprecated\]**

`add_constraint_locked_pu()` has been replaced by
[`add_constraint_locked_planning_units`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_planning_units.md).

## Usage

``` r
add_constraint_locked_pu(x, locked_in = NULL, locked_out = NULL)
```

## Arguments

- x:

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).

- locked_in:

  Optional locked-in specification. It may be `NULL`, a column name in
  the raw planning-unit data, a logical vector, or a vector of
  planning-unit ids.

- locked_out:

  Optional locked-out specification. It may be `NULL`, a column name in
  the raw planning-unit data, a logical vector, or a vector of
  planning-unit ids.

## Value

An updated `Problem` object in which the planning-unit table contains
logical columns `locked_in` and `locked_out`.

## See also

[`add_constraint_locked_planning_units`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_planning_units.md)
