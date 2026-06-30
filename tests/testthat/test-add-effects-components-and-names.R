test_that("add_effects accepts feature names and component filters", {
  p <- make_round4_problem(with_actions = TRUE)

  effects <- data.frame(
    pu = c(1, 2),
    action = c("conservation", "restoration"),
    feature = c("sp1", "sp2"),
    delta = c(2, -3)
  )

  benefit_only <- multiscape::add_effects(
    p,
    effects = effects,
    effect_type = "delta",
    component = "benefit"
  )
  expect_equal(nrow(benefit_only$data$dist_effects), 1L)
  expect_true(all(benefit_only$data$dist_effects$benefit > 0))
  expect_equal(benefit_only$data$dist_effects$feature, 1L)

  loss_only <- multiscape::add_effects(
    p,
    effects = effects,
    effect_type = "delta",
    component = "loss"
  )
  expect_equal(nrow(loss_only$data$dist_effects), 1L)
  expect_true(all(loss_only$data$dist_effects$loss > 0))
  expect_equal(loss_only$data$dist_effects$feature, 2L)
})

test_that("add_effects validates duplicated keys and unknown feature names", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = c(1, 1),
        action = c("conservation", "conservation"),
        feature = c("sp1", "sp1"),
        delta = c(1, 2)
      ),
      effect_type = "delta"
    ),
    "duplicated"
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = 1,
        action = "conservation",
        feature = "unknown",
        delta = 1
      ),
      effect_type = "delta"
    ),
    "Unknown feature name"
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = 1,
        action = "conservation",
        feature = "sp1",
        delta = NA_real_
      ),
      effect_type = "delta"
    ),
    "missing"
  )
})
