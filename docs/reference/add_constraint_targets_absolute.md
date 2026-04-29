# Add absolute targets

Add feature-level absolute targets to a planning problem.

These targets are stored in the problem object and later translated into
linear constraints when the optimization model is built. Absolute
targets are interpreted directly in the same units as the feature
contributions used by the model. Each call appends one or more target
definitions to the problem. This makes it possible to combine multiple
target rules, including targets associated with different action
subsets.

## Usage

``` r
add_constraint_targets_absolute(
  x,
  targets,
  features = NULL,
  actions = NULL,
  label = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- targets:

  Target specification. This is interpreted as an absolute target value
  in the same units as the modelled feature contributions. It may be a
  scalar, vector, named vector, or `data.frame`. See Details.

- features:

  Optional feature specification indicating which features the supplied
  target values refer to when `targets` does not identify features
  explicitly. If `NULL`, all features are targeted.

- actions:

  Optional character vector indicating which actions count toward target
  achievement. Entries may match action ids, `action_set` labels, or
  both. If `NULL`, all actions count.

- label:

  Optional character string stored with the targets for reporting and
  bookkeeping.

## Value

An updated `Problem` object with absolute targets appended to the stored
target table.

## Details

Use this function when target requirements are naturally expressed in
the original units of the modelled feature contributions, rather than as
proportions of current baseline totals.

Let \\\mathcal{F}\\ denote the set of features. For each targeted
feature \\f \in \mathcal{F}\\, this function stores an absolute target
threshold \\T_f \ge 0\\.

When the optimization model is built, each such target is interpreted as
a lower-bound constraint of the form: \$\$ \sum\_{(i,a) \in
\mathcal{D}\_f^{\star}} c\_{iaf} x\_{ia} \ge T_f, \$\$ where:

- \\i \in \mathcal{I}\\ indexes planning units,

- \\a \in \mathcal{A}\\ indexes actions,

- \\x\_{ia}\\ indicates whether action \\a\\ is selected in planning
  unit \\i\\,

- \\c\_{iaf}\\ is the contribution of that action to feature \\f\\,

- \\\mathcal{D}\_f^{\star}\\ is the subset of planning unit–action pairs
  allowed to count toward the target for feature \\f\\.

In the absolute case, the stored target threshold is simply: \$\$ T_f =
t_f, \$\$ where \\t_f\\ is the user-supplied target value for feature
\\f\\.

The `actions` argument restricts which actions may contribute toward
achievement of the target, but it does not modify the value of \\T_f\\
itself.

The `targets` argument is parsed by `.pa_parse_targets()` and may be
supplied in several equivalent forms, including:

- a single numeric value recycled to all selected features,

- a numeric vector aligned to `features`,

- a named numeric vector where names identify features,

- a `data.frame` with `feature` and `target` columns.

If `targets` does not explicitly identify features:

- if `features = NULL`, the target is applied to all features,

- if `features` is supplied, the target values are interpreted with
  respect to that feature set.

Repeated calls append new target rules rather than replacing previous
ones. This allows cumulative target modelling, including multiple rules
on the same feature with different contributing action subsets.

## See also

[`add_constraint_targets_relative`](https://josesalgr.github.io/multiscape/reference/add_constraint_targets_relative.md)

## Examples

``` r
pu_tbl <- data.frame(
  id = 1:4,
  cost = c(1, 2, 3, 4)
)

feat_tbl <- data.frame(
  id = 1:2,
  name = c("feature_1", "feature_2")
)

dist_feat_tbl <- data.frame(
  pu = c(1, 1, 2, 3, 4),
  feature = c(1, 2, 2, 1, 2),
  amount = c(5, 2, 3, 4, 1)
)

p <- create_problem(
  pu = pu_tbl,
  features = feat_tbl,
  dist_features = dist_feat_tbl,
  cost = "cost"
) |>
  add_actions(data.frame(id = "conservation", name = "conservation"), cost = 0)

# Same absolute target for all features
p1 <- add_constraint_targets_absolute(p, 3)
p1$data$targets
#>   feature    type sense target_unit target_raw basis_total target_value actions
#> 1       1 actions    ge    absolute          3          NA            3    <NA>
#> 2       2 actions    ge    absolute          3          NA            3    <NA>
#>   label                 created_at feature_name
#> 1  <NA> 2026-04-29 19:56:08.930995    feature_1
#> 2  <NA> 2026-04-29 19:56:08.930995    feature_2

# Different targets by feature
p2 <- add_constraint_targets_absolute(
  p,
  c("1" = 4, "2" = 2)
)
p2$data$targets
#>   feature    type sense target_unit target_raw basis_total target_value actions
#> 1       1 actions    ge    absolute          4          NA            4    <NA>
#> 2       2 actions    ge    absolute          2          NA            2    <NA>
#>   label                 created_at feature_name
#> 1  <NA> 2026-04-29 19:56:08.934873    feature_1
#> 2  <NA> 2026-04-29 19:56:08.934873    feature_2

# Restrict which actions count toward target achievement
p3 <- add_constraint_targets_absolute(
  p,
  2,
  actions = "conservation"
)
p3$data$targets
#>   feature    type sense target_unit target_raw basis_total target_value
#> 1       1 actions    ge    absolute          2          NA            2
#> 2       2 actions    ge    absolute          2          NA            2
#>        actions label                 created_at feature_name
#> 1 conservation  <NA> 2026-04-29 19:56:08.938296    feature_1
#> 2 conservation  <NA> 2026-04-29 19:56:08.938296    feature_2
```
