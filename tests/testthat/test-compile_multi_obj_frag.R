test_that("compile_model builds MO superset with boundary auxiliaries when fragmentation is included", {
  toy <- toy_equivalent_basic()

  p2 <- multiscape::create_problem(
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
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "frag"),
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_frag = 1))
    )

  p2 <- multiscape::compile_model(p2)

  expect_s3_class(p2, "Problem")
  expect_false(is.null(p2$data$model_ptr))
  expect_true(is.list(p2$data$model_list))
  expect_false(isTRUE(p2$data$meta$model_dirty))

  n_y_pu <- as.integer(p2$data$model_list$n_y_pu %||% 0L)
  expect_gt(n_y_pu, 0)
})
