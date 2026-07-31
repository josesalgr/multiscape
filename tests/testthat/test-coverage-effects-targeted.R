test_that("add_effects accepts feature names and all explicit signed formats", {
  p <- make_round2_action_problem(with_effects = FALSE)

  compact <- multiscape::add_effects(
    p,
    data.frame(
      action = c("conservation", "restoration"),
      feature = factor(c("sp1", "sp2")),
      multiplier = c(0.5, 1.5)
    ),
    effect_type = "after"
  )
  expect_true(nrow(compact$data$dist_effects) > 0L)
  expect_true(all(compact$data$dist_effects$amount_after >= 0))

  delta <- multiscape::add_effects(
    p,
    data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      delta = c(2, -1)
    ),
    effect_type = "delta"
  )
  expect_setequal(delta$data$dist_effects$benefit, c(0, 2))
  expect_setequal(delta$data$dist_effects$loss, c(0, 1))

  effect_after <- multiscape::add_effects(
    p,
    data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      effect = c(3, 4)
    ),
    effect_type = "after"
  )
  expect_equal(effect_after$data$dist_effects$amount_after, c(3, 4))

  explicit_after <- multiscape::add_effects(
    p,
    data.frame(
      pu = 1,
      action = "conservation",
      feature = 1,
      after = 7
    ),
    effect_type = "after"
  )
  expect_equal(explicit_after$data$dist_effects$amount_after, 7)

  signed_effect <- multiscape::add_effects(
    p,
    data.frame(
      pu = 1,
      action = "conservation",
      feature = 1,
      effect = -2
    ),
    effect_type = "delta"
  )
  expect_equal(signed_effect$data$dist_effects$loss, 2)
})


test_that("add_effects canonicalizes partial split benefit and loss tables", {
  p <- make_round2_action_problem(with_effects = FALSE)

  benefit <- multiscape::add_effects(
    p,
    data.frame(
      pu = 1,
      action = "conservation",
      feature = 1,
      benefit = 2,
      loss = 0
    )
  )
  expect_equal(benefit$data$dist_effects$benefit, 2)
  expect_equal(benefit$data$dist_effects$loss, 0)

  loss <- multiscape::add_effects(
    p,
    data.frame(
      pu = 2,
      action = "restoration",
      feature = 2,
      loss = 1,
      benefit = 0
    )
  )
  expect_equal(loss$data$dist_effects$benefit, 0)
  expect_equal(loss$data$dist_effects$loss, 1)

  only_benefits <- multiscape::add_benefits(
    p,
    benefits = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      delta = c(2, -1)
    )
  )
  expect_true(all(only_benefits$data$dist_effects$benefit > 0))
  expect_false("loss" %in% names(only_benefits$data$dist_benefit))

  only_losses <- multiscape::add_losses(
    p,
    losses = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      delta = c(2, -1)
    )
  )
  expect_true(all(only_losses$data$dist_effects$loss > 0))
  expect_false("benefit" %in% names(only_losses$data$dist_loss))
})


test_that("add_effects validates compact and explicit effect specifications", {
  p <- make_round2_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_effects(
      p,
      data.frame(action = "conservation", feature = "unknown", multiplier = 1)
    ),
    "Unknown feature name"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(action = "conservation", feature = 99, multiplier = 1)
    ),
    "Unknown feature id"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(action = "conservation", feature = 1, multiplier = "x")
    ),
    "must be numeric"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        action = c("conservation", "conservation"),
        feature = c(1, 1),
        multiplier = c(1, 2)
      )
    ),
    "duplicated combination"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1,
        delta = 1, effect = 2
      )
    ),
    "Ambiguous effect specification"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1, after = 2
      ),
      effect_type = "delta"
    ),
    "Column 'after'.*effect_type = 'delta'"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1, delta = 2
      ),
      effect_type = "after"
    ),
    "Column 'delta'.*effect_type = 'after'"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1,
        benefit = 1, loss = 1
      )
    ),
    "cannot have both"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1, delta = -100
      )
    ),
    "after-action feature amounts are negative"
  )
  expect_error(multiscape::add_effects(p, effects = "bad"), "Unsupported type")
})
