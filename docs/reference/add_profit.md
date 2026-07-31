# Add profit to a planning problem

Define economic profit values for feasible planning unit–action pairs
and store them in a profit table.

Profit is stored separately from ecological effects. In particular,
`profit` is not the same as ecological `benefit` or `loss` as
represented in
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md).
This separation allows the package to distinguish economic returns from
ecological consequences when building objectives, constraints, and
reporting summaries.

## Usage

``` r
add_profit(x, profit = NULL)
```

## Arguments

- x:

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).
  It must already contain feasible actions and an action catalogue; run
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
  first.

- profit:

  Profit specification. One of:

  - `NULL`: profit is set to 0 for all feasible `(pu, action)` pairs,

  - a numeric scalar: recycled to all feasible pairs,

  - a named numeric vector: names are action ids and values define
    action-level profit,

  - a `data.frame(action, profit)` defining action-level profit,

  - a `data.frame(pu, action, profit)` defining pair-specific profit.

## Value

An updated `Problem` object with a stored profit table created or
replaced. The stored table contains columns `pu`, `action`, `profit`,
`internal_pu`, and `internal_action`, and includes only rows with
non-zero profit.

## Details

**When to use `add_profit()`.**

Use this function when economic returns, penalties, or other
action-specific financial values are part of the planning problem.
Typical downstream uses include objectives such as
[`add_objective_max_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_profit.md)
and
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md).

Let \\\mathcal{I}\\ denote the set of planning units and \\\mathcal{A}\\
the set of actions. Let \\\mathcal{D} \subseteq \mathcal{I} \times
\mathcal{A}\\ denote the set of feasible planning unit–action pairs
currently stored in the problem.

This function assigns to each feasible pair \\(i,a) \in \mathcal{D}\\ a
numeric profit value \\\pi\_{ia} \in \mathbb{R}\\ and stores the result
in a profit table.

Thus, the stored table can be interpreted as a mapping \$\$ \pi :
\mathcal{D} \to \mathbb{R}, \$\$ where \\\pi\_{ia}\\ represents the
economic return associated with selecting action \\a\\ in planning unit
\\i\\.

Profit values may be positive, zero, or negative. Positive values
represent gains or revenues, zero represents no net profit contribution,
and negative values can be used to encode penalties or net economic
losses.

The stored table contains:

- `pu`: external planning-unit id,

- `action`: action id,

- `profit`: numeric profit value,

- `internal_pu`: internal planning-unit index,

- `internal_action`: internal action index.

**Supported input formats**

The `profit` argument may be specified in several ways:

- `NULL`: assign profit 0 to all feasible `(pu, action)` pairs,

- a numeric scalar: assign the same profit value to all feasible pairs,

- a named numeric vector: names are action ids, assigning one global
  profit value per action,

- a `data.frame(action, profit)`: assign one global profit value per
  action,

- a `data.frame(pu, action, profit)`: assign pair-specific profit
  values.

When action-level profit is supplied, the same profit value is assigned
to all feasible planning units for that action. When pair-specific
profit is supplied, only the listed `(pu, action)` pairs receive
explicit values; unmatched feasible pairs are interpreted as zero-profit
pairs.

**Storage behaviour**

This function stores only rows with non-zero profit values. Feasible
pairs whose final profit is zero are omitted from the stored profit
table. Missing values produced during matching or joins are treated as
zero before this filtering step. Therefore, the resulting table is a
sparse representation of economic returns over the feasible decision
space.

**Data-only behaviour**

This function is purely data-oriented. It does not build or modify the
optimization model, and it does not change feasibility. It simply
assigns profit values to rows already present in the feasible action
table.

In particular:

- it does not add new feasible `(pu, action)` pairs,

- it does not remove infeasible pairs,

- it does not apply solver-side filtering such as dropping locked-out
  decisions,

- it does not modify ecological effect tables.

Any such filtering is expected to occur later when model-ready tables
are prepared, typically during the build stage invoked by
[`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md).

**Use in optimization**

Profit values stored by this function can later be used in objectives
such as
[`add_objective_max_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_profit.md)
or
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md),
in derived budget expressions, or in reporting and summary functions.

For example, if \\x\_{ia} \in \\0,1\\\\ denotes whether action \\a\\ is
selected in planning unit \\i\\, then a profit-maximization objective
typically takes the form \$\$ \max \sum\_{(i,a) \in \mathcal{D}}
\pi\_{ia} x\_{ia}. \$\$

## See also

[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_objective_max_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_profit.md),
[`add_objective_max_net_profit`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md),
[`add_effects`](https://josesalgr.github.io/multiscape/reference/add_effects.md)

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

# 1) Constant profit for every feasible (pu, action)
p1 <- add_profit(p, profit = 10)
p1$data$dist_profit
#>     pu  action profit internal_pu internal_action
#> 1    1 protect     10           1               1
#> 65   1 restore     10           1               2
#> 2    2 protect     10           2               1
#> 66   2 restore     10           2               2
#> 3    3 protect     10           3               1
#> 67   3 restore     10           3               2
#> 4    4 protect     10           4               1
#> 68   4 restore     10           4               2
#> 5    5 protect     10           5               1
#> 69   5 restore     10           5               2
#> 6    6 protect     10           6               1
#> 70   6 restore     10           6               2
#> 7    7 protect     10           7               1
#> 71   7 restore     10           7               2
#> 8    8 protect     10           8               1
#> 72   8 restore     10           8               2
#> 9    9 protect     10           9               1
#> 73   9 restore     10           9               2
#> 10  10 protect     10          10               1
#> 74  10 restore     10          10               2
#> 11  11 protect     10          11               1
#> 75  11 restore     10          11               2
#> 12  12 protect     10          12               1
#> 76  12 restore     10          12               2
#> 13  13 protect     10          13               1
#> 77  13 restore     10          13               2
#> 14  14 protect     10          14               1
#> 78  14 restore     10          14               2
#> 15  15 protect     10          15               1
#> 79  15 restore     10          15               2
#> 16  16 protect     10          16               1
#> 80  16 restore     10          16               2
#> 17  17 protect     10          17               1
#> 81  17 restore     10          17               2
#> 18  18 protect     10          18               1
#> 82  18 restore     10          18               2
#> 19  19 protect     10          19               1
#> 83  19 restore     10          19               2
#> 20  20 protect     10          20               1
#> 84  20 restore     10          20               2
#> 21  21 protect     10          21               1
#> 85  21 restore     10          21               2
#> 22  22 protect     10          22               1
#> 86  22 restore     10          22               2
#> 23  23 protect     10          23               1
#> 87  23 restore     10          23               2
#> 24  24 protect     10          24               1
#> 88  24 restore     10          24               2
#> 25  25 protect     10          25               1
#> 89  25 restore     10          25               2
#> 26  26 protect     10          26               1
#> 90  26 restore     10          26               2
#> 27  27 protect     10          27               1
#> 91  27 restore     10          27               2
#> 28  28 protect     10          28               1
#> 92  28 restore     10          28               2
#> 29  29 protect     10          29               1
#> 93  29 restore     10          29               2
#> 30  30 protect     10          30               1
#> 94  30 restore     10          30               2
#> 31  31 protect     10          31               1
#> 95  31 restore     10          31               2
#> 32  32 protect     10          32               1
#> 96  32 restore     10          32               2
#> 33  33 protect     10          33               1
#> 97  33 restore     10          33               2
#> 34  34 protect     10          34               1
#> 98  34 restore     10          34               2
#> 35  35 protect     10          35               1
#> 99  35 restore     10          35               2
#> 36  36 protect     10          36               1
#> 100 36 restore     10          36               2
#> 37  37 protect     10          37               1
#> 101 37 restore     10          37               2
#> 38  38 protect     10          38               1
#> 102 38 restore     10          38               2
#> 39  39 protect     10          39               1
#> 103 39 restore     10          39               2
#> 40  40 protect     10          40               1
#> 104 40 restore     10          40               2
#> 41  41 protect     10          41               1
#> 105 41 restore     10          41               2
#> 42  42 protect     10          42               1
#> 106 42 restore     10          42               2
#> 43  43 protect     10          43               1
#> 107 43 restore     10          43               2
#> 44  44 protect     10          44               1
#> 108 44 restore     10          44               2
#> 45  45 protect     10          45               1
#> 109 45 restore     10          45               2
#> 46  46 protect     10          46               1
#> 110 46 restore     10          46               2
#> 47  47 protect     10          47               1
#> 111 47 restore     10          47               2
#> 48  48 protect     10          48               1
#> 112 48 restore     10          48               2
#> 49  49 protect     10          49               1
#> 113 49 restore     10          49               2
#> 50  50 protect     10          50               1
#> 114 50 restore     10          50               2
#> 51  51 protect     10          51               1
#> 115 51 restore     10          51               2
#> 52  52 protect     10          52               1
#> 116 52 restore     10          52               2
#> 53  53 protect     10          53               1
#> 117 53 restore     10          53               2
#> 54  54 protect     10          54               1
#> 118 54 restore     10          54               2
#> 55  55 protect     10          55               1
#> 119 55 restore     10          55               2
#> 56  56 protect     10          56               1
#> 120 56 restore     10          56               2
#> 57  57 protect     10          57               1
#> 121 57 restore     10          57               2
#> 58  58 protect     10          58               1
#> 122 58 restore     10          58               2
#> 59  59 protect     10          59               1
#> 123 59 restore     10          59               2
#> 60  60 protect     10          60               1
#> 124 60 restore     10          60               2
#> 61  61 protect     10          61               1
#> 125 61 restore     10          61               2
#> 62  62 protect     10          62               1
#> 126 62 restore     10          62               2
#> 63  63 protect     10          63               1
#> 127 63 restore     10          63               2
#> 64  64 protect     10          64               1
#> 128 64 restore     10          64               2

# 2) Profit per action using a named vector
pr <- c(protect = 50, restore = -5)
p2 <- add_profit(p, profit = pr)
p2$data$dist_profit
#>     pu  action profit internal_pu internal_action
#> 1    1 protect     50           1               1
#> 65   1 restore     -5           1               2
#> 2    2 protect     50           2               1
#> 66   2 restore     -5           2               2
#> 3    3 protect     50           3               1
#> 67   3 restore     -5           3               2
#> 4    4 protect     50           4               1
#> 68   4 restore     -5           4               2
#> 5    5 protect     50           5               1
#> 69   5 restore     -5           5               2
#> 6    6 protect     50           6               1
#> 70   6 restore     -5           6               2
#> 7    7 protect     50           7               1
#> 71   7 restore     -5           7               2
#> 8    8 protect     50           8               1
#> 72   8 restore     -5           8               2
#> 9    9 protect     50           9               1
#> 73   9 restore     -5           9               2
#> 10  10 protect     50          10               1
#> 74  10 restore     -5          10               2
#> 11  11 protect     50          11               1
#> 75  11 restore     -5          11               2
#> 12  12 protect     50          12               1
#> 76  12 restore     -5          12               2
#> 13  13 protect     50          13               1
#> 77  13 restore     -5          13               2
#> 14  14 protect     50          14               1
#> 78  14 restore     -5          14               2
#> 15  15 protect     50          15               1
#> 79  15 restore     -5          15               2
#> 16  16 protect     50          16               1
#> 80  16 restore     -5          16               2
#> 17  17 protect     50          17               1
#> 81  17 restore     -5          17               2
#> 18  18 protect     50          18               1
#> 82  18 restore     -5          18               2
#> 19  19 protect     50          19               1
#> 83  19 restore     -5          19               2
#> 20  20 protect     50          20               1
#> 84  20 restore     -5          20               2
#> 21  21 protect     50          21               1
#> 85  21 restore     -5          21               2
#> 22  22 protect     50          22               1
#> 86  22 restore     -5          22               2
#> 23  23 protect     50          23               1
#> 87  23 restore     -5          23               2
#> 24  24 protect     50          24               1
#> 88  24 restore     -5          24               2
#> 25  25 protect     50          25               1
#> 89  25 restore     -5          25               2
#> 26  26 protect     50          26               1
#> 90  26 restore     -5          26               2
#> 27  27 protect     50          27               1
#> 91  27 restore     -5          27               2
#> 28  28 protect     50          28               1
#> 92  28 restore     -5          28               2
#> 29  29 protect     50          29               1
#> 93  29 restore     -5          29               2
#> 30  30 protect     50          30               1
#> 94  30 restore     -5          30               2
#> 31  31 protect     50          31               1
#> 95  31 restore     -5          31               2
#> 32  32 protect     50          32               1
#> 96  32 restore     -5          32               2
#> 33  33 protect     50          33               1
#> 97  33 restore     -5          33               2
#> 34  34 protect     50          34               1
#> 98  34 restore     -5          34               2
#> 35  35 protect     50          35               1
#> 99  35 restore     -5          35               2
#> 36  36 protect     50          36               1
#> 100 36 restore     -5          36               2
#> 37  37 protect     50          37               1
#> 101 37 restore     -5          37               2
#> 38  38 protect     50          38               1
#> 102 38 restore     -5          38               2
#> 39  39 protect     50          39               1
#> 103 39 restore     -5          39               2
#> 40  40 protect     50          40               1
#> 104 40 restore     -5          40               2
#> 41  41 protect     50          41               1
#> 105 41 restore     -5          41               2
#> 42  42 protect     50          42               1
#> 106 42 restore     -5          42               2
#> 43  43 protect     50          43               1
#> 107 43 restore     -5          43               2
#> 44  44 protect     50          44               1
#> 108 44 restore     -5          44               2
#> 45  45 protect     50          45               1
#> 109 45 restore     -5          45               2
#> 46  46 protect     50          46               1
#> 110 46 restore     -5          46               2
#> 47  47 protect     50          47               1
#> 111 47 restore     -5          47               2
#> 48  48 protect     50          48               1
#> 112 48 restore     -5          48               2
#> 49  49 protect     50          49               1
#> 113 49 restore     -5          49               2
#> 50  50 protect     50          50               1
#> 114 50 restore     -5          50               2
#> 51  51 protect     50          51               1
#> 115 51 restore     -5          51               2
#> 52  52 protect     50          52               1
#> 116 52 restore     -5          52               2
#> 53  53 protect     50          53               1
#> 117 53 restore     -5          53               2
#> 54  54 protect     50          54               1
#> 118 54 restore     -5          54               2
#> 55  55 protect     50          55               1
#> 119 55 restore     -5          55               2
#> 56  56 protect     50          56               1
#> 120 56 restore     -5          56               2
#> 57  57 protect     50          57               1
#> 121 57 restore     -5          57               2
#> 58  58 protect     50          58               1
#> 122 58 restore     -5          58               2
#> 59  59 protect     50          59               1
#> 123 59 restore     -5          59               2
#> 60  60 protect     50          60               1
#> 124 60 restore     -5          60               2
#> 61  61 protect     50          61               1
#> 125 61 restore     -5          61               2
#> 62  62 protect     50          62               1
#> 126 62 restore     -5          62               2
#> 63  63 protect     50          63               1
#> 127 63 restore     -5          63               2
#> 64  64 protect     50          64               1
#> 128 64 restore     -5          64               2

# 3) Profit per action using a data frame
pr_df <- data.frame(
  action = c("protect", "restore"),
  profit = c(40, 15)
)
p3 <- add_profit(p, profit = pr_df)
p3$data$dist_profit
#>     pu  action profit internal_pu internal_action
#> 1    1 protect     40           1               1
#> 2    1 restore     15           1               2
#> 3    2 protect     40           2               1
#> 4    2 restore     15           2               2
#> 5    3 protect     40           3               1
#> 6    3 restore     15           3               2
#> 7    4 protect     40           4               1
#> 8    4 restore     15           4               2
#> 9    5 protect     40           5               1
#> 10   5 restore     15           5               2
#> 11   6 protect     40           6               1
#> 12   6 restore     15           6               2
#> 13   7 protect     40           7               1
#> 14   7 restore     15           7               2
#> 15   8 protect     40           8               1
#> 16   8 restore     15           8               2
#> 17   9 protect     40           9               1
#> 18   9 restore     15           9               2
#> 19  10 protect     40          10               1
#> 20  10 restore     15          10               2
#> 21  11 protect     40          11               1
#> 22  11 restore     15          11               2
#> 23  12 protect     40          12               1
#> 24  12 restore     15          12               2
#> 25  13 protect     40          13               1
#> 26  13 restore     15          13               2
#> 27  14 protect     40          14               1
#> 28  14 restore     15          14               2
#> 29  15 protect     40          15               1
#> 30  15 restore     15          15               2
#> 31  16 protect     40          16               1
#> 32  16 restore     15          16               2
#> 33  17 protect     40          17               1
#> 34  17 restore     15          17               2
#> 35  18 protect     40          18               1
#> 36  18 restore     15          18               2
#> 37  19 protect     40          19               1
#> 38  19 restore     15          19               2
#> 39  20 protect     40          20               1
#> 40  20 restore     15          20               2
#> 41  21 protect     40          21               1
#> 42  21 restore     15          21               2
#> 43  22 protect     40          22               1
#> 44  22 restore     15          22               2
#> 45  23 protect     40          23               1
#> 46  23 restore     15          23               2
#> 47  24 protect     40          24               1
#> 48  24 restore     15          24               2
#> 49  25 protect     40          25               1
#> 50  25 restore     15          25               2
#> 51  26 protect     40          26               1
#> 52  26 restore     15          26               2
#> 53  27 protect     40          27               1
#> 54  27 restore     15          27               2
#> 55  28 protect     40          28               1
#> 56  28 restore     15          28               2
#> 57  29 protect     40          29               1
#> 58  29 restore     15          29               2
#> 59  30 protect     40          30               1
#> 60  30 restore     15          30               2
#> 61  31 protect     40          31               1
#> 62  31 restore     15          31               2
#> 63  32 protect     40          32               1
#> 64  32 restore     15          32               2
#> 65  33 protect     40          33               1
#> 66  33 restore     15          33               2
#> 67  34 protect     40          34               1
#> 68  34 restore     15          34               2
#> 69  35 protect     40          35               1
#> 70  35 restore     15          35               2
#> 71  36 protect     40          36               1
#> 72  36 restore     15          36               2
#> 73  37 protect     40          37               1
#> 74  37 restore     15          37               2
#> 75  38 protect     40          38               1
#> 76  38 restore     15          38               2
#> 77  39 protect     40          39               1
#> 78  39 restore     15          39               2
#> 79  40 protect     40          40               1
#> 80  40 restore     15          40               2
#> 81  41 protect     40          41               1
#> 82  41 restore     15          41               2
#> 83  42 protect     40          42               1
#> 84  42 restore     15          42               2
#> 85  43 protect     40          43               1
#> 86  43 restore     15          43               2
#> 87  44 protect     40          44               1
#> 88  44 restore     15          44               2
#> 89  45 protect     40          45               1
#> 90  45 restore     15          45               2
#> 91  46 protect     40          46               1
#> 92  46 restore     15          46               2
#> 93  47 protect     40          47               1
#> 94  47 restore     15          47               2
#> 95  48 protect     40          48               1
#> 96  48 restore     15          48               2
#> 97  49 protect     40          49               1
#> 98  49 restore     15          49               2
#> 99  50 protect     40          50               1
#> 100 50 restore     15          50               2
#> 101 51 protect     40          51               1
#> 102 51 restore     15          51               2
#> 103 52 protect     40          52               1
#> 104 52 restore     15          52               2
#> 105 53 protect     40          53               1
#> 106 53 restore     15          53               2
#> 107 54 protect     40          54               1
#> 108 54 restore     15          54               2
#> 109 55 protect     40          55               1
#> 110 55 restore     15          55               2
#> 111 56 protect     40          56               1
#> 112 56 restore     15          56               2
#> 113 57 protect     40          57               1
#> 114 57 restore     15          57               2
#> 115 58 protect     40          58               1
#> 116 58 restore     15          58               2
#> 117 59 protect     40          59               1
#> 118 59 restore     15          59               2
#> 119 60 protect     40          60               1
#> 120 60 restore     15          60               2
#> 121 61 protect     40          61               1
#> 122 61 restore     15          61               2
#> 123 62 protect     40          62               1
#> 124 62 restore     15          62               2
#> 125 63 protect     40          63               1
#> 126 63 restore     15          63               2
#> 127 64 protect     40          64               1
#> 128 64 restore     15          64               2

# 4) Profit per (pu, action) pair
pr_pair <- data.frame(
  pu = c(1, 2, 3),
  action = c("protect", "protect", "restore"),
  profit = c(100, 80, 30)
)
p4 <- add_profit(p, profit = pr_pair)
p4$data$dist_profit
#>   pu  action profit internal_pu internal_action
#> 1  1 protect    100           1               1
#> 3  2 protect     80           2               1
#> 6  3 restore     30           3               2
```
