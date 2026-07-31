# Add locked action decisions to a planning problem

Fix feasible planning unit–action decisions to be selected or excluded.

This function modifies the status of existing feasible `(pu, action)`
pairs stored in the feasible action table. It does not create new
feasible action pairs and therefore must be used only after
[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
has been called.

## Usage

``` r
add_constraint_locked_actions(x, locked_in = NULL, locked_out = NULL)
```

## Arguments

- x:

  A `Problem` object with action feasibility already defined via
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).

- locked_in:

  Optional specification of feasible `(pu, action)` pairs that must be
  selected. It may be `NULL`, a `data.frame`, or a named list.

- locked_out:

  Optional specification of feasible `(pu, action)` pairs that must not
  be selected. It may be `NULL`, a `data.frame`, or a named list.

## Value

An updated `Problem` object in which the status column of the feasible
action table has been modified to reflect locked-in and locked-out
decisions.

## Details

Use this function when only specific feasible `(pu, action)` decisions
must be forced in or out of the solution, rather than whole planning
units.

Let \\\mathcal{I}\\ denote the set of planning units and \\\mathcal{A}\\
the set of actions. Let \\\mathcal{D} \subseteq \mathcal{I} \times
\mathcal{A}\\ denote the set of feasible planning unit–action pairs
already defined in the problem.

This function allows the user to define two subsets:

- \\\mathcal{D}^{in} \subseteq \mathcal{D}\\, the set of feasible pairs
  that must be selected,

- \\\mathcal{D}^{out} \subseteq \mathcal{D}\\, the set of feasible pairs
  that must not be selected.

These sets are encoded by updating the `status` column of the feasible
action table. The function validates that all requested locked-in and
locked-out pairs are already feasible. Therefore, it cannot be used to
introduce new planning unit–action combinations into the problem.

In optimization terms, if \\x\_{ia}\\ denotes the decision variable
associated with planning unit \\i\\ and action \\a\\, then:

- locked-in pairs conceptually impose \\x\_{ia} = 1\\,

- locked-out pairs conceptually impose \\x\_{ia} = 0\\.

The exact translation into solver-side constraints occurs later when the
model is built.

In contrast,
[`add_constraint_locked_pu`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_pu.md)
fixes whole planning units through the unit-selection variables, whereas
this function fixes only specific feasible `(pu, action)` decisions.

**Accepted formats**

Both `locked_in` and `locked_out` accept the same formats:

- `NULL`,

- a `data.frame` with columns `pu` and `action`, optionally including a
  `feasible` column used as a filter,

- a named list whose names are action ids and whose elements are either
  vectors of planning unit ids or `sf` objects.

If a `feasible` column is supplied in a `data.frame`, only rows with
`feasible = TRUE` are used. Missing values in `feasible` are treated as
`FALSE`.

If an `sf` specification is supplied, the problem object must contain
planning-unit geometry, and planning units are matched spatially using
[`sf::st_intersects()`](https://r-spatial.github.io/sf/reference/geos_binary_pred.html).

**Conflict checking**

A given `(pu, action)` pair cannot be simultaneously requested in both
`locked_in` and `locked_out`. Such overlaps are rejected.

In addition, if a planning unit is already marked as locked out at the
planning-unit level, then all feasible actions in that planning unit are
forced to `status = 3`. Any attempt to lock in an action within such a
planning unit raises an error.

**Order of precedence**

User-supplied locked-in and locked-out action requests are first applied
to the feasible action table. Afterwards, any planning-unit-level
`locked_out` flag is enforced, overriding action-level status and
ensuring consistency with planning-unit exclusions.

## See also

[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_constraint_locked_pu`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_pu.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

p <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
) |>
  add_actions(
    example_data$actions,
    cost = example_data$action_costs
  )

# Lock a few feasible decisions
p <- add_constraint_locked_actions(
  x = p,
  locked_in = data.frame(
    pu = c(1, 2),
    action = c("protect", "restore")
  ),
  locked_out = data.frame(
    pu = c(4),
    action = c("protect")
  )
)

p$data$dist_actions
#>     pu  action cost status internal_pu internal_action action_area
#> 1    1 protect 1.05      2           1               1           1
#> 65   1 restore 2.30      0           1               2           1
#> 2    2 protect 1.15      0           2               1           1
#> 66   2 restore 2.18      2           2               2           1
#> 3    3 protect 1.25      0           3               1           1
#> 67   3 restore 2.06      0           3               2           1
#> 4    4 protect 1.35      3           4               1           1
#> 68   4 restore 1.94      0           4               2           1
#> 5    5 protect 1.45      0           5               1           1
#> 69   5 restore 1.82      0           5               2           1
#> 6    6 protect 1.55      0           6               1           1
#> 70   6 restore 1.70      0           6               2           1
#> 7    7 protect 1.65      0           7               1           1
#> 71   7 restore 1.58      0           7               2           1
#> 8    8 protect 1.75      0           8               1           1
#> 72   8 restore 1.46      0           8               2           1
#> 9    9 protect 1.05      0           9               1           1
#> 73   9 restore 2.30      0           9               2           1
#> 10  10 protect 1.15      0          10               1           1
#> 74  10 restore 2.18      0          10               2           1
#> 11  11 protect 1.25      0          11               1           1
#> 75  11 restore 2.06      0          11               2           1
#> 12  12 protect 1.35      0          12               1           1
#> 76  12 restore 1.94      0          12               2           1
#> 13  13 protect 1.45      0          13               1           1
#> 77  13 restore 1.82      0          13               2           1
#> 14  14 protect 1.55      0          14               1           1
#> 78  14 restore 1.70      0          14               2           1
#> 15  15 protect 1.65      0          15               1           1
#> 79  15 restore 1.58      0          15               2           1
#> 16  16 protect 1.75      0          16               1           1
#> 80  16 restore 1.46      0          16               2           1
#> 17  17 protect 1.05      0          17               1           1
#> 81  17 restore 2.30      0          17               2           1
#> 18  18 protect 1.15      0          18               1           1
#> 82  18 restore 2.18      0          18               2           1
#> 19  19 protect 1.25      0          19               1           1
#> 83  19 restore 2.06      0          19               2           1
#> 20  20 protect 1.35      0          20               1           1
#> 84  20 restore 1.94      0          20               2           1
#> 21  21 protect 1.45      0          21               1           1
#> 85  21 restore 1.82      0          21               2           1
#> 22  22 protect 1.55      0          22               1           1
#> 86  22 restore 1.70      0          22               2           1
#> 23  23 protect 1.65      0          23               1           1
#> 87  23 restore 1.58      0          23               2           1
#> 24  24 protect 1.75      0          24               1           1
#> 88  24 restore 1.46      0          24               2           1
#> 25  25 protect 1.05      0          25               1           1
#> 89  25 restore 2.30      0          25               2           1
#> 26  26 protect 1.15      0          26               1           1
#> 90  26 restore 2.18      0          26               2           1
#> 27  27 protect 1.25      0          27               1           1
#> 91  27 restore 2.06      0          27               2           1
#> 28  28 protect 1.35      0          28               1           1
#> 92  28 restore 1.94      0          28               2           1
#> 29  29 protect 1.45      0          29               1           1
#> 93  29 restore 1.82      0          29               2           1
#> 30  30 protect 1.55      0          30               1           1
#> 94  30 restore 1.70      0          30               2           1
#> 31  31 protect 1.65      0          31               1           1
#> 95  31 restore 1.58      0          31               2           1
#> 32  32 protect 1.75      0          32               1           1
#> 96  32 restore 1.46      0          32               2           1
#> 33  33 protect 1.05      0          33               1           1
#> 97  33 restore 2.30      0          33               2           1
#> 34  34 protect 1.15      0          34               1           1
#> 98  34 restore 2.18      0          34               2           1
#> 35  35 protect 1.25      0          35               1           1
#> 99  35 restore 2.06      0          35               2           1
#> 36  36 protect 1.35      0          36               1           1
#> 100 36 restore 1.94      0          36               2           1
#> 37  37 protect 1.45      0          37               1           1
#> 101 37 restore 1.82      0          37               2           1
#> 38  38 protect 1.55      0          38               1           1
#> 102 38 restore 1.70      0          38               2           1
#> 39  39 protect 1.65      0          39               1           1
#> 103 39 restore 1.58      0          39               2           1
#> 40  40 protect 1.75      0          40               1           1
#> 104 40 restore 1.46      0          40               2           1
#> 41  41 protect 1.05      0          41               1           1
#> 105 41 restore 2.30      0          41               2           1
#> 42  42 protect 1.15      0          42               1           1
#> 106 42 restore 2.18      0          42               2           1
#> 43  43 protect 1.25      0          43               1           1
#> 107 43 restore 2.06      0          43               2           1
#> 44  44 protect 1.35      0          44               1           1
#> 108 44 restore 1.94      0          44               2           1
#> 45  45 protect 1.45      0          45               1           1
#> 109 45 restore 1.82      0          45               2           1
#> 46  46 protect 1.55      0          46               1           1
#> 110 46 restore 1.70      0          46               2           1
#> 47  47 protect 1.65      0          47               1           1
#> 111 47 restore 1.58      0          47               2           1
#> 48  48 protect 1.75      0          48               1           1
#> 112 48 restore 1.46      0          48               2           1
#> 49  49 protect 1.05      0          49               1           1
#> 113 49 restore 2.30      0          49               2           1
#> 50  50 protect 1.15      0          50               1           1
#> 114 50 restore 2.18      0          50               2           1
#> 51  51 protect 1.25      0          51               1           1
#> 115 51 restore 2.06      0          51               2           1
#> 52  52 protect 1.35      0          52               1           1
#> 116 52 restore 1.94      0          52               2           1
#> 53  53 protect 1.45      0          53               1           1
#> 117 53 restore 1.82      0          53               2           1
#> 54  54 protect 1.55      0          54               1           1
#> 118 54 restore 1.70      0          54               2           1
#> 55  55 protect 1.65      0          55               1           1
#> 119 55 restore 1.58      0          55               2           1
#> 56  56 protect 1.75      0          56               1           1
#> 120 56 restore 1.46      0          56               2           1
#> 57  57 protect 1.05      0          57               1           1
#> 121 57 restore 2.30      0          57               2           1
#> 58  58 protect 1.15      0          58               1           1
#> 122 58 restore 2.18      0          58               2           1
#> 59  59 protect 1.25      0          59               1           1
#> 123 59 restore 2.06      0          59               2           1
#> 60  60 protect 1.35      0          60               1           1
#> 124 60 restore 1.94      0          60               2           1
#> 61  61 protect 1.45      0          61               1           1
#> 125 61 restore 1.82      0          61               2           1
#> 62  62 protect 1.55      0          62               1           1
#> 126 62 restore 1.70      0          62               2           1
#> 63  63 protect 1.65      0          63               1           1
#> 127 63 restore 1.58      0          63               2           1
#> 64  64 protect 1.75      0          64               1           1
#> 128 64 restore 1.46      0          64               2           1

# Named-list interface
p2 <- add_constraint_locked_actions(
  x = p,
  locked_in = list(
    protect = c(1, 3)
  ),
  locked_out = list(
    restore = c(2)
  )
)

p2$data$dist_actions
#>     pu  action cost status internal_pu internal_action action_area
#> 1    1 protect 1.05      2           1               1           1
#> 65   1 restore 2.30      0           1               2           1
#> 2    2 protect 1.15      0           2               1           1
#> 66   2 restore 2.18      3           2               2           1
#> 3    3 protect 1.25      2           3               1           1
#> 67   3 restore 2.06      0           3               2           1
#> 4    4 protect 1.35      3           4               1           1
#> 68   4 restore 1.94      0           4               2           1
#> 5    5 protect 1.45      0           5               1           1
#> 69   5 restore 1.82      0           5               2           1
#> 6    6 protect 1.55      0           6               1           1
#> 70   6 restore 1.70      0           6               2           1
#> 7    7 protect 1.65      0           7               1           1
#> 71   7 restore 1.58      0           7               2           1
#> 8    8 protect 1.75      0           8               1           1
#> 72   8 restore 1.46      0           8               2           1
#> 9    9 protect 1.05      0           9               1           1
#> 73   9 restore 2.30      0           9               2           1
#> 10  10 protect 1.15      0          10               1           1
#> 74  10 restore 2.18      0          10               2           1
#> 11  11 protect 1.25      0          11               1           1
#> 75  11 restore 2.06      0          11               2           1
#> 12  12 protect 1.35      0          12               1           1
#> 76  12 restore 1.94      0          12               2           1
#> 13  13 protect 1.45      0          13               1           1
#> 77  13 restore 1.82      0          13               2           1
#> 14  14 protect 1.55      0          14               1           1
#> 78  14 restore 1.70      0          14               2           1
#> 15  15 protect 1.65      0          15               1           1
#> 79  15 restore 1.58      0          15               2           1
#> 16  16 protect 1.75      0          16               1           1
#> 80  16 restore 1.46      0          16               2           1
#> 17  17 protect 1.05      0          17               1           1
#> 81  17 restore 2.30      0          17               2           1
#> 18  18 protect 1.15      0          18               1           1
#> 82  18 restore 2.18      0          18               2           1
#> 19  19 protect 1.25      0          19               1           1
#> 83  19 restore 2.06      0          19               2           1
#> 20  20 protect 1.35      0          20               1           1
#> 84  20 restore 1.94      0          20               2           1
#> 21  21 protect 1.45      0          21               1           1
#> 85  21 restore 1.82      0          21               2           1
#> 22  22 protect 1.55      0          22               1           1
#> 86  22 restore 1.70      0          22               2           1
#> 23  23 protect 1.65      0          23               1           1
#> 87  23 restore 1.58      0          23               2           1
#> 24  24 protect 1.75      0          24               1           1
#> 88  24 restore 1.46      0          24               2           1
#> 25  25 protect 1.05      0          25               1           1
#> 89  25 restore 2.30      0          25               2           1
#> 26  26 protect 1.15      0          26               1           1
#> 90  26 restore 2.18      0          26               2           1
#> 27  27 protect 1.25      0          27               1           1
#> 91  27 restore 2.06      0          27               2           1
#> 28  28 protect 1.35      0          28               1           1
#> 92  28 restore 1.94      0          28               2           1
#> 29  29 protect 1.45      0          29               1           1
#> 93  29 restore 1.82      0          29               2           1
#> 30  30 protect 1.55      0          30               1           1
#> 94  30 restore 1.70      0          30               2           1
#> 31  31 protect 1.65      0          31               1           1
#> 95  31 restore 1.58      0          31               2           1
#> 32  32 protect 1.75      0          32               1           1
#> 96  32 restore 1.46      0          32               2           1
#> 33  33 protect 1.05      0          33               1           1
#> 97  33 restore 2.30      0          33               2           1
#> 34  34 protect 1.15      0          34               1           1
#> 98  34 restore 2.18      0          34               2           1
#> 35  35 protect 1.25      0          35               1           1
#> 99  35 restore 2.06      0          35               2           1
#> 36  36 protect 1.35      0          36               1           1
#> 100 36 restore 1.94      0          36               2           1
#> 37  37 protect 1.45      0          37               1           1
#> 101 37 restore 1.82      0          37               2           1
#> 38  38 protect 1.55      0          38               1           1
#> 102 38 restore 1.70      0          38               2           1
#> 39  39 protect 1.65      0          39               1           1
#> 103 39 restore 1.58      0          39               2           1
#> 40  40 protect 1.75      0          40               1           1
#> 104 40 restore 1.46      0          40               2           1
#> 41  41 protect 1.05      0          41               1           1
#> 105 41 restore 2.30      0          41               2           1
#> 42  42 protect 1.15      0          42               1           1
#> 106 42 restore 2.18      0          42               2           1
#> 43  43 protect 1.25      0          43               1           1
#> 107 43 restore 2.06      0          43               2           1
#> 44  44 protect 1.35      0          44               1           1
#> 108 44 restore 1.94      0          44               2           1
#> 45  45 protect 1.45      0          45               1           1
#> 109 45 restore 1.82      0          45               2           1
#> 46  46 protect 1.55      0          46               1           1
#> 110 46 restore 1.70      0          46               2           1
#> 47  47 protect 1.65      0          47               1           1
#> 111 47 restore 1.58      0          47               2           1
#> 48  48 protect 1.75      0          48               1           1
#> 112 48 restore 1.46      0          48               2           1
#> 49  49 protect 1.05      0          49               1           1
#> 113 49 restore 2.30      0          49               2           1
#> 50  50 protect 1.15      0          50               1           1
#> 114 50 restore 2.18      0          50               2           1
#> 51  51 protect 1.25      0          51               1           1
#> 115 51 restore 2.06      0          51               2           1
#> 52  52 protect 1.35      0          52               1           1
#> 116 52 restore 1.94      0          52               2           1
#> 53  53 protect 1.45      0          53               1           1
#> 117 53 restore 1.82      0          53               2           1
#> 54  54 protect 1.55      0          54               1           1
#> 118 54 restore 1.70      0          54               2           1
#> 55  55 protect 1.65      0          55               1           1
#> 119 55 restore 1.58      0          55               2           1
#> 56  56 protect 1.75      0          56               1           1
#> 120 56 restore 1.46      0          56               2           1
#> 57  57 protect 1.05      0          57               1           1
#> 121 57 restore 2.30      0          57               2           1
#> 58  58 protect 1.15      0          58               1           1
#> 122 58 restore 2.18      0          58               2           1
#> 59  59 protect 1.25      0          59               1           1
#> 123 59 restore 2.06      0          59               2           1
#> 60  60 protect 1.35      0          60               1           1
#> 124 60 restore 1.94      0          60               2           1
#> 61  61 protect 1.45      0          61               1           1
#> 125 61 restore 1.82      0          61               2           1
#> 62  62 protect 1.55      0          62               1           1
#> 126 62 restore 1.70      0          62               2           1
#> 63  63 protect 1.65      0          63               1           1
#> 127 63 restore 1.58      0          63               2           1
#> 64  64 protect 1.75      0          64               1           1
#> 128 64 restore 1.46      0          64               2           1
```
