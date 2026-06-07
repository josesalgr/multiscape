test_that("single-objective solve returns a one-run SolutionSet", {
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

  expect_s3_class(s, "SolutionSet")
  expect_true(inherits(s$problem, "Problem"))
  expect_true(is.list(s$solution))
  expect_true(is.list(s$summary))
  expect_true(is.list(s$diagnostics))
  expect_equal(nrow(multiscape::get_runs(s)), 1L)
  expect_equal(sum(!is.na(multiscape::get_runs(s)$solution_id)), 1L)
})

test_that("weighted solve returns a SolutionSet with core components", {
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

  expect_s3_class(s, "SolutionSet")
  expect_true("problem" %in% names(s))
  expect_true("solution" %in% names(s))
  expect_true("summary" %in% names(s))
  expect_true("diagnostics" %in% names(s))

  expect_true(is.list(s$solution))
  expect_true("runs" %in% names(s$solution))
  expect_true("solutions" %in% names(s$solution))
})
