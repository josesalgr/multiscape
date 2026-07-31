# Add locked planning units to a problem

Define planning units that must be included in, or excluded from, the
optimization problem.

This function updates the planning-unit table stored in the `Problem`
object by creating or replacing the logical columns `locked_in` and
`locked_out`. These columns are later used by the model builder when
translating the problem into optimization constraints.

Lock information may be supplied either directly as logical vectors, as
vectors of planning-unit ids, or by referencing columns in the raw
planning-unit data originally passed to
[`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).

## Usage

``` r
add_constraint_locked_planning_units(x, locked_in = NULL, locked_out = NULL)
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

## Details

Use this function when whole planning units must be forced into or out
of the solution, regardless of which action may later be selected in
them.

Let \\\mathcal{I}\\ denote the set of planning units and let \\w_i \in
\\0,1\\\\ denote the binary variable indicating whether planning unit
\\i \in \mathcal{I}\\ is selected by the model.

This function defines two subsets:

- \\\mathcal{I}^{in} \subseteq \mathcal{I}\\, the planning units that
  must be included,

- \\\mathcal{I}^{out} \subseteq \mathcal{I}\\, the planning units that
  must be excluded.

Conceptually, these sets correspond to the following conditions:

- if \\i \in \mathcal{I}^{in}\\, then \\w_i = 1\\,

- if \\i \in \mathcal{I}^{out}\\, then \\w_i = 0\\.

These constraints are not imposed immediately by this function; instead,
they are stored in the planning-unit table and enforced later when
building the optimization model.

**Philosophy**

The role of
[`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
is to construct and normalize the basic inputs of the planning problem.
Locking planning units is treated as a separate modelling step so that
users can define or revise selection restrictions after the `Problem`
object has already been created.

In contrast,
[`add_constraint_locked_actions`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_actions.md)
is used to fix specific feasible `(pu, action)` decisions rather than
whole planning units.

**Supported input formats**

For both `locked_in` and `locked_out`, the function accepts:

- `NULL`, meaning that no planning units are locked on that side,

- a single character string, interpreted as a column name in the raw
  planning-unit data,

- a logical vector of length `nrow(pu)`,

- a vector of planning-unit ids.

When a column name is supplied, the referenced column is coerced to
logical. Numeric values are interpreted as non-zero = `TRUE`; character
and factor values are interpreted using common logical strings such as
`"true"`, `"t"`, `"1"`, `"yes"`, and `"y"`. Missing values are treated
as `FALSE`.

**Replacement behaviour**

Each call to `add_constraint_locked_planning_units()` replaces any
existing `locked_in` and `locked_out` columns in the planning-unit
table. In other words, the function defines the complete current set of
locked planning units; it does not merge new values with previous ones.

**Consistency checks**

The function checks that no planning unit is simultaneously assigned to
both `locked_in` and `locked_out`. If such conflicts are found, an error
is raised.

## See also

[`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md),
[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_constraint_locked_actions`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_actions.md),
[`add_constraint_locked_pu`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_pu.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

pu <- example_data$planning_units
pu$lock_col <- pu$id %in% c(1, 4)
pu$out_col <- pu$id == 5

p <- create_problem(
  pu = pu,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
)

# 1) Lock by planning-unit ids
p1 <- add_constraint_locked_planning_units(
  x = p,
  locked_in = c(1, 3),
  locked_out = c(5)
)

p1$data$pu[, c("id", "locked_in", "locked_out")]
#>    id locked_in locked_out
#> 1   1      TRUE      FALSE
#> 2   2     FALSE      FALSE
#> 3   3      TRUE      FALSE
#> 4   4     FALSE      FALSE
#> 5   5     FALSE       TRUE
#> 6   6     FALSE      FALSE
#> 7   7     FALSE      FALSE
#> 8   8     FALSE      FALSE
#> 9   9     FALSE      FALSE
#> 10 10     FALSE      FALSE
#> 11 11     FALSE      FALSE
#> 12 12     FALSE      FALSE
#> 13 13     FALSE      FALSE
#> 14 14     FALSE      FALSE
#> 15 15     FALSE      FALSE
#> 16 16     FALSE      FALSE
#> 17 17     FALSE      FALSE
#> 18 18     FALSE      FALSE
#> 19 19     FALSE      FALSE
#> 20 20     FALSE      FALSE
#> 21 21     FALSE      FALSE
#> 22 22     FALSE      FALSE
#> 23 23     FALSE      FALSE
#> 24 24     FALSE      FALSE
#> 25 25     FALSE      FALSE
#> 26 26     FALSE      FALSE
#> 27 27     FALSE      FALSE
#> 28 28     FALSE      FALSE
#> 29 29     FALSE      FALSE
#> 30 30     FALSE      FALSE
#> 31 31     FALSE      FALSE
#> 32 32     FALSE      FALSE
#> 33 33     FALSE      FALSE
#> 34 34     FALSE      FALSE
#> 35 35     FALSE      FALSE
#> 36 36     FALSE      FALSE
#> 37 37     FALSE      FALSE
#> 38 38     FALSE      FALSE
#> 39 39     FALSE      FALSE
#> 40 40     FALSE      FALSE
#> 41 41     FALSE      FALSE
#> 42 42     FALSE      FALSE
#> 43 43     FALSE      FALSE
#> 44 44     FALSE      FALSE
#> 45 45     FALSE      FALSE
#> 46 46     FALSE      FALSE
#> 47 47     FALSE      FALSE
#> 48 48     FALSE      FALSE
#> 49 49     FALSE      FALSE
#> 50 50     FALSE      FALSE
#> 51 51     FALSE      FALSE
#> 52 52     FALSE      FALSE
#> 53 53     FALSE      FALSE
#> 54 54     FALSE      FALSE
#> 55 55     FALSE      FALSE
#> 56 56     FALSE      FALSE
#> 57 57     FALSE      FALSE
#> 58 58     FALSE      FALSE
#> 59 59     FALSE      FALSE
#> 60 60     FALSE      FALSE
#> 61 61     FALSE      FALSE
#> 62 62     FALSE      FALSE
#> 63 63     FALSE      FALSE
#> 64 64     FALSE      FALSE

# 2) Read lock information from raw planning-unit data columns
p2 <- add_constraint_locked_planning_units(
  x = p,
  locked_in = "lock_col",
  locked_out = "out_col"
)

p2$data$pu[, c("id", "locked_in", "locked_out")]
#>    id locked_in locked_out
#> 1   1      TRUE      FALSE
#> 2   2     FALSE      FALSE
#> 3   3     FALSE      FALSE
#> 4   4      TRUE      FALSE
#> 5   5     FALSE       TRUE
#> 6   6     FALSE      FALSE
#> 7   7     FALSE      FALSE
#> 8   8     FALSE      FALSE
#> 9   9     FALSE      FALSE
#> 10 10     FALSE      FALSE
#> 11 11     FALSE      FALSE
#> 12 12     FALSE      FALSE
#> 13 13     FALSE      FALSE
#> 14 14     FALSE      FALSE
#> 15 15     FALSE      FALSE
#> 16 16     FALSE      FALSE
#> 17 17     FALSE      FALSE
#> 18 18     FALSE      FALSE
#> 19 19     FALSE      FALSE
#> 20 20     FALSE      FALSE
#> 21 21     FALSE      FALSE
#> 22 22     FALSE      FALSE
#> 23 23     FALSE      FALSE
#> 24 24     FALSE      FALSE
#> 25 25     FALSE      FALSE
#> 26 26     FALSE      FALSE
#> 27 27     FALSE      FALSE
#> 28 28     FALSE      FALSE
#> 29 29     FALSE      FALSE
#> 30 30     FALSE      FALSE
#> 31 31     FALSE      FALSE
#> 32 32     FALSE      FALSE
#> 33 33     FALSE      FALSE
#> 34 34     FALSE      FALSE
#> 35 35     FALSE      FALSE
#> 36 36     FALSE      FALSE
#> 37 37     FALSE      FALSE
#> 38 38     FALSE      FALSE
#> 39 39     FALSE      FALSE
#> 40 40     FALSE      FALSE
#> 41 41     FALSE      FALSE
#> 42 42     FALSE      FALSE
#> 43 43     FALSE      FALSE
#> 44 44     FALSE      FALSE
#> 45 45     FALSE      FALSE
#> 46 46     FALSE      FALSE
#> 47 47     FALSE      FALSE
#> 48 48     FALSE      FALSE
#> 49 49     FALSE      FALSE
#> 50 50     FALSE      FALSE
#> 51 51     FALSE      FALSE
#> 52 52     FALSE      FALSE
#> 53 53     FALSE      FALSE
#> 54 54     FALSE      FALSE
#> 55 55     FALSE      FALSE
#> 56 56     FALSE      FALSE
#> 57 57     FALSE      FALSE
#> 58 58     FALSE      FALSE
#> 59 59     FALSE      FALSE
#> 60 60     FALSE      FALSE
#> 61 61     FALSE      FALSE
#> 62 62     FALSE      FALSE
#> 63 63     FALSE      FALSE
#> 64 64     FALSE      FALSE

# 3) Use logical vectors
p3 <- add_constraint_locked_planning_units(
  x = p,
  locked_in = pu$id %in% c(1, 3),
  locked_out = pu$id == 4
)

p3$data$pu[, c("id", "locked_in", "locked_out")]
#>    id locked_in locked_out
#> 1   1      TRUE      FALSE
#> 2   2     FALSE      FALSE
#> 3   3      TRUE      FALSE
#> 4   4     FALSE       TRUE
#> 5   5     FALSE      FALSE
#> 6   6     FALSE      FALSE
#> 7   7     FALSE      FALSE
#> 8   8     FALSE      FALSE
#> 9   9     FALSE      FALSE
#> 10 10     FALSE      FALSE
#> 11 11     FALSE      FALSE
#> 12 12     FALSE      FALSE
#> 13 13     FALSE      FALSE
#> 14 14     FALSE      FALSE
#> 15 15     FALSE      FALSE
#> 16 16     FALSE      FALSE
#> 17 17     FALSE      FALSE
#> 18 18     FALSE      FALSE
#> 19 19     FALSE      FALSE
#> 20 20     FALSE      FALSE
#> 21 21     FALSE      FALSE
#> 22 22     FALSE      FALSE
#> 23 23     FALSE      FALSE
#> 24 24     FALSE      FALSE
#> 25 25     FALSE      FALSE
#> 26 26     FALSE      FALSE
#> 27 27     FALSE      FALSE
#> 28 28     FALSE      FALSE
#> 29 29     FALSE      FALSE
#> 30 30     FALSE      FALSE
#> 31 31     FALSE      FALSE
#> 32 32     FALSE      FALSE
#> 33 33     FALSE      FALSE
#> 34 34     FALSE      FALSE
#> 35 35     FALSE      FALSE
#> 36 36     FALSE      FALSE
#> 37 37     FALSE      FALSE
#> 38 38     FALSE      FALSE
#> 39 39     FALSE      FALSE
#> 40 40     FALSE      FALSE
#> 41 41     FALSE      FALSE
#> 42 42     FALSE      FALSE
#> 43 43     FALSE      FALSE
#> 44 44     FALSE      FALSE
#> 45 45     FALSE      FALSE
#> 46 46     FALSE      FALSE
#> 47 47     FALSE      FALSE
#> 48 48     FALSE      FALSE
#> 49 49     FALSE      FALSE
#> 50 50     FALSE      FALSE
#> 51 51     FALSE      FALSE
#> 52 52     FALSE      FALSE
#> 53 53     FALSE      FALSE
#> 54 54     FALSE      FALSE
#> 55 55     FALSE      FALSE
#> 56 56     FALSE      FALSE
#> 57 57     FALSE      FALSE
#> 58 58     FALSE      FALSE
#> 59 59     FALSE      FALSE
#> 60 60     FALSE      FALSE
#> 61 61     FALSE      FALSE
#> 62 62     FALSE      FALSE
#> 63 63     FALSE      FALSE
#> 64 64     FALSE      FALSE
```
