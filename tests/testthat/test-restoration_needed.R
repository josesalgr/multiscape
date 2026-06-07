test_that("solve uses restoration when restoration-only feature target requires it", {
  skip_if_no_cbc()

  toy <- toy_multiaction_semantics()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects, effect_type = "after") |>
    multiscape::add_constraint_targets_relative(0.8, features = 2) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  expect_s3_class(s, "SolutionSet")
  actions <- multiscape::get_actions(s)
  expect_true(is.data.frame(actions))

  acts_sel <- actions[actions$selected > 0.5, , drop = FALSE]

  expect_true(any(acts_sel$action == "restoration"))
})
