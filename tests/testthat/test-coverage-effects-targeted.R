test_that("add_effects accepts feature names and all explicit signed formats", {
  p <- make_round2_action_problem(with_effects = FALSE)

  compact <- multiscape::add_effects(
    p,
    data.frame(
      action = c("conservation", "restoration"),
      feature = factor(c("sp1", "sp2")),
      relative_change = c(-0.5, 0.5)
    )
  )
  expect_true(nrow(compact$data$dist_effects) > 0L)
  expect_true(all(compact$data$dist_effects$amount_after >= 0))

  signed <- multiscape::add_effects(
    p,
    data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      effect = c(2, -1)
    )
  )
  expect_setequal(signed$data$dist_effects$benefit, c(0, 2))
  expect_setequal(signed$data$dist_effects$loss, c(0, 1))

  effect_after <- multiscape::add_effects(
    p,
    data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      outcome = c(3, 4)
    )
  )
  expect_equal(effect_after$data$dist_effects$amount_after, c(3, 4))

  explicit_after <- multiscape::add_effects(
    p,
    data.frame(
      pu = 1,
      action = "conservation",
      feature = 1,
      outcome = 7
    )
  )
  expect_equal(explicit_after$data$dist_effects$amount_after, 7)

  signed_effect <- multiscape::add_effects(
    p,
    data.frame(
      pu = 1,
      action = "conservation",
      feature = 1,
      effect = -2
    )
  )
  expect_equal(signed_effect$data$dist_effects$loss, 2)
})
