# Plot selected planning units in space

**\[deprecated\]**

`plot_spatial_pu()` has been replaced by
[`plot_spatial_planning_units`](https://josesalgr.github.io/multiscape/reference/plot_spatial_planning_units.md).

## Usage

``` r
plot_spatial_pu(
  x,
  solutions = NULL,
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

- solutions:

  Optional integer vector of solution ids. If `NULL`, the first
  available solution is plotted by default.

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

## See also

[`plot_spatial_planning_units`](https://josesalgr.github.io/multiscape/reference/plot_spatial_planning_units.md)
