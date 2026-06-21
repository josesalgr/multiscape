test_that("multiscape matches prioritizr on a one-action boundary-penalized problem", {
  skip_if_no_cbc()
  skip_if_no_prioritizr()

  toy <- toy_equivalent_basic()

  bnd <- toy$boundary
  names(bnd)[names(bnd) == "pu1"] <- "id1"
  names(bnd)[names(bnd) == "pu2"] <- "id2"

  p_multiscape <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = toy$effects, effect_type = "after") |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_spatial_boundary(boundary = toy$boundary, include_self = FALSE) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_min_fragmentation_planning_units(alias = "frag") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "frag"),
      runs = multiscape::set_runs_manual(
        data.frame(
          weight_cost = 1,
          weight_frag = 1
        )
      )
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s_multiscape <- multiscape::solve(p_multiscape)
  acts_multiscape <- multiscape::get_actions(s_multiscape, solution = 1)
  acts_multiscape <- acts_multiscape[acts_multiscape$selected == 1L, , drop = FALSE]
  sel_multiscape <- sort(unique(acts_multiscape$pu))
  cost_multiscape <- sum(toy$pu$cost[toy$pu$id %in% sel_multiscape])

  p_prio <- build_prioritizr_basic(
    toy,
    target = 0.5,
    boundary_matrix = bnd
  )

  s_prio <- solve_prioritizr(p_prio)

  sel_prio <- sort(which(s_prio$solution_1 > 0.5))
  cost_prio <- sum(toy$pu$cost[toy$pu$id %in% sel_prio])

  expect_equal(cost_multiscape, cost_prio)
  expect_equal(sel_multiscape, sel_prio)
})
