test_that("solve errors for unknown MO method configuration", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_spatial_boundary(
      boundary = toy$boundary,
      weight_col = "boundary",
      include_self = TRUE
    ) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_min_fragmentation_planning_units(alias = "frag")

  p$data$method <- list(type = "not_a_method")

  expect_error(
    multiscape::solve(p),
    "Unknown|unsupported"
  )
})
