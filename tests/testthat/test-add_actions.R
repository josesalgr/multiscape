test_that("add_actions creates one feasible row per pu-action pair", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  )

  p <- multiscape::add_actions(
    p,
    actions = toy$actions,
    cost = 0
  )

  expect_true(is.data.frame(p$data$actions))
  expect_true(is.data.frame(p$data$dist_actions))

  expect_equal(nrow(p$data$actions), 1)
  expect_equal(nrow(p$data$dist_actions), nrow(toy$pu) * nrow(toy$actions))

  expect_true(all(c("pu", "action") %in% names(p$data$dist_actions)))
  expect_equal(anyDuplicated(p$data$dist_actions[, c("pu", "action")]), 0)

  expect_true("internal_action" %in% names(p$data$dist_actions))
  expect_true("internal_pu" %in% names(p$data$dist_actions))
})

test_that("add_actions stores a constant action cost correctly", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  )

  p <- multiscape::add_actions(
    p,
    actions = toy$actions,
    cost = 7
  )

  expect_true("cost" %in% names(p$data$dist_actions))
  expect_equal(unique(p$data$dist_actions$cost), 7)
})


test_that("add_actions accepts scalar and named action costs", {
  d <- make_round4_base_data()
  p <- make_round4_problem()

  scalar <- multiscape::add_actions(
    p,
    actions = d$actions,
    cost = 1
  )

  named <- multiscape::add_actions(
    p,
    actions = d$actions,
    cost = c(
      conservation = 1,
      restoration = 2
    )
  )

  expect_s3_class(scalar, "Problem")
  expect_s3_class(named, "Problem")
})


test_that("add_actions rejects partial named costs", {
  d <- make_round4_base_data()
  p <- make_round4_problem()

  expect_error(
    multiscape::add_actions(
      p,
      actions = d$actions,
      cost = c(conservation = 1)
    ),
    "missing action id"
  )
})


test_that("add_actions rejects duplicated action ids", {
  d <- make_round4_base_data()
  d$actions$id[2] <- d$actions$id[1]

  expect_error(
    multiscape::add_actions(
      make_round4_problem(),
      actions = d$actions,
      cost = 1
    )
  )
})

test_that("add_actions accepts complete named costs", {
  d <- make_round4_base_data()
  p <- make_round4_problem()

  out <- multiscape::add_actions(
    p,
    actions = d$actions,
    cost = c(
      conservation = 1,
      restoration = 2
    )
  )

  expect_s3_class(out, "Problem")
})


test_that("add_actions rejects unknown and non-finite named costs", {
  d <- make_round4_base_data()
  p <- make_round4_problem()

  expect_error(
    multiscape::add_actions(
      p,
      actions = d$actions,
      cost = c(
        conservation = 1,
        unknown = 2
      )
    )
  )

  expect_error(
    multiscape::add_actions(
      p,
      actions = d$actions,
      cost = c(
        conservation = 1,
        restoration = Inf
      )
    )
  )
})


test_that("add_actions does not mutate the original problem", {
  d <- make_round4_base_data()
  p <- make_round4_problem()
  original_actions <- p$data$actions

  out <- multiscape::add_actions(
    p,
    actions = d$actions,
    cost = c(
      conservation = 1,
      restoration = 2
    )
  )

  expect_s3_class(out, "Problem")
  expect_identical(p$data$actions, original_actions)
})


test_that("add_actions rejects unknown ids in feasible-pair tables", {
  d <- make_round4_base_data()
  p <- make_round4_problem()

  feasible <- data.frame(
    pu = c(1L, 999L),
    action = c("conservation", "restoration")
  )

  expect_error(
    multiscape::add_actions(
      p,
      actions = d$actions,
      cost = c(
        conservation = 1,
        restoration = 2
      ),
      include = feasible
    )
  )
})
