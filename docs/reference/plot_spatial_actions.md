# Plot selected actions in space

Plot the spatial distribution of selected actions from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

This function maps the selected planning unit–action pairs returned by
[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md)
onto the planning-unit geometry stored in the associated `Problem`
object.

## Usage

``` r
plot_spatial_actions(
  x,
  runs = NULL,
  actions = NULL,
  layout = NULL,
  max_facets = 4L,
  ...,
  base_alpha = 0.08,
  selected_alpha = 0.95,
  base_fill = "grey95",
  base_color = NA,
  selected_color = NA,
  draw_borders = FALSE,
  show_base = TRUE,
  fill_values = NULL,
  fill_na = "grey80",
  use_viridis = TRUE
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

- actions:

  Optional action subset to display. Entries may match action ids or
  action-set labels.

- layout:

  Character string controlling the layout. Must be one of `"single"` or
  `"facet"`. If `NULL`, the default is `"single"`.

- max_facets:

  Maximum number of action facets shown when `actions` is `NULL` and
  faceting would otherwise create many panels.

- ...:

  Reserved for future extensions.

- base_alpha:

  Numeric value in \\\[0,1\]\\ giving the alpha of the base
  planning-unit layer.

- selected_alpha:

  Numeric value in \\\[0,1\]\\ giving the alpha of the highlighted
  action layer.

- base_fill:

  Fill colour for the base planning-unit layer.

- base_color:

  Border colour for the base planning-unit layer.

- selected_color:

  Border colour for highlighted layers.

- draw_borders:

  Logical. If `FALSE`, borders are not drawn.

- show_base:

  Logical. If `TRUE`, draw the base planning-unit layer underneath the
  highlighted output.

- fill_values:

  Optional named vector of colours for discrete action maps.

- fill_na:

  Fill colour for missing values.

- use_viridis:

  Logical. If `TRUE` and the viridis package is available, use viridis
  discrete scales.

## Value

Invisibly returns a `ggplot` object.

## Details

Let \\x\_{ia} \in \\0,1\\\\ denote whether action \\a\\ is selected in
planning unit \\i\\. This function plots the selected `(pu, action)`
pairs in geographic space.

If `layout = "facet"` and only one run is plotted, one panel is drawn
per action.

If `layout = "single"`, all selected actions are drawn in a single map
using discrete fills. If more than one action is selected in the same
planning unit, the action labels are collapsed using `"+"`.

When plotting multiple runs, only `layout = "single"` is supported.

Planning-unit geometry must be available in the associated problem
object.

## See also

[`get_actions`](https://josesalgr.github.io/multiscape/reference/get_actions.md),
[`plot_spatial`](https://josesalgr.github.io/multiscape/reference/plot_spatial.md),
[`plot_spatial_pu`](https://josesalgr.github.io/multiscape/reference/plot_spatial_pu.md),
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

  actions <- data.frame(
    id = c("conservation", "restoration")
  )

  effects <- data.frame(
    action = actions$id,
    feature = 1L,
    multiplier = c(1.0, 1.5)
  )

  problem <- create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  ) |>
    add_actions(
      actions = actions,
      cost = c(
        conservation = 1,
        restoration = 2
      )
    ) |>
    add_effects(
      effects = effects,
      effect_type = "after"
    ) |>
    add_constraint_targets_relative(0.25) |>
    add_objective_min_cost(alias = "cost") |>
    set_solver_cbc(verbose = FALSE)

  solutions <- solve(problem)

  plot_spatial_actions(
    solutions,
    layout = "single"
  )
}

```
