test_that("compile_model builds a single-objective cost model without boundary auxiliaries", {
  toy <- toy_equivalent_basic()

  p1 <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_objective_min_cost(alias = "cost")

  p1 <- multiscape::compile_model(p1)

  expect_s3_class(p1, "Problem")
  expect_false(is.null(p1$data$model_ptr))
  expect_true(is.list(p1$data$model_list))
  expect_false(isTRUE(p1$data$meta$model_dirty))

  n_y_pu <- as.integer(p1$data$model_list$n_y_pu %||% 0L)
  expect_identical(n_y_pu, 0L)
})
