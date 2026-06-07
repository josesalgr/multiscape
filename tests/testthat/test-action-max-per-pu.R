test_that("action_max_per_pu stores validated constraint metadata", {
  p <- make_round2_action_problem(with_effects = FALSE)

  out <- multiscape:::add_action_max_per_pu(
    p,
    max = 1L,
    pu = c(1, 3),
    actions = "restoration"
  )

  spec <- out$data$constraints$action_max_per_pu

  expect_identical(spec$type, "action_max_per_pu")
  expect_identical(spec$max, 1L)
  expect_setequal(spec$pu, c(1L, 3L))
  expect_identical(spec$actions, "restoration")
})


test_that("action_max_per_pu validates subsets and overwrite", {
  p <- make_round2_action_problem(with_effects = FALSE)

  expect_error(
    multiscape:::add_action_max_per_pu(p, max = -1),
    "must be >= 0"
  )

  expect_error(
    multiscape:::add_action_max_per_pu(p, pu = 99),
    "Unknown PU"
  )

  expect_error(
    multiscape:::add_action_max_per_pu(p, actions = "unknown"),
    "Unknown action"
  )

  p1 <- multiscape:::add_action_max_per_pu(p, max = 1)

  expect_error(
    multiscape:::add_action_max_per_pu(p1, max = 0),
    "already exists"
  )

  p2 <- multiscape:::add_action_max_per_pu(
    p1,
    max = 0,
    overwrite = TRUE
  )

  expect_identical(
    p2$data$constraints$action_max_per_pu$max,
    0L
  )
})

test_that("the internal maximum-one-action constraint is compiled", {
  toy <- toy_multiaction_semantics()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = toy$actions,
      cost = c(
        conservation = 1,
        restoration = 2
      )
    ) |>
    multiscape::add_effects(
      effects = toy$effects,
      effect_type = "after"
    ) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_objective_min_cost(alias = "cost")

  compiled <- multiscape::compile_model(p)

  expect_s3_class(compiled, "Problem")
})
