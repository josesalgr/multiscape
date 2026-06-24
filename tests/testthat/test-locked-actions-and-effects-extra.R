test_that("locked actions accepts data-frame and list specs and normalizes feasible flags", {
  p <- make_round4_problem(with_actions = TRUE)

  locked <- multiscape::add_constraint_locked_actions(
    p,
    locked_in = data.frame(
      pu = c("1", "2", "3"),
      id = c("conservation", "restoration", "conservation"),
      feasible = c("yes", "0", NA_character_),
      stringsAsFactors = FALSE
    ),
    locked_out = list(
      restoration = c(1, 4),
      conservation = NULL
    )
  )

  da <- locked$data$dist_actions
  expect_equal(da$status[da$pu == 1 & da$action == "conservation"], 2L)
  expect_equal(da$status[da$pu == 2 & da$action == "restoration"], 0L)
  expect_equal(da$status[da$pu == 3 & da$action == "conservation"], 0L)
  expect_equal(da$status[da$pu == 1 & da$action == "restoration"], 3L)
  expect_equal(da$status[da$pu == 4 & da$action == "restoration"], 3L)
})


test_that("locked actions rejects malformed requests and conflicting locks", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_constraint_locked_actions(make_round4_problem(), locked_in = data.frame(pu = 1, action = "conservation")),
    "add_actions"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = data.frame()),
    "empty data.frame"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = data.frame(pu = 1)),
    "columns 'pu' and 'action'"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = data.frame(pu = "A", action = "conservation")),
    "numeric/integer"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = data.frame(pu = 999, action = "conservation")),
    "PU ids not present"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = data.frame(pu = 1, action = "unknown")),
    "action ids not present"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = data.frame(pu = c(1, 1), action = c("conservation", "conservation"))),
    "duplicate"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = list(c(1, 2))),
    "named list"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = list(unknown = 1)),
    "unknown actions"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(p, locked_in = TRUE),
    "Unsupported type"
  )

  # Make one feasible pair unavailable, then request it.
  p_bad <- p
  p_bad$data$dist_actions <- p_bad$data$dist_actions[
    !(p_bad$data$dist_actions$pu == 1 & p_bad$data$dist_actions$action == "conservation"),
    ,
    drop = FALSE
  ]
  expect_error(
    multiscape::add_constraint_locked_actions(p_bad, locked_in = data.frame(pu = 1, action = "conservation")),
    "not feasible"
  )

  expect_error(
    multiscape::add_constraint_locked_actions(
      p,
      locked_in = data.frame(pu = 1, action = "conservation"),
      locked_out = data.frame(pu = 1, action = "conservation")
    ),
    "simultaneously|not feasible"
  )

  p_pu_locked <- p
  p_pu_locked$data$pu$locked_out <- p_pu_locked$data$pu$id == 1
  expect_error(
    multiscape::add_constraint_locked_actions(
      p_pu_locked,
      locked_in = data.frame(pu = 1, action = "conservation")
    ),
    "locked_in inside planning units|not feasible"
  )

  p_pu_locked_out <- multiscape::add_constraint_locked_actions(
    p_pu_locked,
    locked_out = data.frame(pu = 2, action = "conservation")
  )
  da <- p_pu_locked_out$data$dist_actions
  expect_true(all(da$status[da$pu == 1] == 3L))
})


test_that("add_effects validates effect types, components, and malformed effect tables", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "conservation", feature = 1, multiplier = 1), effect_type = "bad"),
    "should be one of|effect_type"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "conservation", feature = 1, multiplier = 1), component = "bad"),
    "should be one of|component"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(pu = 1, action = "conservation", feature = 1)),
    "multiplier|amount_after|benefit|loss|Elements"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "unknown", feature = 1, multiplier = 1), effect_type = "after"),
    "action"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "conservation", feature = "unknown", multiplier = 1), effect_type = "after"),
    "feature"
  )

  after <- multiscape::add_effects(
    p,
    effects = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c("sp1", "sp2"),
      after = c(2, 5)
    ),
    effect_type = "after"
  )
  expect_true(is.data.frame(after$data$dist_effects))

  benefit <- multiscape::add_effects(
    p,
    effects = data.frame(
      pu = 2,
      action = "restoration",
      feature = "sp1",
      benefit = 4
    ),
    component = "benefit"
  )
  expect_true(is.data.frame(benefit$data$dist_effects))

  loss <- multiscape::add_effects(
    p,
    effects = data.frame(
      pu = 1,
      action = "conservation",
      feature = "sp2",
      loss = 1
    ),
    component = "loss"
  )
  expect_true(is.data.frame(loss$data$dist_effects))
})
