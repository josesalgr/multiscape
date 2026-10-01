test_that("compile_model errors when no objective is configured", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.5)

  expect_error(
    multiscape::compile_model(p),
    "No objective configured"
  )
})
