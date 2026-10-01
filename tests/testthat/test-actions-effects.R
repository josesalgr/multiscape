test_that("add_actions supports include and exclude pair specifications", {
  base <- make_round3_tabular_problem()
  actions <- data.frame(id = c("a", "b"))

  included <- multiscape::add_actions(
    base,
    actions = actions,
    include_pairs = list(
      a = c(1, 2),
      b = c(3, 4)
    ),
    cost = c(a = 1, b = 2)
  )

  expect_equal(nrow(included$data$dist_actions), 4L)
  expect_setequal(included$data$dist_actions$pu, 1:4)

  excluded <- multiscape::add_actions(
    base,
    actions = actions,
    exclude_pairs = data.frame(
      pu = c(1, 4),
      action = c("a", "b")
    ),
    cost = c(a = 1, b = 2)
  )

  expect_false(any(
    excluded$data$dist_actions$pu == 1 &
      excluded$data$dist_actions$action == "a"
  ))
  expect_false(any(
    excluded$data$dist_actions$pu == 4 &
      excluded$data$dist_actions$action == "b"
  ))
})


test_that("add_actions validates pair specifications", {
  base <- make_round3_tabular_problem()
  actions <- data.frame(id = c("a", "b"))

  expect_error(
    multiscape::add_actions(
      base,
      actions = actions,
      include_pairs = data.frame(pu = 999, action = "a")
    )
  )

  expect_error(
    multiscape::add_actions(
      base,
      actions = actions,
      include_pairs = data.frame(pu = 1, action = "unknown")
    )
  )

  expect_error(
    multiscape::add_actions(
      base,
      actions = actions,
      include_pairs = data.frame(
        pu = c(1, 1),
        action = c("a", "a")
      )
    )
  )
})


test_that("add_effects supports feature names and explicit signed effects", {
  x <- make_round3_action_problem(with_effects = FALSE)

  # Signed effect tables are explicit at the pu-action-feature level.
  effects <- data.frame(
    pu = c(1L, 2L),
    action = c("conservation", "restoration"),
    feature = c("sp1", "sp2"),
    effect = c(-1, 2)
  )

  out <- multiscape::add_effects(
    x,
    effects = effects
  )

  tbl <- out$data$dist_effects

  expect_s3_class(tbl, "data.frame")
  expect_true(all(c("benefit", "loss", "amount_after") %in% names(tbl)))
  expect_true(any(tbl$loss > 0))
  expect_true(any(tbl$benefit > 0))
  expect_true(all(tbl$feature_name %in% c("sp1", "sp2")))
})
