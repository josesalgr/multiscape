# Add rook adjacency from polygons

Build and register a rook adjacency relation from planning-unit
polygons.

Two planning units are rook-adjacent if they share a boundary segment of
positive length. Corner-only contact does not count as rook adjacency.

## Usage

``` r
add_spatial_rook(x, geometry = NULL, name = "rook", weight = 1)
```

## Arguments

- x:

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  or another object containing aligned planning-unit polygons.

- geometry:

  Optional `sf` object with planning-unit polygons and an `id` column.
  If `NULL`, `x$data$pu_sf` is used.

- name:

  Character string giving the key under which the relation is stored.

- weight:

  Numeric scalar giving the edge weight assigned to each rook adjacency.

## Value

An updated `Problem` object.

## Details

Use this function when neighbourhood should be defined by shared polygon
edges rather than by point-touching or coordinate-based proximity.

This constructor derives an adjacency graph from polygon geometry using
a rook criterion. If planning units \\i\\ and \\j\\ share a common edge
of non-zero length, then an edge \\(i,j)\\ is added to the relation.

Let \\G = (\mathcal{I}, E)\\ denote the resulting graph. Then: \$\$
(i,j) \in E \quad \Longleftrightarrow \quad \mathrm{length}(\partial i
\cap \partial j) \> 0. \$\$

All edges receive the same user-supplied weight.

The resulting relation is stored as an undirected spatial relation.

## See also

[`add_spatial_queen`](https://josesalgr.github.io/multiscape/reference/add_spatial_queen.md),
[`add_spatial_boundary`](https://josesalgr.github.io/multiscape/reference/add_spatial_boundary.md)

## Examples

``` r
# \donttest{
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

p <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
)

p <- add_spatial_rook(
  x = p,
  geometry = example_data$planning_units,
  name = "rook",
  weight = 1
)

head(p$data$spatial_relations$rook)
#>    internal_pu1 internal_pu2 weight pu1 pu2  source relation_name
#> 28           10           11      1  10  11 rook_sf          rook
#> 29           10           18      1  10  18 rook_sf          rook
#> 32           11           12      1  11  12 rook_sf          rook
#> 33           11           19      1  11  19 rook_sf          rook
#> 36           12           13      1  12  13 rook_sf          rook
#> 37           12           20      1  12  20 rook_sf          rook
# }
```
