test_that("compile_model can be called twice on an already compiled single-objective problem", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_objective_min_cost(alias = "cost")

  p1 <- multiscape::compile_model(p)
  p2 <- multiscape::compile_model(p1)

  expect_s3_class(p1, "Problem")
  expect_s3_class(p2, "Problem")

  expect_false(is.null(p1$data$model_ptr))
  expect_false(is.null(p2$data$model_ptr))

  expect_true(is.list(p1$data$model_list))
  expect_true(is.list(p2$data$model_list))

  expect_false(isTRUE(p1$data$meta$model_dirty))
  expect_false(isTRUE(p2$data$meta$model_dirty))
})

test_that("compile_model(force = TRUE) recompiles a single-objective problem", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_objective_min_cost(alias = "cost")

  p <- multiscape::compile_model(p)
  p <- multiscape::compile_model(p, force = TRUE)

  expect_s3_class(p, "Problem")
  expect_false(is.null(p$data$model_ptr))
  expect_true(is.list(p$data$model_list))
  expect_false(isTRUE(p$data$meta$model_dirty))
})
