test_that("augmecon returns a SolutionSet with runs", {
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
    multiscape::add_objective_min_fragmentation_pu(
      alias = "frag"
    ) |>
    multiscape::set_method_augmecon(
      primary = "cost",
      aliases = c("cost", "frag"),
      runs = multiscape::run_grid(
        n = 3,
        include_extremes = TRUE
      ),
      augmentation = 1e-3
    ) |>
    multiscape::set_solver_cbc(
      gap_limit = 0,
      verbose = FALSE
    )

  s <- multiscape::solve(p)

  expect_s3_class(s, "SolutionSet")

  runs <- multiscape::get_runs(s)

  expect_s3_class(runs, "data.frame")
  expect_gte(nrow(runs), 1L)
  expect_gte(
    sum(!is.na(runs$solution_id)),
    1L
  )

  expect_true(
    all(c(
      "run_id",
      "solution_id",
      "status",
      "value_cost",
      "value_frag"
    ) %in% names(runs))
  )
})


test_that("deprecated AUGMECON grid is converted to a manual run design", {
  toy <- toy_equivalent_basic()

  x <- create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    add_actions(toy$actions) |>
    add_effects(toy$effects) |>
    add_objective_max_benefit(alias = "benefit") |>
    add_objective_min_cost(alias = "cost")

  expect_warning(
    out <- set_method_augmecon(
      x,
      primary = "benefit",
      aliases = c("benefit", "cost"),
      grid = list(
        cost = c(4, 6, 8)
      )
    ),
    "deprecated"
  )

  values <- out$data$method$runs$values

  expect_s3_class(out$data$method$runs, "RunManual")
  expect_identical(names(values), "eps_cost")
  expect_false("run_id" %in% names(values))
  expect_equal(nrow(values), 3L)
  expect_equal(values$eps_cost, c(4, 6, 8))
})
