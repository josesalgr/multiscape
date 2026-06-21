test_that("action locks update feasible decision statuses", {
  p <- make_round2_action_problem(with_effects = FALSE)

  out <- multiscape::add_constraint_locked_actions(
    p,
    locked_in = data.frame(
      pu = c(1, 2),
      action = c("restoration", "conservation")
    ),
    locked_out = data.frame(
      pu = 4,
      action = "restoration"
    )
  )

  da <- out$data$dist_actions

  expect_equal(
    da$status[da$pu == 1 & da$action == "restoration"],
    2L
  )
  expect_equal(
    da$status[da$pu == 2 & da$action == "conservation"],
    2L
  )
  expect_equal(
    da$status[da$pu == 4 & da$action == "restoration"],
    3L
  )
})


test_that("action locks support the named-list interface", {
  p <- make_round2_action_problem(with_effects = FALSE)

  out <- multiscape::add_constraint_locked_actions(
    p,
    locked_in = list(
      restoration = c(1, 3)
    ),
    locked_out = list(
      conservation = 2
    )
  )

  da <- out$data$dist_actions

  expect_true(all(
    da$status[
      da$pu %in% c(1, 3) & da$action == "restoration"
    ] == 2L
  ))

  expect_equal(
    da$status[da$pu == 2 & da$action == "conservation"],
    3L
  )
})


test_that("action locks reject invalid and contradictory pairs", {
  p <- make_round2_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_constraint_locked_actions(
      p,
      locked_in = data.frame(pu = 99, action = "restoration")
    ),
    "PU ids not present"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(
      p,
      locked_in = data.frame(pu = 1, action = "unknown")
    ),
    "action ids not present"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(
      p,
      locked_in = data.frame(
        pu = c(1, 1),
        action = c("restoration", "restoration")
      )
    ),
    "duplicate"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(
      p,
      locked_in = data.frame(pu = 1, action = "restoration"),
      locked_out = data.frame(pu = 1, action = "restoration")
    ),
    "simultaneously"
  )
})


test_that("locked actions are respected by the solver", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = FALSE,
    with_profit = TRUE
  ) |>
    multiscape::add_constraint_locked_actions(
      locked_in = data.frame(pu = 1, action = "conservation"),
      locked_out = data.frame(pu = 2, action = "restoration")
    ) |>
    multiscape::add_objective_max_profit(alias = "profit") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  s <- multiscape::solve(p)
  selected <- multiscape::get_actions(s)

  expect_true(any(
    selected$pu == 1 & selected$action == "conservation"
  ))
  expect_false(any(
    selected$pu == 2 & selected$action == "restoration"
  ))
})
