# Plot spatial feature values from a solution set

Plot feature values in space from a
[`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
object returned by
[`solve`](https://josesalgr.github.io/multiscape/reference/solve.md).

This function combines baseline feature amounts from the associated
`Problem` object with positive effects induced by selected actions to
produce planning-unit-level feature maps.

## Usage

``` r
plot_spatial_features(
  x,
  runs = NULL,
  features = NULL,
  value = c("final", "baseline", "benefit"),
  layout = NULL,
  max_facets = 4L,
  ...,
  base_alpha = 0.1,
  selected_alpha = 0.9,
  base_fill = "grey92",
  base_color = NA,
  selected_color = NA,
  draw_borders = FALSE,
  show_base = TRUE,
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

- features:

  Optional feature subset to display. Matching is attempted against both
  feature ids and feature names.

- value:

  Character string indicating which feature quantity to plot. Must be
  one of `"final"`, `"baseline"`, or `"benefit"`.

- layout:

  Character string controlling the layout. Must be one of `"single"` or
  `"facet"`. If `NULL`, the default is `"facet"`.

- max_facets:

  Maximum number of feature facets shown when `features = NULL` and
  faceting would otherwise create many panels.

- ...:

  Reserved for future extensions.

- base_alpha:

  Unused in the current feature view, kept for interface consistency.

- selected_alpha:

  Unused in the current feature view, kept for interface consistency.

- base_fill:

  Unused in the current feature view, kept for interface consistency.

- base_color:

  Unused in the current feature view, kept for interface consistency.

- selected_color:

  Border colour for filled feature polygons.

- draw_borders:

  Logical. If `FALSE`, borders are not drawn.

- show_base:

  Unused in the current feature view, kept for interface consistency.

- fill_na:

  Fill colour for missing values.

- use_viridis:

  Logical. If `TRUE` and the viridis package is available, use a
  continuous viridis scale.

## Value

Invisibly returns a `ggplot` object.

## Details

For each planning unit \\i\\ and feature \\f\\, the plotted quantities
are: \$\$ \mathrm{baseline}\_{if}, \$\$ \$\$ \mathrm{benefit}\_{if},
\$\$ \$\$ \mathrm{final}\_{if} = \mathrm{baseline}\_{if} +
\mathrm{benefit}\_{if}. \$\$

In the current implementation:

- `baseline` is the summed baseline amount from `dist_features`;

- `benefit` is the summed positive effect from selected actions;

- `final` is `baseline + benefit`.

Negative effects are not subtracted in this plotting method. Therefore,
`value = "final"` should be interpreted as baseline plus selected
positive effects under the current plotting logic.

If `layout = "facet"` and only one run is plotted, one panel is drawn
per feature.

If multiple runs are plotted, exactly one feature must be requested, and
faceting is done by run.

Planning-unit geometry must be available in the associated problem
object.

## See also

[`get_features`](https://josesalgr.github.io/multiscape/reference/get_features.md),
[`plot_spatial`](https://josesalgr.github.io/multiscape/reference/plot_spatial.md),
[`plot_spatial_pu`](https://josesalgr.github.io/multiscape/reference/plot_spatial_pu.md),
[`plot_spatial_actions`](https://josesalgr.github.io/multiscape/reference/plot_spatial_actions.md)

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  data("sim_pu_sf", package = "multiscape")

  n <- min(6, nrow(sim_pu_sf))
  ids <- sim_pu_sf$id[seq_len(n)]

  features_df <- data.frame(
    id = c(1, 2),
    name = c("feature_1", "feature_2")
  )

  dist_features_df <- data.frame(
    pu = rep(ids, times = 2),
    feature = rep(c(1, 2), each = n),
    amount = c(seq_len(n), rev(seq_len(n)))
  )

  dist_effects_df <- data.frame(
    pu = ids,
    action = "conservation",
    feature = rep(c(1, 2), length.out = n),
    benefit = rep(1, n)
  )

  actions_df <- data.frame(
    id = "conservation",
    name = "conservation"
  )

  problem <- structure(
    list(
      data = list(
        pu_sf = sim_pu_sf,
        features = features_df,
        dist_features = dist_features_df,
        dist_effects = dist_effects_df,
        actions = actions_df
      )
    ),
    class = "Problem"
  )

  run_result <- list(
    problem = problem,
    summary = list(
      actions = data.frame(
        pu = ids,
        action = "conservation",
        selected = 1L
      )
    )
  )

  solset <- structure(
    list(
      solution = list(
        solutions = list(run_result)
      )
    ),
    class = "SolutionSet"
  )

  plot_spatial_features(solset, features = "feature_1", value = "final")
}

```
