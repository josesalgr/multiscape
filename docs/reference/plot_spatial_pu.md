# Plot selected planning units in space

Plot the spatial distribution of selected planning units from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

This function maps the planning-unit selection summary returned by
[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md)
onto the planning-unit geometry stored in the associated `Problem`
object.

## Usage

``` r
plot_spatial_pu(
  x,
  runs = NULL,
  ...,
  base_alpha = 0.1,
  selected_alpha = 0.9,
  base_fill = "grey92",
  base_color = NA,
  selected_color = NA,
  draw_borders = FALSE,
  show_base = TRUE
)
```

## Arguments

- x:

  A
  [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  object returned by
  [`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

- runs:

  Optional integer vector of run ids. If `NULL`, the first available run
  is plotted by default.

- ...:

  Reserved for future extensions.

- base_alpha:

  Numeric value in \\\[0,1\]\\ giving the alpha of the base
  planning-unit layer.

- selected_alpha:

  Numeric value in \\\[0,1\]\\ giving the alpha of the selected
  planning-unit layer.

- base_fill:

  Fill colour for the base planning-unit layer.

- base_color:

  Border colour for the base planning-unit layer.

- selected_color:

  Border colour for selected planning units.

- draw_borders:

  Logical. If `FALSE`, borders are not drawn.

- show_base:

  Logical. If `TRUE`, draw the base planning-unit layer underneath the
  selected units.

## Value

Invisibly returns a `ggplot` object.

## Details

Let \\w_i \in \\0,1\\\\ denote the planning-unit selection variable for
planning unit \\i\\. This function plots the user-facing `selected == 1`
representation of \\w_i\\.

If several runs are requested, the output is faceted by `run_id`.

Planning-unit geometry must be available in the associated problem
object.

## See also

[`get_pu`](https://josesalgr.github.io/multiscape/reference/get_pu.md),
[`plot_spatial`](https://josesalgr.github.io/multiscape/reference/plot_spatial.md),
[`plot_spatial_actions`](https://josesalgr.github.io/multiscape/reference/plot_spatial_actions.md),
[`plot_spatial_features`](https://josesalgr.github.io/multiscape/reference/plot_spatial_features.md)

## Examples

``` r
if (
  requireNamespace("sf", quietly = TRUE) &&
  requireNamespace("ggplot2", quietly = TRUE) &&
  requireNamespace("rcbc", quietly = TRUE)
) {
  data("sim_pu_sf", package = "multiscape")

  pu <- sim_pu_sf[
    seq_len(min(4L, nrow(sim_pu_sf))),
  ]

  pu$id <- seq_len(nrow(pu))
  pu$cost <- seq_len(nrow(pu))

  features <- data.frame(
    id = 1L,
    name = "feature_1"
  )

  dist_features <- data.frame(
    pu = pu$id,
    feature = 1L,
    amount = rep(1, nrow(pu))
  )

  problem <- create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  ) |>
    add_constraint_targets_relative(0.25) |>
    add_objective_min_cost(alias = "cost") |>
    set_solver_cbc(verbose = FALSE)

  solutions <- solve(problem)

  plot_spatial_pu(solutions)
}

```
