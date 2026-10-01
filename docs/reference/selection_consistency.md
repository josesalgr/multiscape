# Summarize consistency of planning-unit states

Summarize recurrence and disagreement of canonical planning-unit states
across stored solutions.

## Usage

``` r
selection_consistency(x, solution_groups = NULL)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- solution_groups:

  Optional named list assigning every stored numeric solution id to
  exactly one group. If `NULL`, all solutions form the group `"all"`.

## Value

A `data.frame` with one row per planning unit and solution group,
including selection, managed and unmanaged frequencies, dominant state
and frequency, number of observed states, whether the unit is variable
within the group, Shannon entropy, and normalized entropy.

## Details

States are obtained from
[`get_solution_states`](https://josesalgr.github.io/multiscape/reference/get_solution_states.md).
All stored solutions contribute equally, and all planning units are
returned. `solution_groups` can partition the stored solutions into
named groups; consistency is then summarized separately within each
group.

Frequencies describe the proportion of stored solutions in the
corresponding group. They are conditional summaries of the supplied
`SolutionSet`, not probabilities or formal measures of uncertainty.
`variable` is `TRUE` when more than one state occurs for a planning unit
within a solution group.

## See also

[`get_solution_states`](https://josesalgr.github.io/multiscape/reference/get_solution_states.md),
[`selection_frequency`](https://josesalgr.github.io/multiscape/reference/selection_frequency.md),
[`selection_similarity`](https://josesalgr.github.io/multiscape/reference/selection_similarity.md),
[`solution_filter`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)

## Examples

``` r
# Load a complete simulated multi-action problem.
example_data <- load_sim_multiaction()

problem <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
) |>
  add_actions(
    example_data$actions,
    cost = example_data$action_costs
  ) |>
  add_effects(
    example_data$effect_assumptions
  ) |>
  add_constraint_targets_relative(0.05) |>
  add_objective_min_cost(
    alias = "cost",
    include_pu_cost = FALSE
  ) |>
  add_objective_max_benefit(
    alias = "benefit"
  ) |>
  set_method_weighted_sum(
    aliases = c("cost", "benefit"),
    runs = set_runs_grid(n = 5),
    normalize_weights = TRUE
  )

if (requireNamespace("rcbc", quietly = TRUE)) {
  problem <- set_solver_cbc(problem, verbose = FALSE)
  solutions <- solve(problem)

  consistency <- selection_consistency(solutions)
  head(consistency)

  solution_ids <- get_runs(solutions)$solution_id
  solution_ids <- solution_ids[!is.na(solution_ids)]

  if (length(solution_ids) >= 2L) {
    cut <- ceiling(length(solution_ids) / 2)
    groups <- list(
      first = solution_ids[seq_len(cut)],
      second = solution_ids[seq.int(cut + 1L, length(solution_ids))]
    )

    selection_consistency(
      solutions,
      solution_groups = groups
    )
  }
}
#>     pu solution_group n_solutions selected_frequency managed_frequency
#> 1    1          first           3          0.0000000         0.0000000
#> 2    1         second           2          0.5000000         0.5000000
#> 3   10          first           3          0.0000000         0.0000000
#> 4   10         second           2          1.0000000         1.0000000
#> 5   11          first           3          0.0000000         0.0000000
#> 6   11         second           2          0.5000000         0.5000000
#> 7   12          first           3          0.0000000         0.0000000
#> 8   12         second           2          0.5000000         0.5000000
#> 9   13          first           3          0.0000000         0.0000000
#> 10  13         second           2          0.5000000         0.5000000
#> 11  14          first           3          0.0000000         0.0000000
#> 12  14         second           2          0.5000000         0.5000000
#> 13  15          first           3          0.0000000         0.0000000
#> 14  15         second           2          0.5000000         0.5000000
#> 15  16          first           3          0.0000000         0.0000000
#> 16  16         second           2          0.5000000         0.5000000
#> 17  17          first           3          0.0000000         0.0000000
#> 18  17         second           2          0.5000000         0.5000000
#> 19  18          first           3          0.0000000         0.0000000
#> 20  18         second           2          1.0000000         1.0000000
#> 21  19          first           3          0.0000000         0.0000000
#> 22  19         second           2          1.0000000         1.0000000
#> 23   2          first           3          0.0000000         0.0000000
#> 24   2         second           2          0.5000000         0.5000000
#> 25  20          first           3          0.0000000         0.0000000
#> 26  20         second           2          0.5000000         0.5000000
#> 27  21          first           3          0.0000000         0.0000000
#> 28  21         second           2          0.5000000         0.5000000
#> 29  22          first           3          0.0000000         0.0000000
#> 30  22         second           2          0.5000000         0.5000000
#> 31  23          first           3          0.0000000         0.0000000
#> 32  23         second           2          0.5000000         0.5000000
#> 33  24          first           3          0.0000000         0.0000000
#> 34  24         second           2          0.5000000         0.5000000
#> 35  25          first           3          0.0000000         0.0000000
#> 36  25         second           2          0.5000000         0.5000000
#> 37  26          first           3          0.0000000         0.0000000
#> 38  26         second           2          0.5000000         0.5000000
#> 39  27          first           3          0.0000000         0.0000000
#> 40  27         second           2          1.0000000         1.0000000
#> 41  28          first           3          0.0000000         0.0000000
#> 42  28         second           2          1.0000000         1.0000000
#> 43  29          first           3          0.0000000         0.0000000
#> 44  29         second           2          1.0000000         1.0000000
#> 45   3          first           3          0.0000000         0.0000000
#> 46   3         second           2          0.5000000         0.5000000
#> 47  30          first           3          0.0000000         0.0000000
#> 48  30         second           2          0.5000000         0.5000000
#> 49  31          first           3          0.0000000         0.0000000
#> 50  31         second           2          0.5000000         0.5000000
#> 51  32          first           3          0.0000000         0.0000000
#> 52  32         second           2          0.5000000         0.5000000
#> 53  33          first           3          0.3333333         0.3333333
#> 54  33         second           2          1.0000000         1.0000000
#> 55  34          first           3          0.0000000         0.0000000
#> 56  34         second           2          1.0000000         1.0000000
#> 57  35          first           3          0.0000000         0.0000000
#> 58  35         second           2          1.0000000         1.0000000
#> 59  36          first           3          0.0000000         0.0000000
#> 60  36         second           2          1.0000000         1.0000000
#> 61  37          first           3          0.0000000         0.0000000
#> 62  37         second           2          1.0000000         1.0000000
#> 63  38          first           3          0.0000000         0.0000000
#> 64  38         second           2          1.0000000         1.0000000
#> 65  39          first           3          0.0000000         0.0000000
#> 66  39         second           2          0.5000000         0.5000000
#> 67   4          first           3          0.0000000         0.0000000
#> 68   4         second           2          0.5000000         0.5000000
#> 69  40          first           3          0.0000000         0.0000000
#> 70  40         second           2          0.5000000         0.5000000
#> 71  41          first           3          0.0000000         0.0000000
#> 72  41         second           2          1.0000000         1.0000000
#> 73  42          first           3          0.6666667         0.6666667
#> 74  42         second           2          1.0000000         1.0000000
#> 75  43          first           3          0.0000000         0.0000000
#> 76  43         second           2          1.0000000         1.0000000
#> 77  44          first           3          0.0000000         0.0000000
#> 78  44         second           2          1.0000000         1.0000000
#> 79  45          first           3          0.0000000         0.0000000
#> 80  45         second           2          0.5000000         0.5000000
#> 81  46          first           3          0.0000000         0.0000000
#> 82  46         second           2          1.0000000         1.0000000
#> 83  47          first           3          0.3333333         0.3333333
#> 84  47         second           2          1.0000000         1.0000000
#> 85  48          first           3          0.0000000         0.0000000
#> 86  48         second           2          1.0000000         1.0000000
#> 87  49          first           3          0.0000000         0.0000000
#> 88  49         second           2          1.0000000         1.0000000
#> 89   5          first           3          0.0000000         0.0000000
#> 90   5         second           2          0.5000000         0.5000000
#> 91  50          first           3          0.0000000         0.0000000
#> 92  50         second           2          1.0000000         1.0000000
#> 93  51          first           3          0.0000000         0.0000000
#> 94  51         second           2          1.0000000         1.0000000
#> 95  52          first           3          0.0000000         0.0000000
#> 96  52         second           2          1.0000000         1.0000000
#> 97  53          first           3          0.0000000         0.0000000
#> 98  53         second           2          0.5000000         0.5000000
#> 99  54          first           3          0.0000000         0.0000000
#> 100 54         second           2          0.5000000         0.5000000
#> 101 55          first           3          0.0000000         0.0000000
#> 102 55         second           2          0.5000000         0.5000000
#> 103 56          first           3          0.0000000         0.0000000
#> 104 56         second           2          1.0000000         1.0000000
#> 105 57          first           3          0.0000000         0.0000000
#> 106 57         second           2          1.0000000         1.0000000
#> 107 58          first           3          0.0000000         0.0000000
#> 108 58         second           2          1.0000000         1.0000000
#> 109 59          first           3          0.0000000         0.0000000
#> 110 59         second           2          1.0000000         1.0000000
#> 111  6          first           3          0.0000000         0.0000000
#> 112  6         second           2          0.5000000         0.5000000
#> 113 60          first           3          0.0000000         0.0000000
#> 114 60         second           2          0.5000000         0.5000000
#> 115 61          first           3          0.0000000         0.0000000
#> 116 61         second           2          0.5000000         0.5000000
#> 117 62          first           3          0.0000000         0.0000000
#> 118 62         second           2          0.5000000         0.5000000
#> 119 63          first           3          0.0000000         0.0000000
#> 120 63         second           2          0.5000000         0.5000000
#> 121 64          first           3          0.0000000         0.0000000
#> 122 64         second           2          0.5000000         0.5000000
#> 123  7          first           3          0.0000000         0.0000000
#> 124  7         second           2          0.5000000         0.5000000
#> 125  8          first           3          0.0000000         0.0000000
#> 126  8         second           2          0.5000000         0.5000000
#> 127  9          first           3          0.6666667         0.6666667
#> 128  9         second           2          1.0000000         1.0000000
#>     unmanaged_frequency dominant_state dominant_frequency dominant_tie n_states
#> 1             1.0000000      unmanaged          1.0000000        FALSE        1
#> 2             0.5000000        restore          0.5000000         TRUE        2
#> 3             1.0000000      unmanaged          1.0000000        FALSE        1
#> 4             0.0000000        restore          1.0000000        FALSE        1
#> 5             1.0000000      unmanaged          1.0000000        FALSE        1
#> 6             0.5000000        restore          0.5000000         TRUE        2
#> 7             1.0000000      unmanaged          1.0000000        FALSE        1
#> 8             0.5000000        restore          0.5000000         TRUE        2
#> 9             1.0000000      unmanaged          1.0000000        FALSE        1
#> 10            0.5000000        protect          0.5000000         TRUE        2
#> 11            1.0000000      unmanaged          1.0000000        FALSE        1
#> 12            0.5000000        protect          0.5000000         TRUE        2
#> 13            1.0000000      unmanaged          1.0000000        FALSE        1
#> 14            0.5000000        protect          0.5000000         TRUE        2
#> 15            1.0000000      unmanaged          1.0000000        FALSE        1
#> 16            0.5000000        protect          0.5000000         TRUE        2
#> 17            1.0000000      unmanaged          1.0000000        FALSE        1
#> 18            0.5000000        restore          0.5000000         TRUE        2
#> 19            1.0000000      unmanaged          1.0000000        FALSE        1
#> 20            0.0000000        restore          1.0000000        FALSE        1
#> 21            1.0000000      unmanaged          1.0000000        FALSE        1
#> 22            0.0000000        restore          1.0000000        FALSE        1
#> 23            1.0000000      unmanaged          1.0000000        FALSE        1
#> 24            0.5000000        restore          0.5000000         TRUE        2
#> 25            1.0000000      unmanaged          1.0000000        FALSE        1
#> 26            0.5000000        restore          0.5000000         TRUE        2
#> 27            1.0000000      unmanaged          1.0000000        FALSE        1
#> 28            0.5000000        restore          0.5000000         TRUE        2
#> 29            1.0000000      unmanaged          1.0000000        FALSE        1
#> 30            0.5000000        protect          0.5000000         TRUE        2
#> 31            1.0000000      unmanaged          1.0000000        FALSE        1
#> 32            0.5000000        protect          0.5000000         TRUE        2
#> 33            1.0000000      unmanaged          1.0000000        FALSE        1
#> 34            0.5000000        protect          0.5000000         TRUE        2
#> 35            1.0000000      unmanaged          1.0000000        FALSE        1
#> 36            0.5000000        protect          0.5000000         TRUE        2
#> 37            1.0000000      unmanaged          1.0000000        FALSE        1
#> 38            0.5000000        protect          0.5000000         TRUE        2
#> 39            1.0000000      unmanaged          1.0000000        FALSE        1
#> 40            0.0000000        restore          1.0000000        FALSE        1
#> 41            1.0000000      unmanaged          1.0000000        FALSE        1
#> 42            0.0000000        restore          1.0000000        FALSE        1
#> 43            1.0000000      unmanaged          1.0000000        FALSE        1
#> 44            0.0000000        restore          1.0000000        FALSE        1
#> 45            1.0000000      unmanaged          1.0000000        FALSE        1
#> 46            0.5000000        restore          0.5000000         TRUE        2
#> 47            1.0000000      unmanaged          1.0000000        FALSE        1
#> 48            0.5000000        restore          0.5000000         TRUE        2
#> 49            1.0000000      unmanaged          1.0000000        FALSE        1
#> 50            0.5000000        restore          0.5000000         TRUE        2
#> 51            1.0000000      unmanaged          1.0000000        FALSE        1
#> 52            0.5000000        restore          0.5000000         TRUE        2
#> 53            0.6666667      unmanaged          0.6666667        FALSE        2
#> 54            0.0000000        protect          1.0000000        FALSE        1
#> 55            1.0000000      unmanaged          1.0000000        FALSE        1
#> 56            0.0000000        protect          1.0000000        FALSE        1
#> 57            1.0000000      unmanaged          1.0000000        FALSE        1
#> 58            0.0000000        protect          1.0000000        FALSE        1
#> 59            1.0000000      unmanaged          1.0000000        FALSE        1
#> 60            0.0000000        protect          1.0000000        FALSE        1
#> 61            1.0000000      unmanaged          1.0000000        FALSE        1
#> 62            0.0000000        restore          1.0000000        FALSE        1
#> 63            1.0000000      unmanaged          1.0000000        FALSE        1
#> 64            0.0000000        restore          1.0000000        FALSE        1
#> 65            1.0000000      unmanaged          1.0000000        FALSE        1
#> 66            0.5000000        restore          0.5000000         TRUE        2
#> 67            1.0000000      unmanaged          1.0000000        FALSE        1
#> 68            0.5000000        protect          0.5000000         TRUE        2
#> 69            1.0000000      unmanaged          1.0000000        FALSE        1
#> 70            0.5000000        restore          0.5000000         TRUE        2
#> 71            1.0000000      unmanaged          1.0000000        FALSE        1
#> 72            0.0000000        protect          1.0000000        FALSE        1
#> 73            0.3333333        protect          0.6666667        FALSE        2
#> 74            0.0000000        protect          1.0000000        FALSE        1
#> 75            1.0000000      unmanaged          1.0000000        FALSE        1
#> 76            0.0000000        protect          1.0000000        FALSE        1
#> 77            1.0000000      unmanaged          1.0000000        FALSE        1
#> 78            0.0000000        protect          1.0000000        FALSE        1
#> 79            1.0000000      unmanaged          1.0000000        FALSE        1
#> 80            0.5000000        protect          0.5000000         TRUE        2
#> 81            1.0000000      unmanaged          1.0000000        FALSE        1
#> 82            0.0000000        restore          1.0000000        FALSE        1
#> 83            0.6666667      unmanaged          0.6666667        FALSE        2
#> 84            0.0000000        restore          1.0000000        FALSE        1
#> 85            1.0000000      unmanaged          1.0000000        FALSE        1
#> 86            0.0000000        restore          1.0000000        FALSE        1
#> 87            1.0000000      unmanaged          1.0000000        FALSE        1
#> 88            0.0000000        protect          1.0000000        FALSE        1
#> 89            1.0000000      unmanaged          1.0000000        FALSE        1
#> 90            0.5000000        protect          0.5000000         TRUE        2
#> 91            1.0000000      unmanaged          1.0000000        FALSE        1
#> 92            0.0000000        protect          1.0000000        FALSE        1
#> 93            1.0000000      unmanaged          1.0000000        FALSE        1
#> 94            0.0000000        protect          1.0000000        FALSE        1
#> 95            1.0000000      unmanaged          1.0000000        FALSE        1
#> 96            0.0000000        protect          1.0000000        FALSE        1
#> 97            1.0000000      unmanaged          1.0000000        FALSE        1
#> 98            0.5000000        protect          0.5000000         TRUE        2
#> 99            1.0000000      unmanaged          1.0000000        FALSE        1
#> 100           0.5000000        protect          0.5000000         TRUE        2
#> 101           1.0000000      unmanaged          1.0000000        FALSE        1
#> 102           0.5000000        restore          0.5000000         TRUE        2
#> 103           1.0000000      unmanaged          1.0000000        FALSE        1
#> 104           0.0000000        restore          1.0000000        FALSE        1
#> 105           1.0000000      unmanaged          1.0000000        FALSE        1
#> 106           0.0000000        protect          1.0000000        FALSE        1
#> 107           1.0000000      unmanaged          1.0000000        FALSE        1
#> 108           0.0000000        protect          1.0000000        FALSE        1
#> 109           1.0000000      unmanaged          1.0000000        FALSE        1
#> 110           0.0000000        protect          1.0000000        FALSE        1
#> 111           1.0000000      unmanaged          1.0000000        FALSE        1
#> 112           0.5000000        protect          0.5000000         TRUE        2
#> 113           1.0000000      unmanaged          1.0000000        FALSE        1
#> 114           0.5000000        protect          0.5000000         TRUE        2
#> 115           1.0000000      unmanaged          1.0000000        FALSE        1
#> 116           0.5000000        protect          0.5000000         TRUE        2
#> 117           1.0000000      unmanaged          1.0000000        FALSE        1
#> 118           0.5000000        protect          0.5000000         TRUE        2
#> 119           1.0000000      unmanaged          1.0000000        FALSE        1
#> 120           0.5000000        protect          0.5000000         TRUE        2
#> 121           1.0000000      unmanaged          1.0000000        FALSE        1
#> 122           0.5000000        restore          0.5000000         TRUE        2
#> 123           1.0000000      unmanaged          1.0000000        FALSE        1
#> 124           0.5000000        protect          0.5000000         TRUE        2
#> 125           1.0000000      unmanaged          1.0000000        FALSE        1
#> 126           0.5000000        protect          0.5000000         TRUE        2
#> 127           0.3333333        protect          0.6666667        FALSE        2
#> 128           0.0000000        restore          1.0000000        FALSE        1
#>     variable   entropy normalized_entropy
#> 1      FALSE 0.0000000          0.0000000
#> 2       TRUE 0.6931472          1.0000000
#> 3      FALSE 0.0000000          0.0000000
#> 4      FALSE 0.0000000          0.0000000
#> 5      FALSE 0.0000000          0.0000000
#> 6       TRUE 0.6931472          1.0000000
#> 7      FALSE 0.0000000          0.0000000
#> 8       TRUE 0.6931472          1.0000000
#> 9      FALSE 0.0000000          0.0000000
#> 10      TRUE 0.6931472          1.0000000
#> 11     FALSE 0.0000000          0.0000000
#> 12      TRUE 0.6931472          1.0000000
#> 13     FALSE 0.0000000          0.0000000
#> 14      TRUE 0.6931472          1.0000000
#> 15     FALSE 0.0000000          0.0000000
#> 16      TRUE 0.6931472          1.0000000
#> 17     FALSE 0.0000000          0.0000000
#> 18      TRUE 0.6931472          1.0000000
#> 19     FALSE 0.0000000          0.0000000
#> 20     FALSE 0.0000000          0.0000000
#> 21     FALSE 0.0000000          0.0000000
#> 22     FALSE 0.0000000          0.0000000
#> 23     FALSE 0.0000000          0.0000000
#> 24      TRUE 0.6931472          1.0000000
#> 25     FALSE 0.0000000          0.0000000
#> 26      TRUE 0.6931472          1.0000000
#> 27     FALSE 0.0000000          0.0000000
#> 28      TRUE 0.6931472          1.0000000
#> 29     FALSE 0.0000000          0.0000000
#> 30      TRUE 0.6931472          1.0000000
#> 31     FALSE 0.0000000          0.0000000
#> 32      TRUE 0.6931472          1.0000000
#> 33     FALSE 0.0000000          0.0000000
#> 34      TRUE 0.6931472          1.0000000
#> 35     FALSE 0.0000000          0.0000000
#> 36      TRUE 0.6931472          1.0000000
#> 37     FALSE 0.0000000          0.0000000
#> 38      TRUE 0.6931472          1.0000000
#> 39     FALSE 0.0000000          0.0000000
#> 40     FALSE 0.0000000          0.0000000
#> 41     FALSE 0.0000000          0.0000000
#> 42     FALSE 0.0000000          0.0000000
#> 43     FALSE 0.0000000          0.0000000
#> 44     FALSE 0.0000000          0.0000000
#> 45     FALSE 0.0000000          0.0000000
#> 46      TRUE 0.6931472          1.0000000
#> 47     FALSE 0.0000000          0.0000000
#> 48      TRUE 0.6931472          1.0000000
#> 49     FALSE 0.0000000          0.0000000
#> 50      TRUE 0.6931472          1.0000000
#> 51     FALSE 0.0000000          0.0000000
#> 52      TRUE 0.6931472          1.0000000
#> 53      TRUE 0.6365142          0.9182958
#> 54     FALSE 0.0000000          0.0000000
#> 55     FALSE 0.0000000          0.0000000
#> 56     FALSE 0.0000000          0.0000000
#> 57     FALSE 0.0000000          0.0000000
#> 58     FALSE 0.0000000          0.0000000
#> 59     FALSE 0.0000000          0.0000000
#> 60     FALSE 0.0000000          0.0000000
#> 61     FALSE 0.0000000          0.0000000
#> 62     FALSE 0.0000000          0.0000000
#> 63     FALSE 0.0000000          0.0000000
#> 64     FALSE 0.0000000          0.0000000
#> 65     FALSE 0.0000000          0.0000000
#> 66      TRUE 0.6931472          1.0000000
#> 67     FALSE 0.0000000          0.0000000
#> 68      TRUE 0.6931472          1.0000000
#> 69     FALSE 0.0000000          0.0000000
#> 70      TRUE 0.6931472          1.0000000
#> 71     FALSE 0.0000000          0.0000000
#> 72     FALSE 0.0000000          0.0000000
#> 73      TRUE 0.6365142          0.9182958
#> 74     FALSE 0.0000000          0.0000000
#> 75     FALSE 0.0000000          0.0000000
#> 76     FALSE 0.0000000          0.0000000
#> 77     FALSE 0.0000000          0.0000000
#> 78     FALSE 0.0000000          0.0000000
#> 79     FALSE 0.0000000          0.0000000
#> 80      TRUE 0.6931472          1.0000000
#> 81     FALSE 0.0000000          0.0000000
#> 82     FALSE 0.0000000          0.0000000
#> 83      TRUE 0.6365142          0.9182958
#> 84     FALSE 0.0000000          0.0000000
#> 85     FALSE 0.0000000          0.0000000
#> 86     FALSE 0.0000000          0.0000000
#> 87     FALSE 0.0000000          0.0000000
#> 88     FALSE 0.0000000          0.0000000
#> 89     FALSE 0.0000000          0.0000000
#> 90      TRUE 0.6931472          1.0000000
#> 91     FALSE 0.0000000          0.0000000
#> 92     FALSE 0.0000000          0.0000000
#> 93     FALSE 0.0000000          0.0000000
#> 94     FALSE 0.0000000          0.0000000
#> 95     FALSE 0.0000000          0.0000000
#> 96     FALSE 0.0000000          0.0000000
#> 97     FALSE 0.0000000          0.0000000
#> 98      TRUE 0.6931472          1.0000000
#> 99     FALSE 0.0000000          0.0000000
#> 100     TRUE 0.6931472          1.0000000
#> 101    FALSE 0.0000000          0.0000000
#> 102     TRUE 0.6931472          1.0000000
#> 103    FALSE 0.0000000          0.0000000
#> 104    FALSE 0.0000000          0.0000000
#> 105    FALSE 0.0000000          0.0000000
#> 106    FALSE 0.0000000          0.0000000
#> 107    FALSE 0.0000000          0.0000000
#> 108    FALSE 0.0000000          0.0000000
#> 109    FALSE 0.0000000          0.0000000
#> 110    FALSE 0.0000000          0.0000000
#> 111    FALSE 0.0000000          0.0000000
#> 112     TRUE 0.6931472          1.0000000
#> 113    FALSE 0.0000000          0.0000000
#> 114     TRUE 0.6931472          1.0000000
#> 115    FALSE 0.0000000          0.0000000
#> 116     TRUE 0.6931472          1.0000000
#> 117    FALSE 0.0000000          0.0000000
#> 118     TRUE 0.6931472          1.0000000
#> 119    FALSE 0.0000000          0.0000000
#> 120     TRUE 0.6931472          1.0000000
#> 121    FALSE 0.0000000          0.0000000
#> 122     TRUE 0.6931472          1.0000000
#> 123    FALSE 0.0000000          0.0000000
#> 124     TRUE 0.6931472          1.0000000
#> 125    FALSE 0.0000000          0.0000000
#> 126     TRUE 0.6931472          1.0000000
#> 127     TRUE 0.6365142          0.5793802
#> 128    FALSE 0.0000000          0.0000000
```
