test_that("solve errors when multiple objectives are registered without a MO method", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects, effect_type = "after") |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_spatial_boundary(boundary = toy$boundary, include_self = TRUE) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_min_fragmentation_planning_units(alias = "frag") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  expect_error(
    multiscape::solve(p),
    "Multiple objectives are registered but no multi-objective method was selected"
  )
})
