# Set the weighted-sum multi-objective method

Configure a `Problem` object to be solved with a weighted-sum
multi-objective method.

In the weighted-sum method, several registered atomic objectives are
combined into a single scalar objective using a weighted linear
combination. This function stores that configuration in `x$data$method`
so that it can be used later by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## Usage

``` r
set_method_weighted_sum(
  x,
  aliases,
  runs = NULL,
  weights = NULL,
  normalize_weights = NULL,
  objective_scaling = FALSE,
  control = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- aliases:

  Character vector of objective aliases to combine. Each alias must
  correspond to a previously registered atomic objective.

- runs:

  A run design created with
  [`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  or
  [`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).
  For weighted-sum methods, automatic grids define weight combinations,
  while manual runs must contain columns named `weight_<alias>`.

- weights:

  Deprecated. Numeric vector of weights, with the same length and order
  as `aliases`. This argument is kept for backwards compatibility and is
  internally converted to `runs = set_runs_manual(...)`. New code should
  use `runs` instead.

- normalize_weights:

  Logical or `NULL`. If `TRUE`, normalize the weights in each run to sum
  to one before solving. If `FALSE`, manual weights are used exactly as
  supplied. If `NULL`, the default is resolved from the run design:
  automatic grids are normalized and manual designs are not normalized.

- objective_scaling:

  Logical. If `TRUE`, request scaling of the participating objectives
  before weighted aggregation in the solving layer.

- control:

  A control object created with
  [`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md).
  It controls how infeasible runs, runs without a solution, and
  unexpected errors are handled.

## Value

The updated `Problem` object with the weighted-sum method configuration
stored in `x$data$method`.

## Details

Use this method when several registered objectives should be combined
into a single scalar optimization problem through explicit preference
weights.

**General idea**

Suppose that a set of atomic objectives has already been registered in
the problem under aliases \\k \in \mathcal{K}\\. Let \\f_k(x)\\ denote
the scalar value of objective \\k\\, and let \\w_k\\ denote its weight.

The weighted-sum method combines them into a single scalar objective of
the form:

\$\$ \sum\_{k \in \mathcal{K}} w_k \\ f_k(x). \$\$

In practice, the exact sign convention used internally depends on the
sense of each registered atomic objective, for example whether it is a
minimization-type or maximization-type objective. The solving layer is
responsible for constructing a solver-ready scalar objective from the
stored objective specifications and the requested weights.

**Run designs**

Weighted-sum runs are specified through the `runs` argument. This
argument must be created with either
[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
or
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md).

`set_runs_grid(n = ...)` automatically generates a grid of weight
combinations. For two objectives, this is a regular sequence of weights
along the line between the two pure-objective extremes. For three or
more objectives, the grid is generated over the weight simplex, where
all weights are non-negative and sum to one.

Boundary weight combinations are always included in automatic grids.
This means that pure-objective weight vectors are included, where all
weight is assigned to one objective.

[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
allows users to provide explicit weight combinations. In manual
weighted-sum runs, each row is one optimization run and columns must be
named `weight_<alias>`. For example, if
`aliases = c("cost", "benefit")`, the manual run table must contain
columns `weight_cost` and `weight_benefit`.

The older `weights` argument is deprecated. It is still accepted for
backwards compatibility and is internally converted to a one-row
[`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
design.

**Atomic objectives requirement**

The weighted-sum method can only be used with atomic objectives that
have already been registered under aliases. These aliases are typically
created by calling objective setters with an `alias` argument, for
example:


    x <- x |>
      add_objective_min_cost(alias = "cost") |>
      add_objective_min_fragmentation(alias = "frag")

Internally, each atomic objective is stored in
`x$data$objectives[[alias]]` together with its metadata, such as:

- `objective_id`,

- `model_type`,

- `sense`,

- `objective_args`.

The `aliases` argument passed to this function selects which of those
registered atomic objectives are included in the weighted combination.

**Weight normalization**

The default value of `normalize_weights` is `NULL`. In this case, the
default behaviour depends on the run design:

- automatic grids created with
  [`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  use `normalize_weights = TRUE`;

- manual designs created with
  [`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
  use `normalize_weights = FALSE`.

If `normalize_weights = TRUE`, the weights in each run are rescaled to
sum to one:

\$\$ \tilde{w}\_k = \frac{w_k}{\sum\_{j \in \mathcal{K}} w_j}. \$\$

This normalization does not change the optimizer's solution in a pure
weighted-sum formulation as long as all weights are multiplied by the
same positive constant, but it can improve interpretability and
numerical conditioning.

If `normalize_weights = FALSE`, manual weights are used exactly as
supplied. Automatic grids generated by
[`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
are already constructed on a normalized simplex.

**Objective scaling**

If `objective_scaling = TRUE`, the solving layer scales the
participating objectives before combining them. The purpose of scaling
is to reduce distortions caused by objectives being measured on very
different numerical ranges.

Conceptually, if \\R_k\\ denotes a scale or range associated with
objective \\k\\, then a scaled weighted sum may be interpreted as:

\$\$ \sum\_{k \in \mathcal{K}} w_k \\ \frac{f_k(x)}{R_k}. \$\$

The exact scaling rule is implemented in the solving layer.

**Mixed objective senses**

Weighted sums are straightforward when all participating objectives have
the same optimization sense. When minimization and maximization
objectives are mixed, the solving layer standardizes them internally
before building the scalar objective.

Users should provide non-negative weights according to the original
meaning of each objective. For example, a positive weight on a
maximization objective means that higher values of that objective are
preferred.

**Failure handling**

The `control` argument controls how failed runs are handled. It must be
created with
[`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md).

Weighted-sum runs do not normally introduce additional constraints, so
they should not usually create infeasible subproblems by themselves.
However, runs may still fail if the underlying model is infeasible, the
solver stops before finding a feasible solution, or a numerical/modeling
issue occurs. The `control` argument determines whether such failures
stop the whole solve or are retained in the returned `SolutionSet` with
missing objective values.

**Theoretical limitation**

The weighted-sum method typically recovers only *supported* efficient
solutions, that is, solutions lying on the convex hull of the Pareto
front in objective space. In non-convex multi-objective problems,
especially mixed integer problems, some efficient solutions cannot be
obtained by any weighted combination. In such cases, methods such as
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md)
or
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)
may be preferable.

**Stored configuration**

This function stores the method definition in `x$data$method` with:

- `name = "weighted"`,

- `type = "weighted"`,

- `aliases`,

- `runs`,

- `normalize_weights`,

- `objective_scaling`,

- `control`.

The actual scalarization is performed later by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

## See also

[`set_runs_grid`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md),
[`set_runs_manual`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md),
[`set_runs_control`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md),
[`set_method_epsilon_constraint`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md),
[`set_method_augmecon`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md),
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md)

## Examples

``` r
# Small toy problem
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

actions_df <- data.frame(
  id = c("conservation", "restoration"),
  name = c("conservation", "restoration")
)

effects_df <- data.frame(
  pu = c(1, 2, 3, 4, 1, 2, 3, 4),
  action = c("conservation", "conservation", "conservation", "conservation",
             "restoration", "restoration", "restoration", "restoration"),
  feature = c(1, 1, 1, 1, 2, 2, 2, 2),
  benefit = c(2, 1, 0, 1, 3, 0, 1, 2),
  loss = c(0, 0, 1, 0, 0, 1, 0, 0)
)

x <- create_problem(
  pu = pu_tbl,
  features = feat_tbl,
  dist_features = dist_feat_tbl,
  cost = "cost"
) |>
  add_actions(actions_df, cost = c(conservation = 1, restoration = 2)) |>
  add_effects(effects_df) |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_max_benefit(alias = "benefit")

# Automatic weight grid
x1 <- set_method_weighted_sum(
  x,
  aliases = c("cost", "benefit"),
  runs = set_runs_grid(n = 5),
  objective_scaling = TRUE
)

x1$data$method
#> $name
#> [1] "weighted"
#> 
#> $type
#> [1] "weighted"
#> 
#> $aliases
#> [1] "cost"    "benefit"
#> 
#> $runs
#> $type
#> [1] "grid"
#> 
#> $n
#> [1] 5
#> 
#> $include_extremes
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunGrid"   "RunDesign"
#> 
#> $normalize_weights
#> [1] TRUE
#> 
#> $objective_scaling
#> [1] TRUE
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Manual weighted runs
manual_weights <- data.frame(
  weight_cost = c(1.0, 0.75, 0.50, 0.25, 0.0),
  weight_benefit = c(0.0, 0.25, 0.50, 0.75, 1.0)
)

x2 <- set_method_weighted_sum(
  x,
  aliases = c("cost", "benefit"),
  runs = set_runs_manual(manual_weights),
  objective_scaling = TRUE
)

x2$data$method
#> $name
#> [1] "weighted"
#> 
#> $type
#> [1] "weighted"
#> 
#> $aliases
#> [1] "cost"    "benefit"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   weight_cost weight_benefit
#> 1        1.00           0.00
#> 2        0.75           0.25
#> 3        0.50           0.50
#> 4        0.25           0.75
#> 5        0.00           1.00
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $normalize_weights
#> [1] FALSE
#> 
#> $objective_scaling
#> [1] TRUE
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Manual runs with automatic weight normalization
manual_weights2 <- data.frame(
  weight_cost = c(2, 1, 1),
  weight_benefit = c(1, 1, 3)
)

x3 <- set_method_weighted_sum(
  x,
  aliases = c("cost", "benefit"),
  runs = set_runs_manual(manual_weights2),
  normalize_weights = TRUE
)

x3$data$method
#> $name
#> [1] "weighted"
#> 
#> $type
#> [1] "weighted"
#> 
#> $aliases
#> [1] "cost"    "benefit"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   weight_cost weight_benefit
#> 1           2              1
#> 2           1              1
#> 3           1              3
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $normalize_weights
#> [1] TRUE
#> 
#> $objective_scaling
#> [1] FALSE
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Backwards-compatible deprecated usage
x4 <- set_method_weighted_sum(
  x,
  aliases = c("cost", "benefit"),
  weights = c(0.4, 0.6),
  normalize_weights = FALSE
)
#> Warning: `weights` is deprecated. Use `runs = set_runs_manual(data.frame(weight_<alias> = ...))` instead.

x4$data$method
#> $name
#> [1] "weighted"
#> 
#> $type
#> [1] "weighted"
#> 
#> $aliases
#> [1] "cost"    "benefit"
#> 
#> $runs
#> $type
#> [1] "manual"
#> 
#> $values
#>   weight_cost weight_benefit
#> 1         0.4            0.6
#> 
#> attr(,"class")
#> [1] "RunManual" "RunDesign"
#> 
#> $normalize_weights
#> [1] FALSE
#> 
#> $objective_scaling
#> [1] FALSE
#> 
#> $control
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 
#> $stop_on_infeasible
#> [1] FALSE
#> 
#> $stop_on_no_solution
#> [1] FALSE
#> 
#> $stop_on_error
#> [1] TRUE
#> 

# Control failure handling
x5 <- set_method_weighted_sum(
  x,
  aliases = c("cost", "benefit"),
  runs = set_runs_grid(n = 5),
  control = set_runs_control(
    stop_on_infeasible = TRUE,
    stop_on_no_solution = TRUE,
    stop_on_error = TRUE
  )
)

x5$data$method
#> $name
#> [1] "weighted"
#> 
#> $type
#> [1] "weighted"
#> 
#> $aliases
#> [1] "cost"    "benefit"
#> 
#> $runs
#> $type
#> [1] "grid"
#> 
#> $n
#> [1] 5
#> 
#> $include_extremes
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunGrid"   "RunDesign"
#> 
#> $normalize_weights
#> [1] TRUE
#> 
#> $objective_scaling
#> [1] FALSE
#> 
#> $control
#> $stop_on_infeasible
#> [1] TRUE
#> 
#> $stop_on_no_solution
#> [1] TRUE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "RunsControl" "MOControl"   "list"       
#> 
#> $stop_on_infeasible
#> [1] TRUE
#> 
#> $stop_on_no_solution
#> [1] TRUE
#> 
#> $stop_on_error
#> [1] TRUE
#> 
```
