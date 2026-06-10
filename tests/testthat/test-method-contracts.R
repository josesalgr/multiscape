test_that("set_method_weighted_sum rejects malformed manual weights", {
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
    multiscape::add_spatial_boundary(
      boundary = bnd,
      weight_col = "boundary",
      include_self = TRUE
    ) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_objective_min_cost(
      alias = "cost"
    ) |>
    multiscape::add_objective_min_fragmentation_pu(
      alias = "frag"
    )

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "frag"),
      runs = multiscape::run_manual(
        data.frame(
          weight_cost = 1
        )
      )
    ),
    "missing required column"
  )
})


test_that("set_method_weighted_sum rejects duplicate aliases", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_spatial_boundary(
      boundary = toy$boundary,
      weight_col = "boundary",
      include_self = TRUE
    ) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_min_fragmentation_pu(alias = "frag")

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "cost"),
      runs = multiscape::run_manual(
        data.frame(
          weight_cost = 1,
          check.names = FALSE
        )
      )
    ),
    "duplicate|unique|aliases"
  )
})


test_that("weighted-sum validates aliases and manual weights", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "cost"),
      runs = multiscape::run_grid(3)
    )
  )

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "unknown"),
      runs = multiscape::run_grid(3)
    )
  )

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      runs = multiscape::run_manual(
        data.frame(weight_cost = 1)
      )
    )
  )

  out <- multiscape::set_method_weighted_sum(
    p,
    aliases = c("cost", "benefit"),
    runs = multiscape::run_manual(
      data.frame(
        weight_cost = 2,
        weight_benefit = 1
      )
    ),
    normalize_weights = FALSE
  )

  expect_s3_class(out, "Problem")
  expect_false(out$data$method$normalize_weights)
})


test_that("epsilon-constraint validates unknown primary objectives", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "unknown",
      runs = multiscape::run_grid(3)
    )
  )
})


test_that("epsilon-constraint accepts manual designs resolved by the method", {
  p <- make_round4_mo_problem()

  out <- multiscape::set_method_epsilon_constraint(
    p,
    primary = "cost",
    aliases = c("cost", "benefit"),
    runs = multiscape::run_manual(
      data.frame(eps_cost = 1)
    )
  )

  expect_s3_class(out, "Problem")
})


test_that("AUGMECON validates primary, augmentation, and runs", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "unknown",
      runs = multiscape::run_grid(3)
    )
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::run_grid(3),
      augmentation = -1
    )
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = NULL
    )
  )
})


test_that("multi-objective methods reject invalid controls", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      runs = multiscape::run_grid(3),
      control = list()
    )
  )

  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      runs = multiscape::run_grid(3),
      control = list()
    )
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::run_grid(3),
      control = list()
    )
  )
})


test_that("weighted-sum can use raw manual weights", {
  p <- make_round4_mo_problem()

  out <- multiscape::set_method_weighted_sum(
    p,
    aliases = c("cost", "benefit"),
    runs = multiscape::run_manual(
      data.frame(
        weight_cost = 2,
        weight_benefit = 1
      )
    ),
    normalize_weights = FALSE
  )

  expect_s3_class(out, "Problem")
  expect_false(out$data$method$normalize_weights)
})
