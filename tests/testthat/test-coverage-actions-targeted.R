test_that("add_actions handles named pair lists, feasibility flags, and action metadata", {
  p <- make_round3_tabular_problem()
  actions <- data.frame(
    action = c("conservation", "restoration"),
    action_set = c("protect", "repair"),
    internal_id = c(2L, 1L)
  )

  include <- list(
    conservation = c(1, 2, 2),
    restoration = c(2, 3)
  )
  exclude <- data.frame(
    pu = c(2, 3),
    action = c("conservation", "restoration"),
    feasible = c("yes", "no")
  )
  area <- data.frame(
    pu = c(1, 2),
    id = c("conservation", "restoration"),
    area = c(10, 30)
  )
  costs <- data.frame(
    action = c("conservation", "restoration"),
    cost = c(2, 5)
  )

  expect_warning(
    out <- multiscape::add_actions(
      p,
      actions = actions,
      include_pairs = include,
      exclude_pairs = exclude,
      action_area = area,
      cost = costs
    ),
    "Renaming it to 'id'|not feasible"
  )

  expect_setequal(out$data$actions$id, c("conservation", "restoration"))
  expect_setequal(out$data$actions$internal_id, c(1L, 2L))
  expect_true(all(out$data$dist_actions$cost %in% c(2, 5)))
  expect_false(any(
    out$data$dist_actions$pu == 2 &
      out$data$dist_actions$action == "conservation"
  ))
  expect_equal(
    out$data$dist_actions$action_area[
      out$data$dist_actions$pu == 2 &
        out$data$dist_actions$action == "restoration"
    ],
    30
  )
})


test_that("add_actions accepts numeric and factor feasibility flags", {
  p <- make_round3_tabular_problem()
  actions <- data.frame(id = c("a", "b"))

  numeric_flags <- data.frame(
    pu = c(1, 2, 3),
    action = c("a", "a", "b"),
    feasible = c(1, 0, NA)
  )
  out <- multiscape::add_actions(
    p,
    actions,
    include_pairs = numeric_flags
  )
  expect_equal(nrow(out$data$dist_actions), 1L)
  expect_equal(out$data$dist_actions$pu, 1L)

  factor_flags <- data.frame(
    pu = c(1, 2),
    action = c("a", "b"),
    feasible = factor(c("true", "false"))
  )
  out_factor <- multiscape::add_actions(
    p,
    actions,
    include_pairs = factor_flags
  )
  expect_equal(nrow(out_factor$data$dist_actions), 1L)
  expect_equal(out_factor$data$dist_actions$action, "a")
})


test_that("add_actions validates pair-list and action-area edge cases", {
  p <- make_round3_tabular_problem()
  actions <- data.frame(id = c("a", "b"))

  expect_error(
    multiscape::add_actions(p, actions, include_pairs = list(1:2)),
    "must be a named list"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = list(other = 1)),
    "unknown actions"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = list(a = "bad")),
    "numeric/integer ids"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = list(a = 99)),
    "PU ids not present"
  )
  expect_error(
    multiscape::add_actions(p, actions, include_pairs = "bad"),
    "Unsupported type"
  )

  expect_error(
    multiscape::add_actions(p, actions, action_area = 1),
    "must be NULL or a data.frame"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      action_area = data.frame(pu = 1, action = "a")
    ),
    "must contain columns"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      action_area = data.frame(pu = 99, action = "a", action_area = 1)
    ),
    "unknown pu"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      action_area = data.frame(pu = 1, action = "other", action_area = 1)
    ),
    "unknown action"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      action_area = data.frame(
        pu = c(1, 1), action = c("a", "a"), action_area = c(1, 2)
      )
    ),
    "duplicate"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      action_area = data.frame(pu = 1, action = "a", action_area = Inf)
    ),
    "finite"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      action_area = data.frame(pu = 1, action = "a", action_area = -1)
    ),
    "non-negative"
  )
})


test_that("add_actions validates action-level cost tables", {
  p <- make_round3_tabular_problem()
  actions <- data.frame(id = c("a", "b"))

  expect_error(
    multiscape::add_actions(
      p, actions,
      cost = data.frame(action = c("a", "a"), cost = c(1, 2))
    ),
    "unique action rows"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      cost = data.frame(action = "a", cost = 1)
    ),
    "missing action id"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      cost = data.frame(action = c("a", "b"), cost = c(1, NA))
    ),
    "finite, non-missing"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      cost = data.frame(action = c("a", "b"), cost = c(1, -1))
    ),
    "non-negative"
  )
  expect_error(
    multiscape::add_actions(
      p, actions,
      cost = data.frame(action = c("a", "other"), cost = c(1, 2))
    ),
    "unknown actions"
  )
})
