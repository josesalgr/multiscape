test_that("add_actions supports action-column aliases and default names", {
  p <- make_round4_problem()

  expect_warning(
    out <- multiscape::add_actions(
      p,
      actions = data.frame(action = c("b", "a")),
      cost = 3
    ),
    "Renaming"
  )

  expect_equal(out$data$actions$id, c("a", "b"))
  expect_equal(out$data$actions$name, c("a", "b"))
  expect_true(all(out$data$dist_actions$cost == 3))
})


test_that("add_actions validates action names, sets, internal ids, and no feasible pairs", {
  p <- make_round4_problem()

  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = ""),
      cost = 1
    ),
    "empty"
  )
  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = "a", name = ""),
      cost = 1
    ),
    "name"
  )
  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = "a", action_set = NA_character_),
      cost = 1
    ),
    "action_set"
  )
  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = c("a", "b"), internal_id = c(1L, 1L)),
      cost = c(a = 1, b = 2)
    ),
    "internal_id"
  )
  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = "a"),
      include_pairs = data.frame(pu = 1, action = "a"),
      exclude_pairs = data.frame(pu = 1, action = "a"),
      cost = 1
    ),
    "No feasible"
  )
})


test_that("add_actions validates named vector costs", {
  p <- make_round4_problem()
  actions <- data.frame(id = c("a", "b"))

  expect_error(multiscape::add_actions(p, actions, cost = c(a = 1, a = 2)), "duplicated")
  expect_error(multiscape::add_actions(p, actions, cost = c(a = 1, c = 2)), "unknown")
  expect_error(multiscape::add_actions(p, actions, cost = c(a = 1)), "missing")
  expect_error(multiscape::add_actions(p, actions, cost = c(a = 1, b = NA)), "finite|missing")
  expect_error(multiscape::add_actions(p, actions, cost = c(a = 1, b = -1)), "non-negative")
})


test_that("add_actions validates scalar and unsupported costs", {
  p <- make_round4_problem()
  actions <- data.frame(id = "a")

  expect_error(multiscape::add_actions(p, actions, cost = NA_real_), "finite")
  expect_error(multiscape::add_actions(p, actions, cost = -1), "non-negative")
  expect_error(multiscape::add_actions(p, actions, cost = "bad"), "Unsupported")
})


test_that("add_actions supports and validates action-level cost data frames", {
  p <- make_round4_problem()
  actions <- data.frame(id = c("a", "b"))

  out_id <- multiscape::add_actions(
    p,
    actions,
    cost = data.frame(id = c("a", "b"), cost = c(5, 7))
  )
  expect_equal(unique(out_id$data$dist_actions$cost[out_id$data$dist_actions$action == "a"]), 5)
  expect_equal(unique(out_id$data$dist_actions$cost[out_id$data$dist_actions$action == "b"]), 7)

  expect_error(
    multiscape::add_actions(p, actions, cost = data.frame(action = c("a", "a"), cost = c(1, 2))),
    "unique"
  )
  expect_error(
    multiscape::add_actions(p, actions, cost = data.frame(action = "a", cost = 1)),
    "missing"
  )
  expect_error(
    multiscape::add_actions(p, actions, cost = data.frame(action = c("a", "c"), cost = c(1, 2))),
    "unknown"
  )
  expect_error(
    multiscape::add_actions(p, actions, cost = data.frame(action = c("a", "b"), cost = c(1, NA))),
    "finite|missing|numeric"
  )
})


test_that("add_actions supports and validates pair-level cost data frames", {
  p <- make_round4_problem()
  actions <- data.frame(id = c("a", "b"))
  include <- data.frame(pu = c(1, 1, 2), action = c("a", "b", "a"))

  out <- multiscape::add_actions(
    p,
    actions,
    include_pairs = include,
    cost = data.frame(pu = c(1, 2), action = c("a", "a"), cost = c(10, 20))
  )
  expect_equal(out$data$dist_actions$cost[out$data$dist_actions$pu == 1 & out$data$dist_actions$action == "a"], 10)
  expect_equal(out$data$dist_actions$cost[out$data$dist_actions$pu == 2 & out$data$dist_actions$action == "a"], 20)
  expect_equal(out$data$dist_actions$cost[out$data$dist_actions$pu == 1 & out$data$dist_actions$action == "b"], 1)

  expect_error(
    multiscape::add_actions(p, actions, include_pairs = include, cost = data.frame(pu = 999, action = "a", cost = 1)),
    "unknown pu"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = include, cost = data.frame(pu = 1, action = "c", cost = 1)),
    "unknown action"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = include, cost = data.frame(pu = c(1, 1), action = c("a", "a"), cost = c(1, 2))),
    "duplicate"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = include, cost = data.frame(pu = 3, action = "b", cost = 1)),
    "not feasible"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = include, cost = data.frame(pu = 1, action = "a", cost = -1)),
    "non-negative"
  )
})
