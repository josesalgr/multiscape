test_that("solve selects at most one action per planning unit", {
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
    multiscape::add_constraint_targets_relative(0.2, features = 1) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  expect_s3_class(s, "SolutionSet")
  acts <- multiscape::get_actions(s)
  expect_true(is.data.frame(acts))
  acts_sel <- acts[acts$selected > 0.5, , drop = FALSE]

  if (nrow(acts_sel) > 0) {
    n_by_pu <- table(acts_sel$pu)
    expect_true(all(as.integer(n_by_pu) <= 1L))
  } else {
    succeed()
  }
})
