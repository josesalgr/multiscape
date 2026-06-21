test_that("multiscape matches prioritizr on a one-action min-cost problem", {
  skip_if_no_cbc()
  skip_if_no_prioritizr()

  toy <- toy_equivalent_basic()

  p_multiscape <- multiscape::create_problem(
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

  s_multiscape <- multiscape::solve(p_multiscape)

  acts_multiscape <- multiscape::get_actions(s_multiscape)
  acts_multiscape <- acts_multiscape[acts_multiscape$selected == 1L, , drop = FALSE]
  sel_multiscape <- sort(unique(acts_multiscape$pu))
  cost_multiscape <- sum(toy$pu$cost[toy$pu$id %in% sel_multiscape])

  p_prio <- build_prioritizr_basic(toy, target = 0.5)

  s_prio <- solve_prioritizr(p_prio)

  sel_prio <- sort(which(s_prio$solution_1 > 0.5))
  cost_prio <- sum(toy$pu$cost[toy$pu$id %in% sel_prio])

  expect_equal(cost_multiscape, cost_prio)
  expect_equal(sel_multiscape, sel_prio)
})
