test_that("get_actions returns selected actions for Solution", {
  skip_if_no_cbc()

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
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  a_all <- multiscape::get_actions(s)
  expect_true(is.data.frame(a_all))
  expect_gt(nrow(a_all), 0)

  a_sel <- multiscape::get_actions(s, only_selected = TRUE)
  expect_true(is.data.frame(a_sel))
})

test_that("get_actions returns actions for SolutionSet run", {
  skip_if_no_cbc()

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
    multiscape::add_objective_min_fragmentation_pu(alias = "frag") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "frag"),
      runs = multiscape::run_manual(
        data.frame(
          weight_cost = 1,
          weight_frag = 1
        )
      )
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  a <- multiscape::get_actions(s, run = 1)
  expect_true(is.data.frame(a))
})
