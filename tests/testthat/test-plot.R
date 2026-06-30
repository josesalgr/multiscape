test_that("plot_tradeoff returns ggplot output", {
  skip_if_no_cbc()
  testthat::skip_if_not_installed("ggplot2")

  p <- make_round2_action_problem(with_effects = TRUE) |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(n = 3),
      normalize_weights = TRUE
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  out <- multiscape::plot_tradeoff(
    s,
    objectives = c("cost", "benefit")
  )

  expect_s3_class(out, "ggplot")

  expect_error(
    multiscape::plot_tradeoff(s, objectives = "cost"),
    "two"
  )
})


test_that("planning-unit spatial plots return ggplot output", {
  skip_if_no_cbc()
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")

  p <- make_round2_spatial_problem(action_based = FALSE) |>
    multiscape::add_constraint_targets_relative(0.25) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  expect_s3_class(
    multiscape::plot_spatial_planning_units(s),
    "ggplot"
  )

  expect_error(
    multiscape::plot_spatial_planning_units(s, solutions = 999L),
    "solution"
  )
})


test_that("action and feature spatial plots return ggplot output", {
  skip_if_no_cbc()
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")

  p <- make_round2_spatial_problem(action_based = TRUE) |>
    multiscape::add_constraint_targets_relative(0.25) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  expect_s3_class(
    multiscape::plot_spatial_actions(
      s,
      layout = "single"
    ),
    "ggplot"
  )

  expect_s3_class(
    multiscape::plot_spatial_features(
      s,
      features = "sp1",
      value = "final"
    ),
    "ggplot"
  )
})


test_that("plot_tradeoff covers labels, connections, and color mappings", {
  testthat::skip_if_not_installed("ggplot2")

  s <- solve_round3_multiobjective(n = 4)

  connected <- multiscape::plot_tradeoff(
    s,
    objectives = c("cost", "benefit"),
    connect = TRUE,
    label_runs = TRUE,
    color_by = "run_id"
  )

  expect_s3_class(connected, "ggplot")

  by_objective <- multiscape::plot_tradeoff(
    s,
    objectives = c("cost", "benefit"),
    color_by = "cost"
  )

  expect_s3_class(by_objective, "ggplot")

  expect_error(
    multiscape::plot_tradeoff(
      s,
      objectives = c("cost", "benefit"),
      color_by = "unknown"
    ),
    "color_by"
  )

  expect_error(
    multiscape::plot_tradeoff(
      s,
      objectives = c("cost", "unknown")
    ),
    "Unknown objective"
  )
})


test_that("spatial PU and implicit-action plots return ggplot objects", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")
  skip_if_no_cbc()

  p <- make_round3_spatial_problem(action_based = FALSE) |>
    multiscape::add_constraint_targets_relative(0.25) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)
  run_id <- multiscape::get_runs(s)$solution_id[1]

  expect_s3_class(
    multiscape::plot_spatial_planning_units(
      s,
      solutions = run_id
    ),
    "ggplot"
  )

  # Simple problems expose their implicit conservation decisions through the
  # action summary, so this is a valid action plot rather than an error case.
  expect_s3_class(
    multiscape::plot_spatial_actions(s),
    "ggplot"
  )
})


test_that("action and feature plots cover filters and value modes", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")
  skip_if_no_cbc()

  # Maximize positive restoration effects to guarantee selected actions.
  p <- make_round3_spatial_problem(action_based = TRUE) |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)

  expect_gt(
    nrow(multiscape::get_actions(s)),
    0L
  )

  expect_s3_class(
    multiscape::plot_spatial_actions(
      s,
      actions = "restoration",
      layout = "single"
    ),
    "ggplot"
  )

  expect_s3_class(
    multiscape::plot_spatial_features(
      s,
      features = "sp1",
      value = "baseline",
      layout = "single"
    ),
    "ggplot"
  )

  expect_s3_class(
    multiscape::plot_spatial_features(
      s,
      features = "sp2",
      value = "benefit",
      layout = "single"
    ),
    "ggplot"
  )

  expect_s3_class(
    multiscape::plot_spatial_features(
      s,
      features = "sp2",
      value = "final",
      layout = "single"
    ),
    "ggplot"
  )

  expect_error(
    multiscape::plot_spatial_actions(
      s,
      actions = "unknown"
    )
  )

  expect_error(
    multiscape::plot_spatial_features(
      s,
      features = "unknown"
    )
  )
})
