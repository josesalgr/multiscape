test_that("single-objective solve returns a Solution and respects locked units", {
  skip_if_no_cbc()

  toy <- toy_equivalent_basic()
  toy$pu$locked_in[1] <- 1
  toy$pu$locked_out[4] <- 1

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects, effect_type = "after") |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_constraint_locked_pu(locked_in = "locked_in", locked_out = "locked_out") |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  expect_s3_class(s, "SolutionSet")

  acts <- multiscape::get_actions(s, only_selected = TRUE)
  expect_true(any(acts$pu == 1))
  expect_false(any(acts$pu == 4))
})
