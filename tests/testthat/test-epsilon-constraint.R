test_that("epsilon-constraint returns a SolutionSet with runs", {
  skip_if_no_cbc()

  toy <- toy_equivalent_basic()

  bnd <- toy$boundary
  names(bnd)[names(bnd) == "id1"] <- "pu1"
  names(bnd)[names(bnd) == "id2"] <- "pu2"

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = toy$actions,
      cost = 0
    ) |>
    multiscape::add_effects(
      effects = toy$effects,
      effect_type = "after"
    ) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_spatial_boundary(
      boundary = bnd,
      weight_col = "boundary",
      include_self = TRUE
    ) |>
    multiscape::add_objective_min_cost(
      alias = "cost"
    ) |>
    multiscape::add_objective_min_fragmentation_planning_units(
      alias = "frag"
    ) |>
    multiscape::set_method_epsilon_constraint(
      primary = "cost",
      aliases = c("cost", "frag"),
      runs = multiscape::set_runs_grid(
        n = 3
      )
    ) |>
    multiscape::set_solver_cbc(
      gap_limit = 0,
      verbose = FALSE
    )

  s <- multiscape::solve(p)

  expect_s3_class(s, "SolutionSet")

  runs <- multiscape::get_runs(s)

  expect_s3_class(runs, "data.frame")
  expect_equal(nrow(runs), 3L)

  expect_true(
    all(c(
      "run_id",
      "solution_id",
      "status"
    ) %in% names(runs))
  )

  expect_gte(
    sum(!is.na(runs$solution_id)),
    1L
  )
})
